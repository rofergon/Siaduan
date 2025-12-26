// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/destination/LendingVault.sol";
import "../src/destination/adapters/AaveV3Adapter.sol";
import "../src/destination/adapters/CompoundV3Adapter.sol";
import "../src/mocks/MockERC20.sol";

contract DeployRealLendingSystem is Script {
    // Sepolia Addresses
    address constant SEPOLIA_USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // Circle USDC on Sepolia
    address constant AAVE_POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address constant AAVE_DATA_PROVIDER = 0x3e9708d80f7B3e43118013075F7e95CE3AB31F31;
    address constant COMPOUND_COMET = 0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e; // cUSDCv3 Sepolia
    address constant SEPOLIA_USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // Circle USDC on Sepolia
    address constant AAVE_POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address constant AAVE_DATA_PROVIDER = 0x3e9708d80f7B3e43118013075F7e95CE3AB31F31;
    address constant COMPOUND_COMET = 0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e; // cUSDCv3 Sepolia

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address callbackProxy = vm.envAddress("CALLBACK_PROXY_ADDR_SEPOLIA");

        
        console.log("Deployer:", deployer);
        console.log("Deploying Real Lending System to Sepolia...");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy Adapters
        AaveV3Adapter aaveAdapter = new AaveV3Adapter(AAVE_POOL, AAVE_DATA_PROVIDER);
        console.log("AaveV3Adapter deployed at:", address(aaveAdapter));
        
        CompoundV3Adapter compoundAdapter = new CompoundV3Adapter(COMPOUND_COMET);
        console.log("CompoundV3Adapter deployed at:", address(compoundAdapter));
        
        // 2. Deploy Real Vault
        // Note: Using real SEPOLIA_USDC
        LendingVault vault = new LendingVault(
            SEPOLIA_USDC,
            callbackProxy,
            deployer, // Will be updated
            address(aaveAdapter),
            address(compoundAdapter)
        );
        console.log("RealLendingVault deployed at:", address(vault));
        
        // 3. Initialize Adapters (if needed, mostly handled by constructor)
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Real System Deployment Summary ===");
        console.log("Asset (USDC):", SEPOLIA_USDC);
        console.log("Aave Adapter:", address(aaveAdapter));
        console.log("Compound Adapter:", address(compoundAdapter));
        console.log("Real LendingVault:", address(vault));
        console.log("");
        console.log("Next Step: Deploy new LendingRebalancer on Lasna pointing to this Vault.");
    }
}
