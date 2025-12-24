// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockERC20
 * @notice A mock ERC20 token for testing purposes
 * @dev Allows minting by anyone for testnet usage
 */
contract MockERC20 is ERC20, Ownable {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Mints tokens to the caller (faucet-style)
     * @param amount The amount to mint
     */
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    /**
     * @notice Mints tokens to a specific address (owner only for controlled minting)
     * @param to The address to mint to
     * @param amount The amount to mint
     */
    function mintTo(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from the caller
     * @param amount The amount to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}

/**
 * @title MockUSDT
 * @notice Mock USDT token (6 decimals)
 */
contract MockUSDT is MockERC20 {
    constructor() MockERC20("Mock Tether USD", "mUSDT", 6) {}
}

/**
 * @title MockUSDC
 * @notice Mock USDC token (6 decimals)
 */
contract MockUSDC is MockERC20 {
    constructor() MockERC20("Mock USD Coin", "mUSDC", 6) {}
}

/**
 * @title MockXAUT
 * @notice Mock Tether Gold (RWA) token (6 decimals, represents oz of gold)
 */
contract MockXAUT is MockERC20 {
    constructor() MockERC20("Mock Tether Gold", "mXAUT", 6) {}
}

/**
 * @title MockWETH
 * @notice Mock Wrapped ETH for Lasna testnet (18 decimals)
 */
contract MockWETH is MockERC20 {
    constructor() MockERC20("Mock Wrapped Ether", "mWETH", 18) {}

    /**
     * @notice Wraps ETH to WETH
     */
    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    /**
     * @notice Unwraps WETH to ETH
     * @param amount The amount to unwrap
     */
    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {
        _mint(msg.sender, msg.value);
    }
}
