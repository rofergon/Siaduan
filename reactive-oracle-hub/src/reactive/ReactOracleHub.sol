// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "reactive-lib/abstract-base/AbstractReactive.sol";
import "reactive-lib/interfaces/ISystemContract.sol";

/**
 * @title ReactOracleHub
 * @notice A universal cross-chain oracle hub that replicates Chainlink price feeds.
 * @dev Deployed on Reactive Network. Listens to events on Origin and callbacks Destination.
 */
contract ReactOracleHub is AbstractReactive {
    
    // Chainlink AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt)
    // Topic 0 is the keccak256 hash of the event signature.
    uint256 constant ANSWER_UPDATED_TOPIC_0 = 0x0559884fd3a460db3073b7fc896cc77986f16e378210ded43186175bf646fc5f;
    
    // Gas limit for the callback transaction on destination chain
    uint64 constant CALLBACK_GAS_LIMIT = 500000;

    struct Destination {
        uint256 chainId;
        address proxyAddr;
        bool active;
    }

    // Origin Aggregator -> List of Destinations
    mapping(address => Destination[]) public feedDestinations;
    // Track subscriptions to avoid redundant calls
    mapping(address => bool) public isSubscribed;
    
    uint256 public immutable originChainId;
    
    event FeedRegistered(address indexed aggregator, uint256 destChainId, address proxy);
    event CallbackSent(uint256 indexed destChainId, address indexed proxy, int256 price);

    constructor(
        uint256 _originChainId,
        address _service
    ) { 
        originChainId = _originChainId;
        if (_service != address(0)) {
            service = ISystemContract(payable(_service));
        }
    }

    /**
     * @notice Registers a destination proxy for a generic Chainlink aggregator.
     * @dev Subscribes to the aggregator if not already subscribed.
     * @param _aggregator The Chainlink Aggregator address on the Origin chain.
     * @param _destChainId The Chain ID of the destination.
     * @param _destProxy The FeedProxy address on the destination.
     */
    function registerFeed(
        address _aggregator,
        uint256 _destChainId,
        address _destProxy
    ) external {
        require(_aggregator != address(0), "Invalid aggregator");
        require(_destProxy != address(0), "Invalid proxy");
        
        // Add destination
        feedDestinations[_aggregator].push(Destination({
            chainId: _destChainId,
            proxyAddr: _destProxy,
            active: true
        }));
        
        // Subscribe if needed
        // Note: subscribe() is called on the system contract to tell Reactive Network to listen.
        // This usually only works if called from the Reactive Network context (not ReactVM),
        // OR if the system supports dynamic subscriptions from ReactVM.
        // Documentation says: "Subscriptions are established by invoking the subscribe() method... typically called in the contract's constructor() or dynamically via a callback."
        // Wait, "dynamically via a callback" means the ReactVM must emit a Callback to the System Contract?
        // Or can we call service.subscribe inside a normal transaction on RN?
        // The registerFeed function is intended to be called by a user (transaction on RN).
        // Since AbstractReactive.detectVm() determines context.
        // If we are on RN (vm=false), we can call service.subscribe.
        // So this function must be called on RN.
        
        if (!vm) {
            if (!isSubscribed[_aggregator]) {
                service.subscribe(
                    originChainId,
                    _aggregator,
                    ANSWER_UPDATED_TOPIC_0,
                    REACTIVE_IGNORE,
                    REACTIVE_IGNORE,
                    REACTIVE_IGNORE
                );
                isSubscribed[_aggregator] = true;
            }
        } else {
            // If called inside ReactVM (e.g. self-call?), we can't subscribe directly.
            // But this function is external, meant for users to call on the network.
            // So !vm check is appropriate or assume it runs on RN.
        }
        
        emit FeedRegistered(_aggregator, _destChainId, _destProxy);
    }

    /**
     * @notice Reacts to events. Called by the system in ReactVM.
     * @param log The log record from the origin chain.
     */
    function react(LogRecord calldata log) external override vmOnly {
        // Ensure it's the AnswerUpdated event
        if (log.topic_0 != ANSWER_UPDATED_TOPIC_0) return;
        
        // Decode Chainlink event data
        // Event: AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt)
        // Indexed parameters are in topics.
        // topic_0: Event signature hash
        // topic_1: current (int256)
        // topic_2: roundId (uint256)
        // data: updatedAt (uint256) (non-indexed)
        
        int256 answer = int256(log.topic_1);
        uint80 roundId = uint80(log.topic_2);
        
        // Note: log.data is bytes. We need to decode it.
        // Although the event has only one non-indexed param, Abi decoding expects full 32-byte chunks.
        uint256 updatedAt = abi.decode(log.data, (uint256));
        
        // Iterate over destinations for this aggregator
        Destination[] memory dests = feedDestinations[log._contract];
        
        for (uint i = 0; i < dests.length; i++) {
            if (!dests[i].active) continue;
            
            // Construct payload for FeedProxy.updatePrice(...)
            // Signature: updatePrice(address,uint80,int256,uint256,uint256,uint80)
            bytes memory payload = abi.encodeWithSignature(
                "updatePrice(address,uint80,int256,uint256,uint256,uint80)",
                address(0), // Placeholder for sender (replaced by RVM ID)
                roundId,
                answer,
                updatedAt, // startedAt (using updatedAt as proxy)
                updatedAt, // updatedAt
                roundId    // answeredInRound
            );
            
            emit Callback(
                dests[i].chainId,
                dests[i].proxyAddr,
                CALLBACK_GAS_LIMIT,
                payload
            );
            
            emit CallbackSent(dests[i].chainId, dests[i].proxyAddr, answer);
        }
    }
}
