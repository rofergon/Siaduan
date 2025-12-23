// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/reactive/ReactOracleHub.sol";
import "reactive-lib/interfaces/IReactive.sol";

contract MockSystemContract {
    event SubscribeCalled(uint256 chainId, address contractAddr, uint256 topic0);
    function subscribe(uint256 chainId, address contractAddr, uint256 topic0, uint256, uint256, uint256) external {
        emit SubscribeCalled(chainId, contractAddr, topic0);
    }
}

contract ReactOracleHubTest is Test {
    ReactOracleHub hub;
    address constant SYSTEM_ADDR = 0x0000000000000000000000000000000000fffFfF;
    uint256 constant ORIGIN_CHAIN_ID = 11155111;
    uint256 constant DEST_CHAIN_ID = 5318007; // Lasna (or Loopback)
    address constant AGGREGATOR = address(0xABC);
    address constant PROXY = address(0xDEF);

    // Topic for AnswerUpdated
    uint256 constant ANSWER_UPDATED_TOPIC = 0x0559884fd3a460db3073b7fc896cc77986f16e378210ded43186175bf646fc5f;

    event SubscribeCalled(uint256 chainId, address contractAddr, uint256 topic0);
    event Callback(uint256 indexed chain_id, address indexed _contract, uint64 indexed gas_limit, bytes payload);

    function setUp() public {
        // Initially, do NOT etch system contract, so we are in "VM" mode by default?
        // Actually, hub constructor calls detectVm. 
        // We want two separate tests contexts.
    }

    function testRegisterFeedOnNetwork() public {
        // SIMULATE REACTIVE NETWORK (L1) MODE
        // 1. Etch code to SYSTEM_ADDR to make detectVm() return false (vm = false)
        // We deploy MockSystemContract code there.
        vm.etch(SYSTEM_ADDR, address(new MockSystemContract()).code);
        
        // 2. Deploy Hub. Constructor runs detectVm -> sees code -> vm = false.
        hub = new ReactOracleHub(ORIGIN_CHAIN_ID, SYSTEM_ADDR);
        
        // 3. Register Feed
        // Expect subscription call
        vm.expectEmit(false, false, false, true); // Check data mostly
        emit SubscribeCalled(ORIGIN_CHAIN_ID, AGGREGATOR, ANSWER_UPDATED_TOPIC);
        
        hub.registerFeed(AGGREGATOR, DEST_CHAIN_ID, PROXY);
        
        // Verify mapping
        (uint256 chainId, address proxy, bool active) = hub.feedDestinations(AGGREGATOR, 0);
        assertEq(chainId, DEST_CHAIN_ID);
        assertEq(proxy, PROXY);
        assertTrue(active);
        assertTrue(hub.isSubscribed(AGGREGATOR));
    }

    function testReactInVM() public {
        // SIMULATE REACTVM MODE
        // 1. Ensure NO code at SYSTEM_ADDR (default in Foundry).
        // vm = true.
        hub = new ReactOracleHub(ORIGIN_CHAIN_ID, SYSTEM_ADDR);
        
        // 2. Register Feed (manually or via function)
        // Calling registerFeed directly here will skip subscribe because vm=true.
        // This is fine, we just want to populate storage.
        hub.registerFeed(AGGREGATOR, DEST_CHAIN_ID, PROXY);
        
        // 3. Prepare LogRecord
        // Signal: AnswerUpdated(int256 current, uint256 roundId, uint256 updatedAt)
        int256 answer = 1500 * 1e8;
        uint256 roundId = 42;
        uint256 updatedAt = block.timestamp;
        
        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: ORIGIN_CHAIN_ID,
            _contract: AGGREGATOR,
            topic_0: ANSWER_UPDATED_TOPIC,
            topic_1: uint256(answer), // indexed current
            topic_2: roundId,         // indexed roundId
            topic_3: 0,
            data: abi.encode(updatedAt), // non-indexed updatedAt
            block_number: 100,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });

        // 4. Expect Callback
        bytes memory expectedPayload = abi.encodeWithSignature(
            "updatePrice(address,uint80,int256,uint256,uint256,uint80)",
            address(0), 
            uint80(roundId),
            answer,
            updatedAt,
            updatedAt,
            uint80(roundId)
        );

        vm.expectEmit(true, true, true, true);
        emit Callback(DEST_CHAIN_ID, PROXY, 500000, expectedPayload);
        
        // 5. Call react (onlyVM protected)
        // Since we didn't etch, vm=true, so call succeeds.
        hub.react(log);
    }
}
