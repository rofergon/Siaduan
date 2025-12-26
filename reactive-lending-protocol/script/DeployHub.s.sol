// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/reactive/ReactOracleHub.sol";

contract DeployHub is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        uint256 originChainId = vm.envUint("SEPOLIA_CHAIN_ID");

        vm.startBroadcast(deployerPrivateKey);

        // System Contract address is default, so passing address(0) works to use default
        // or explicitly pass 0x0...0fffFfF
        ReactOracleHub hub = new ReactOracleHub(originChainId, address(0));

        console.log("ReactOracleHub Deployed at:", address(hub));

        vm.stopBroadcast();
    }
}
