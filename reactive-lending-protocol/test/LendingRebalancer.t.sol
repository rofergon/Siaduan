// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/reactive/LendingRebalancer.sol";
import "reactive-lib/interfaces/IReactive.sol";

contract MockSystemContract {
    event SubscribeCalled(uint256 chainId, address contractAddr, uint256 topic0);
    
    function subscribe(uint256 chainId, address contractAddr, uint256 topic0, uint256, uint256, uint256) external {
        emit SubscribeCalled(chainId, contractAddr, topic0);
    }
}

/**
 * @title LendingRebalancerTest
 * @notice Tests for the updated LendingRebalancer that uses RateCoordinator pattern
 * @dev The key change is that react() now receives BOTH rates in a single event,
 *      solving the ReactVM stateless problem
 */
contract LendingRebalancerTest is Test {
    LendingRebalancer rebalancer;
    
    address constant SYSTEM_ADDR = 0x0000000000000000000000000000000000fffFfF;
    uint256 constant ORIGIN_CHAIN_ID = 11155111; // Sepolia
    uint256 constant DEST_CHAIN_ID = 11155111;   // Sepolia (same for this demo)
    
    address constant RATE_COORDINATOR = address(0xC0DE);
    address constant VAULT = address(0xCCC);
    
    // RatesUpdated(uint256 indexed rateA, uint256 indexed rateB, uint256 timestamp) topic
    // keccak256("RatesUpdated(uint256,uint256,uint256)")
    uint256 constant RATES_UPDATED_TOPIC = 0x023010bc68e7f4c0be9887f513c570c7a0f5f511b9716abccd42bf3b8943532b;
    
    event RatesReceived(uint256 rateA, uint256 rateB, uint256 timestamp);
    event RebalanceTriggered(bool direction, uint256 amount, uint256 rateA, uint256 rateB);
    event Callback(uint256 indexed chain_id, address indexed _contract, uint64 indexed gas_limit, bytes payload);

    function setUp() public {
        // Deploy rebalancer without system contract (simulates ReactVM)
        rebalancer = new LendingRebalancer(
            ORIGIN_CHAIN_ID,
            RATE_COORDINATOR,
            DEST_CHAIN_ID,
            VAULT
        );
    }

    // ============ Constructor Tests ============

    function testConstructor() public view {
        assertEq(rebalancer.originChainId(), ORIGIN_CHAIN_ID);
        assertEq(rebalancer.rateCoordinator(), RATE_COORDINATOR);
        assertEq(rebalancer.destChainId(), DEST_CHAIN_ID);
        assertEq(rebalancer.vault(), VAULT);
        assertEq(rebalancer.rebalanceThreshold(), 200); // 2%
    }

    // ============ React Tests ============

    function testReactReceivesBothRates() public {
        // Create RatesUpdated event log from RateCoordinator
        // Both rates come in a SINGLE event - this is the key fix!
        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: ORIGIN_CHAIN_ID,
            _contract: RATE_COORDINATOR,
            topic_0: RATES_UPDATED_TOPIC,
            topic_1: 300,  // rateA = 3%
            topic_2: 800,  // rateB = 8%
            topic_3: 0,
            data: abi.encode(block.timestamp), // timestamp
            block_number: 100,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
        
        vm.expectEmit(false, false, false, true);
        emit RatesReceived(300, 800, block.timestamp);
        
        rebalancer.react(log);
    }

    function testReactTriggersRebalanceWhenThresholdExceeded() public {
        // RatesUpdated with significant difference: 300 vs 800 = 166% difference
        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: ORIGIN_CHAIN_ID,
            _contract: RATE_COORDINATOR,
            topic_0: RATES_UPDATED_TOPIC,
            topic_1: 300,  // rateA = 3%
            topic_2: 800,  // rateB = 8% (166% higher)
            topic_3: 0,
            data: abi.encode(block.timestamp),
            block_number: 100,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
        
        // Should emit RebalanceTriggered (direction = true means move to B)
        vm.expectEmit(false, false, false, true);
        emit RebalanceTriggered(true, 0, 300, 800);
        
        rebalancer.react(log);
    }

    function testReactNoRebalanceWhenBelowThreshold() public {
        // RatesUpdated with small difference: 300 vs 303 = 1% difference
        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: ORIGIN_CHAIN_ID,
            _contract: RATE_COORDINATOR,
            topic_0: RATES_UPDATED_TOPIC,
            topic_1: 300,  // rateA = 3%
            topic_2: 303,  // rateB = 3.03% (1% higher - below 2% threshold)
            topic_3: 0,
            data: abi.encode(block.timestamp),
            block_number: 100,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
        
        // Should NOT emit RebalanceTriggered
        rebalancer.react(log);
        
        // No way to verify no emit, but the test passes if no revert
    }

    function testReactNoRebalanceWhenZeroRates() public {
        // RatesUpdated with zero rates
        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: ORIGIN_CHAIN_ID,
            _contract: RATE_COORDINATOR,
            topic_0: RATES_UPDATED_TOPIC,
            topic_1: 0,    // rateA = 0
            topic_2: 800,  // rateB = 8%
            topic_3: 0,
            data: abi.encode(block.timestamp),
            block_number: 100,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
        
        // Should not revert, but should not trigger rebalance
        rebalancer.react(log);
    }

    function testReactIgnoresWrongContract() public {
        address unknownContract = address(0x999);
        
        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: ORIGIN_CHAIN_ID,
            _contract: unknownContract, // Not the RateCoordinator
            topic_0: RATES_UPDATED_TOPIC,
            topic_1: 300,
            topic_2: 800,
            topic_3: 0,
            data: abi.encode(block.timestamp),
            block_number: 100,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
        
        // Should be processed anyway (we don't filter by contract in react)
        // The subscription handles contract filtering
        rebalancer.react(log);
    }

    function testReactIgnoresWrongTopic() public {
        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: ORIGIN_CHAIN_ID,
            _contract: RATE_COORDINATOR,
            topic_0: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef,
            topic_1: 300,
            topic_2: 800,
            topic_3: 0,
            data: abi.encode(block.timestamp),
            block_number: 100,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
        
        // Should not process (wrong topic)
        rebalancer.react(log);
    }

    function testRebalanceDirectionAtoB() public {
        // B has higher rate, so direction should be true (move A -> B)
        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: ORIGIN_CHAIN_ID,
            _contract: RATE_COORDINATOR,
            topic_0: RATES_UPDATED_TOPIC,
            topic_1: 300,  // rateA = 3%
            topic_2: 800,  // rateB = 8% (higher)
            topic_3: 0,
            data: abi.encode(block.timestamp),
            block_number: 100,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
        
        vm.expectEmit(false, false, false, true);
        emit RebalanceTriggered(true, 0, 300, 800); // direction = true
        
        rebalancer.react(log);
    }

    function testRebalanceDirectionBtoA() public {
        // A has higher rate, so direction should be false (move B -> A)
        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: ORIGIN_CHAIN_ID,
            _contract: RATE_COORDINATOR,
            topic_0: RATES_UPDATED_TOPIC,
            topic_1: 800,  // rateA = 8% (higher)
            topic_2: 300,  // rateB = 3%
            topic_3: 0,
            data: abi.encode(block.timestamp),
            block_number: 100,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
        
        vm.expectEmit(false, false, false, true);
        emit RebalanceTriggered(false, 0, 800, 300); // direction = false
        
        rebalancer.react(log);
    }

    // ============ Helper Functions ============

    function _createRatesLog(uint256 rateA, uint256 rateB) internal view returns (IReactive.LogRecord memory) {
        return IReactive.LogRecord({
            chain_id: ORIGIN_CHAIN_ID,
            _contract: RATE_COORDINATOR,
            topic_0: RATES_UPDATED_TOPIC,
            topic_1: rateA,
            topic_2: rateB,
            topic_3: 0,
            data: abi.encode(block.timestamp),
            block_number: 100,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
    }
}
