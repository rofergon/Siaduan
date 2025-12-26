// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/destination/LendingVault.sol";

/**
 * @title RedeployLendingVault
 * @notice Deploys a new LendingVault using existing token and pools
 * @dev This fixes the callback payment issue by adding receive() function
 */
contract RedeployLendingVault is Script {
    // Sepolia Callback Proxy
    address constant CALLBACK_PROXY = 0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA;
    
    // Existing deployed contracts
    address constant MOCK_USDC = 0xf044c58496693C106a7EaE5460d39c1E99ABE074;
    address constant POOL_A = 0x242f6bcCA3208ff2b81F57Af6B9DC281bf1EabF4;
    address constant POOL_B = 0x7952AD383bC3B3443E36d58eC585C49824E4e489;
    
    // Deployer address (ReactVM ID for authorized callbacks)
    address constant AUTHORIZED_REACT_VM = 0xaB6E247B25463F76E81aBAbBb6b0b86B40d45D38;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Redeploying LendingVault ===");
        console.log("Deployer:", deployer);
        console.log("Using existing MockUSDC:", MOCK_USDC);
        console.log("Using existing Pool A:", POOL_A);
        console.log("Using existing Pool B:", POOL_B);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy new LendingVault with receive() function
        LendingVault vault = new LendingVault(
            MOCK_USDC,
            CALLBACK_PROXY,
            AUTHORIZED_REACT_VM,
            POOL_A,
            POOL_B
        );
        
        console.log("");
        console.log("=== NEW LendingVault deployed at:", address(vault), "===");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("Next steps:");
        console.log("1. Fund vault with ETH: cast send", address(vault), "--value 0.05ether");
        console.log("2. Update rebalancer vault: cast send 0xcB3cd214a61269DC904B03831fdE7228e89aC07e 'updateVault(address)'", address(vault));
        console.log("3. Migrate funds from old vault to new vault");
        console.log("4. Update frontend addresses.js");
    }
}
