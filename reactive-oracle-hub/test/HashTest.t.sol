// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

contract HashTest is Test {
    function testComputeHash() public pure {
        bytes32 hash = keccak256("PoolRateUpdated(uint256)");
        // The hash should be exactly 32 bytes = 64 hex chars
        assertEq(uint256(hash), uint256(hash)); // Just to output it
    }
    
    function testPrintHash() public view {
        bytes32 hash = keccak256("PoolRateUpdated(uint256)");
        console.log("Hash as uint256:");
        console.log(uint256(hash));
    }
}
