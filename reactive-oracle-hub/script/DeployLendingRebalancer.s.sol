// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/reactive/LendingRebalancer.sol";

/**
 * @title DeployLendingRebalancer
 * @notice Deploys the LendingRebalancer to Reactive Network (Lasna)
 * @dev Updated to use RateCoordinator pattern instead of individual pool subscriptions
 */
contract DeployLendingRebalancer is Script {
    // System contract on Reactive Network
    address constant SYSTEM_CONTRACT = 0x0000000000000000000000000000000000fffFfF;
    
    // Chain IDs
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant LASNA_CHAIN_ID = 5318007;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // *** UPDATE THIS ADDRESS AFTER DEPLOYING RATE COORDINATOR ***
        address rateCoordinator = vm.envOr("RATE_COORDINATOR", address(0));
        require(rateCoordinator != address(0), "Set RATE_COORDINATOR env var");
        
        // Vault address from Sepolia deployment
        address vault = 0xa968EEB8d2897464E41De673D79f1e289A3B0b7d;
        
        console.log("Deployer:", deployer);
        console.log("Deploying LendingRebalancer to Lasna...");
        console.log("RateCoordinator:", rateCoordinator);
        console.log("Destination Vault:", vault);
        
        vm.startBroadcast(deployerPrivateKey);
        
        LendingRebalancer rebalancer = new LendingRebalancer{value: 4 ether}(
            SEPOLIA_CHAIN_ID,      // Origin chain ID
            SYSTEM_CONTRACT,       // System contract
            rateCoordinator,       // RateCoordinator address
            SEPOLIA_CHAIN_ID,      // Destination chain ID
            vault                  // Vault address
        );
        
        console.log("LendingRebalancer:", address(rebalancer));
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Next Steps ===");
        console.log("1. Subscribe: call subscribeToCoordinator()");
        console.log("2. Authorize: call setAuthorizedReactVM on vault");
        console.log("3. Test: call reportRates(300, 800) on coordinator");
    }
}
