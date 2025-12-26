// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "reactive-lib/abstract-base/AbstractReactive.sol";
import "reactive-lib/interfaces/ISystemContract.sol";

/**
 * @title LendingRebalancer
 * @notice A reactive contract that monitors lending pool rates and triggers rebalancing
 * @dev Deployed on Reactive Network (Lasna). Listens to RatesUpdated events from RateCoordinator.
 * 
 * IMPORTANT: ReactVM is STATELESS - each react() call starts with clean state.
 * This contract subscribes to RateCoordinator which emits a single event with BOTH rates,
 * eliminating the need to store rates between calls.
 */
contract LendingRebalancer is AbstractReactive {
    
    // Event signature: RatesUpdated(uint256 indexed rateA, uint256 indexed rateB, uint256 timestamp)
    // keccak256("RatesUpdated(uint256,uint256,uint256)")
    uint256 constant RATES_UPDATED_TOPIC_0 = 0x023010bc68e7f4c0be9887f513c570c7a0f5f511b9716abccd42bf3b8943532b;
    
    // Gas limit for rebalance callback
    uint64 constant CALLBACK_GAS_LIMIT = 800000;
    
    // ============ State ============
    uint256 public immutable originChainId;
    
    // RateCoordinator on origin chain (replaces individual pool oracles)
    address public rateCoordinator;
    
    // Destination vault
    uint256 public destChainId;
    address public vault;
    
    // Configuration
    uint256 public rebalanceThreshold = 200; // 2% in basis points
    uint256 public minRebalanceInterval = 60; // Minimum seconds between rebalances
    uint256 public rebalancePercentage = 5000; // 50% of higher-allocation pool moved
    
    // ============ Events ============
    event RatesReceived(uint256 rateA, uint256 rateB, uint256 timestamp);
    event RebalanceTriggered(bool direction, uint256 amount, uint256 rateA, uint256 rateB);
    event ConfigUpdated(uint256 threshold, uint256 interval, uint256 percentage);
    event SubscribedToCoordinator(address coordinator);

    constructor(
        uint256 _originChainId,
        address _rateCoordinator,
        uint256 _destChainId,
        address _vault
    ) payable AbstractReactive() {
        originChainId = _originChainId;
        
        // service is now properly initialized by AbstractReactive() constructor
        // which sets service = SERVICE_ADDR (0xfffFfF) and calls detectVm()
        
        rateCoordinator = _rateCoordinator;
        destChainId = _destChainId;
        vault = _vault;
        
        // NOTE: Subscription is done manually after deployment via subscribeToCoordinator()
        // This allows the contract to be funded with REACT first
    }
    
    /**
     * @notice Subscribe to RateCoordinator events. Call after funding the contract.
     * @dev Can only be called on Reactive Network (not in ReactVM)
     */
    function subscribeToCoordinator() external {
        require(!vm, "Cannot call in ReactVM");
        require(rateCoordinator != address(0), "Coordinator not set");
        
        // Subscribe to RatesUpdated events from RateCoordinator
        service.subscribe(
            originChainId,
            rateCoordinator,
            RATES_UPDATED_TOPIC_0,
            REACTIVE_IGNORE,  // We'll decode rateA from topic_1
            REACTIVE_IGNORE,  // We'll decode rateB from topic_2
            REACTIVE_IGNORE   // timestamp is in data
        );
        
        emit SubscribedToCoordinator(rateCoordinator);
    }

    /**
     * @notice Reacts to RatesUpdated events from RateCoordinator
     * @param log The log record from the origin chain
     * @dev This is the key change: we receive BOTH rates in a single event,
     *      eliminating the stateless storage problem
     */
    function react(LogRecord calldata log) external override vmOnly {
        // Only process RatesUpdated events
        if (log.topic_0 != RATES_UPDATED_TOPIC_0) return;
        
        // Decode rates from indexed parameters
        // topic_1 = rateA (indexed)
        // topic_2 = rateB (indexed)
        uint256 rateA = log.topic_1;
        uint256 rateB = log.topic_2;
        
        // Decode timestamp from data (non-indexed parameter)
        uint256 timestamp = abi.decode(log.data, (uint256));
        
        emit RatesReceived(rateA, rateB, timestamp);
        
        // Check if rebalance is needed and trigger it
        _checkAndTriggerRebalance(rateA, rateB);
    }
    
    /**
     * @notice Checks rate differential and triggers rebalance if threshold exceeded
     * @param rateA Rate from Pool A
     * @param rateB Rate from Pool B
     */
    function _checkAndTriggerRebalance(uint256 rateA, uint256 rateB) internal {
        // Need valid rates from both pools
        if (rateA == 0 || rateB == 0) return;
        
        // Calculate rate differential in basis points
        uint256 higher = rateA > rateB ? rateA : rateB;
        uint256 lower = rateA > rateB ? rateB : rateA;
        
        // Avoid division by zero
        if (lower == 0) lower = 1;
        
        uint256 differential = ((higher - lower) * 10000) / lower;
        
        // Check if differential exceeds threshold
        if (differential < rebalanceThreshold) return;
        
        // Determine direction: move funds TO the higher-yielding pool
        // direction = true means A -> B (B has higher rate)
        // direction = false means B -> A (A has higher rate)
        bool direction = rateB > rateA;
        
        // Calculate rebalance amount (vault will determine optimal amount)
        uint256 amount = 0;
        
        // Emit callback to vault
        _emitRebalanceCallback(direction, amount, rateA, rateB);
        
        emit RebalanceTriggered(direction, amount, rateA, rateB);
    }
    
    /**
     * @notice Emits a callback to the vault to trigger rebalancing
     */
    function _emitRebalanceCallback(bool direction, uint256 amount, uint256 rateA, uint256 rateB) internal {
        // Construct payload for LendingVault.rebalance(address,bool,uint256,uint256,uint256)
        bytes memory payload = abi.encodeWithSignature(
            "rebalance(address,bool,uint256,uint256,uint256)",
            address(0),  // Placeholder for sender (replaced by RVM ID)
            direction,
            amount,
            rateA,
            rateB
        );
        
        emit Callback(
            destChainId,
            vault,
            CALLBACK_GAS_LIMIT,
            payload
        );
    }
    
    // ============ Admin Functions (only on RN, not ReactVM) ============
    
    /**
     * @notice Updates configuration parameters
     * @dev Only callable on Reactive Network (not in ReactVM)
     */
    function setConfig(
        uint256 _threshold,
        uint256 _interval,
        uint256 _percentage
    ) external {
        require(!vm, "Cannot call in ReactVM");
        rebalanceThreshold = _threshold;
        minRebalanceInterval = _interval;
        rebalancePercentage = _percentage;
        emit ConfigUpdated(_threshold, _interval, _percentage);
    }
    
    /**
     * @notice Updates RateCoordinator address and resubscribes
     */
    function setRateCoordinator(address _coordinator) external {
        require(!vm, "Cannot call in ReactVM");
        rateCoordinator = _coordinator;
    }
    
    /**
     * @notice Updates destination vault
     */
    function setVault(uint256 _destChainId, address _vault) external {
        require(!vm, "Cannot call in ReactVM");
        destChainId = _destChainId;
        vault = _vault;
    }
}
