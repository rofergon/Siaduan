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
        
        // Pool addresses from Sepolia deployment
        address poolA = 0x242f6bcCA3208ff2b81F57Af6B9DC281bf1EabF4;
        address poolB = 0x7952AD383bC3B3443E36d58eC585C49824E4e489;
        
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
