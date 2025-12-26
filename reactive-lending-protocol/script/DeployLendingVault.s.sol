// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/destination/LendingVault.sol";
import "../src/destination/adapters/MockLendingPool.sol";
import "../src/mocks/MockERC20.sol";

/**
 * @title DeployLendingVault
 * @notice Deploys the LendingVault and MockLendingPools to Sepolia
 */
contract DeployLendingVault is Script {
    // Sepolia Callback Proxy
    address constant CALLBACK_PROXY = 0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer:", deployer);
        console.log("Deploying LendingVault system to Sepolia...");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy mock token (USDC)
        MockUSDC token = new MockUSDC();
        console.log("MockUSDC deployed at:", address(token));
        
        // 2. Deploy Pool A
        MockLendingPool poolA = new MockLendingPool("Pool Alpha");
        console.log("Pool Alpha deployed at:", address(poolA));
        
        // 3. Deploy Pool B
        MockLendingPool poolB = new MockLendingPool("Pool Beta");
        console.log("Pool Beta deployed at:", address(poolB));
        
        // 4. Deploy LendingVault
        // NOTE: authorizedReactVM will be the deployer address (ReactVM ID)
        // This should match the address that deploys LendingRebalancer on Lasna
        LendingVault vault = new LendingVault(
            address(token),
            CALLBACK_PROXY,
            deployer, // Will be updated after LendingRebalancer is deployed
            address(poolA),
            address(poolB)
        );
        console.log("LendingVault deployed at:", address(vault));
        
        // 5. Set initial supply rates
        poolA.setSupplyRate(address(token), 300); // 3%
        poolB.setSupplyRate(address(token), 500); // 5%
        console.log("Initial rates set: Pool A = 3%, Pool B = 5%");
        
        // 6. Mint some test tokens to deployer
        token.mint(10000 * 1e6); // 10,000 USDC
        console.log("Minted 10,000 mUSDC to deployer");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("MockUSDC:", address(token));
        console.log("Pool Alpha:", address(poolA));
        console.log("Pool Beta:", address(poolB));
        console.log("LendingVault:", address(vault));
        console.log("");
        console.log("Next steps:");
        console.log("1. Deploy LendingRebalancer on Lasna");
        console.log("2. Update vault.setAuthorizedReactVM() with the Lasna deployer address");
        console.log("3. Fund the LendingRebalancer with REACT tokens");
    }
}
