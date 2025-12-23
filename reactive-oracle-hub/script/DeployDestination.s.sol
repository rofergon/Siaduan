// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/destination/FeedProxy.sol";

contract DeployDestination is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        address callbackProxy = vm.envAddress("CALLBACK_PROXY_ADDR_SEPOLIA");
        
        // Config for ETH/USD Feed on Sepolia
        uint8 decimals = 8;
        string memory description = "ETH/USD (Reactive)";
        
        // Authorized RVM ID is the deployer's address
        address authorizedRvmId = deployerAddress;

        vm.startBroadcast(deployerPrivateKey);

        FeedProxy proxy = new FeedProxy(
            callbackProxy,
            authorizedRvmId,
            decimals,
            description
        );

        console.log("FeedProxy Deployed at:", address(proxy));
        console.log("Authorized RVM ID:", authorizedRvmId);
        console.log("Callback Proxy:", callbackProxy);

        vm.stopBroadcast();
    }
}
