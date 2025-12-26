// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

/**
 * @title DebugRebalancer
 * @notice Script to verify LendingRebalancer configuration and trigger subscription
 * @dev Run on Lasna testnet to subscribe to RateCoordinator events
 */
contract DebugRebalancer is Script {
    // Contract addresses
    address constant LENDING_REBALANCER = 0x8e5e742779CEE74cBa58eDA528E38A5A145a3B17;
    address constant RATE_COORDINATOR = 0x8d8159e74eE9c987925a2B5b21Cc6D6970513648;
    address constant LENDING_VAULT = 0xa968EEB8d2897464E41De673D79f1e289A3B0b7d;
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== LendingRebalancer Debug Script ===");
        console.log("");
        
        // Check configurations
        console.log("Checking LendingRebalancer configuration...");
        console.log("LendingRebalancer:", LENDING_REBALANCER);
        console.log("RateCoordinator:", RATE_COORDINATOR);
        console.log("LendingVault:", LENDING_VAULT);
        console.log("");
        
        vm.startBroadcast(privateKey);
        
        // Call subscribeToCoordinator - this is the key step!
        console.log("Calling subscribeToCoordinator()...");
        (bool success,) = LENDING_REBALANCER.call(
            abi.encodeWithSignature("subscribeToCoordinator()")
        );
        
        if (success) {
            console.log("SUCCESS: Subscribed to RateCoordinator events!");
            console.log("");
            console.log("Next steps:");
            console.log("1. Wait 1-2 minutes for subscription to propagate");
            console.log("2. Call reportRates(300, 800) on RateCoordinator (Sepolia)");
            console.log("3. Wait 2-3 minutes for rebalance callback");
            console.log("4. Check LendingVault allocations");
        } else {
            console.log("FAILED: Could not subscribe. Check:");
            console.log("- Contract may already be subscribed");
            console.log("- Insufficient REACT balance");
        }
        
        vm.stopBroadcast();
    }
}
