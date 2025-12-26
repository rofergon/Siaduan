// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/reactive/LendingRebalancer.sol";

/**
 * @title RedeployLendingRebalancer
 * @notice Redeploys the LendingRebalancer with the CORRECT vault address
 * @dev The ReactVM is STATELESS - vault address must be correct at deployment
 */
contract RedeployLendingRebalancer is Script {
    // Chain IDs
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    
    // CORRECT addresses
    address constant RATE_COORDINATOR = 0x8d8159e74eE9c987925a2B5b21Cc6D6970513648;
    address constant NEW_VAULT = 0xf8Af4B57A22328Af51448A43eEF1bbdE8542852D;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Redeploying LendingRebalancer ===");
        console.log("Deployer:", deployer);
        console.log("RateCoordinator:", RATE_COORDINATOR);
        console.log("NEW Vault:", NEW_VAULT);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy with 0.5 REACT (sufficient for testing)
        LendingRebalancer rebalancer = new LendingRebalancer{value: 0.5 ether}(
            SEPOLIA_CHAIN_ID,      // Origin chain ID
            RATE_COORDINATOR,      // RateCoordinator address
            SEPOLIA_CHAIN_ID,      // Destination chain ID
            NEW_VAULT              // NEW Vault address
        );
        
        console.log("");
        console.log("=== NEW LendingRebalancer deployed at:", address(rebalancer), "===");
        
        // NOTE: Do NOT call subscribeToCoordinator() here - it will fail and revert the deploy
        // Call it manually AFTER deployment
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("Next steps:");
        console.log("1. Update authorizedReactVM on vault:", NEW_VAULT);
        console.log("   cast send", NEW_VAULT, "'setAuthorizedReactVM(address)'", deployer);
        console.log("2. Update frontend REACTIVE_ADDRESSES with new rebalancer address");
        console.log("3. Test: cast send", RATE_COORDINATOR, "'reportRates(uint256,uint256)' 600 1500");
    }
}
