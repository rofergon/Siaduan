// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract ComputeHash is Script {
    function run() external view {
        bytes32 hash = keccak256("PoolRateUpdated(uint256)");
        console.log("PoolRateUpdated(uint256) hash:");
        console.logBytes32(hash);
    }
}
