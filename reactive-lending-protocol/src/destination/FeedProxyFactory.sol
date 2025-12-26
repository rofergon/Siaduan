// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./FeedProxy.sol";

contract FeedProxyFactory {
    event ProxyDeployed(address indexed proxy, address indexed authorizedVM, string description);

    function deployProxy(
        address _callbackProxy,
        address _authorizedReactVM,
        uint8 _decimals,
        string memory _description
    ) external returns (address proxy) {
        proxy = address(new FeedProxy(
            _callbackProxy,
            _authorizedReactVM,
            _decimals,
            _description
        ));
        
        emit ProxyDeployed(proxy, _authorizedReactVM, _description);
    }
}
