// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/destination/FeedProxy.sol";

contract FeedProxyTest is Test {
    FeedProxy proxy;
    address constant CALLBACK_PROXY = address(0x123);
    address constant RVM_ID = address(0x456);
    
    event PriceUpdated(uint80 indexed roundId, int256 answer, uint256 updatedAt);

    function setUp() public {
        proxy = new FeedProxy(CALLBACK_PROXY, RVM_ID, 18, "ETH/USD");
    }

    function testInitialState() public {
        assertEq(proxy.decimals(), 18);
        assertEq(proxy.description(), "ETH/USD");
        assertEq(proxy.version(), 1);
        
        (uint80 id, int256 ans, , , ) = proxy.latestRoundData();
        assertEq(id, 0);
        assertEq(ans, 0);
    }

    function testUpdatePriceAuthorized() public {
        // Mock call from Callback Proxy
        vm.prank(CALLBACK_PROXY);
        
        uint80 roundId = 1;
        int256 answer = 3000 * 1e18;
        uint256 updatedAt = block.timestamp;
        
        // Expect event
        vm.expectEmit(true, false, false, true);
        emit PriceUpdated(roundId, answer, updatedAt);

        // Call updatePrice
        // First arg _sender must be RVM_ID
        proxy.updatePrice(RVM_ID, roundId, answer, updatedAt, updatedAt, roundId);

        // Verify state
        (uint80 id, int256 ans, uint256 start, uint256 upd, uint80 ansInRound) = proxy.latestRoundData();
        assertEq(id, roundId);
        assertEq(ans, answer);
        assertEq(start, updatedAt);
        assertEq(upd, updatedAt);
        assertEq(ansInRound, roundId);
    }

    function testUpdatePriceUnauthorizedCaller() public {
        vm.expectRevert("Caller must be Callback Proxy");
        proxy.updatePrice(RVM_ID, 1, 100, 100, 100, 1);
    }

    function testUpdatePriceUnauthorizedRVM() public {
        vm.prank(CALLBACK_PROXY);
        vm.expectRevert("Unauthorized ReactVM sender");
        // Pass wrong RVM ID
        proxy.updatePrice(address(0x999), 1, 100, 100, 100, 1);
    }
    
    function testStaleUpdateRevert() public {
        vm.startPrank(CALLBACK_PROXY);
        
        // First update
        proxy.updatePrice(RVM_ID, 5, 100, 100, 100, 5);
        
        // Stale update (lower round ID)
        vm.expectRevert("Stale or older round ID");
        proxy.updatePrice(RVM_ID, 4, 100, 100, 100, 4);
        
        vm.stopPrank();
    }
}
