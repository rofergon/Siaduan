// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/reactive/ReactOracleHub.sol";

contract RegisterFeed is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        address hubAddr = vm.envAddress("HUB_ADDR");
        address proxyAddr = vm.envAddress("FEED_PROXY_ADDR");
        
        // Sepolia ETH/USD Aggregator
        address aggregator = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        uint256 destChainId = vm.envUint("SEPOLIA_CHAIN_ID");

        vm.startBroadcast(deployerPrivateKey);

        ReactOracleHub hub = ReactOracleHub(payable(hubAddr));
        
        hub.registerFeed(aggregator, destChainId, proxyAddr);

        console.log("Feed Registered:");
        console.log("Aggregator:", aggregator);
        console.log("Destination Chain:", destChainId);
        console.log("Proxy:", proxyAddr);

        vm.stopBroadcast();
    }
}
