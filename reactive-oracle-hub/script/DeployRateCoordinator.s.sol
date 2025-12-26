// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/destination/RateCoordinator.sol";

/**
 * @title DeployRateCoordinator
 * @notice Deploys the RateCoordinator to Sepolia
 */
contract DeployRateCoordinator is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Pool addresses from NEW Sepolia deployment (Dec 25, 2025)
        address poolA = 0x00FD6c43791752D46296F651d4e316661d90665f; // Pool Alpha
        address poolB = 0xbf7298c0517937e563B82263D28911277df194B4; // Pool Beta
        
        console.log("Deployer:", deployer);
        console.log("Deploying RateCoordinator to Sepolia...");
        console.log("");
        console.log("Configuration:");
        console.log("  Pool A:", poolA);
        console.log("  Pool B:", poolB);
        
        vm.startBroadcast(deployerPrivateKey);
        
        RateCoordinator coordinator = new RateCoordinator(
            poolA,
            poolB
        );
        
        console.log("");
        console.log("RateCoordinator deployed at:", address(coordinator));
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("RateCoordinator:", address(coordinator));
        console.log("Owner:", deployer);
        console.log("");
        console.log("=== Next Steps ===");
        console.log("1. Update LendingRebalancer to use this coordinator address");
        console.log("2. Deploy updated LendingRebalancer to Lasna");
        console.log("3. Test: reportRates(300, 800) on coordinator");
    }
}
