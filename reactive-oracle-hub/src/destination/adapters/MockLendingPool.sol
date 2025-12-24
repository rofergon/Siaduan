// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/ILendingPoolAdapter.sol";

/**
 * @title MockLendingPool
 * @notice A mock lending pool for testing cross-chain rebalancing
 * @dev Simulates a lending pool with configurable supply rates
 */
contract MockLendingPool is ILendingPoolAdapter, Ownable {
    using SafeERC20 for IERC20;

    string public override poolName;
    
    // Asset -> depositor -> balance
    mapping(address => mapping(address => uint256)) public deposits;
    // Asset -> total deposits
    mapping(address => uint256) public totalDeposits;
    // Asset -> supply rate (in basis points, e.g., 500 = 5%)
    mapping(address => uint256) public supplyRates;
    
    // Events
    event Deposited(address indexed user, address indexed asset, uint256 amount);
    event Withdrawn(address indexed user, address indexed asset, uint256 amount);
    event RateUpdated(address indexed asset, uint256 indexed newRate);
    event PoolRateUpdated(uint256 indexed newRate); // For reactive to listen

    constructor(string memory _poolName) Ownable(msg.sender) {
        poolName = _poolName;
    }

    /**
     * @notice Sets the supply rate for an asset
     * @param asset The asset address
     * @param rate The rate in basis points (100 = 1%)
     */
    function setSupplyRate(address asset, uint256 rate) external onlyOwner {
        supplyRates[asset] = rate;
        emit RateUpdated(asset, rate);
        emit PoolRateUpdated(rate); // Generic event for reactive subscription
    }

    /**
     * @notice Deposits assets into the pool
     * @param asset The asset to deposit
     * @param amount The amount to deposit
     */
    function deposit(address asset, uint256 amount) external override {
        require(amount > 0, "Amount must be > 0");
        
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        
        deposits[asset][msg.sender] += amount;
        totalDeposits[asset] += amount;
        
        emit Deposited(msg.sender, asset, amount);
    }

    /**
     * @notice Withdraws assets from the pool
     * @param asset The asset to withdraw
     * @param amount The amount to withdraw
     * @return The actual amount withdrawn
     */
    function withdraw(address asset, uint256 amount) external override returns (uint256) {
        uint256 balance = deposits[asset][msg.sender];
        uint256 toWithdraw = amount > balance ? balance : amount;
        
        require(toWithdraw > 0, "Nothing to withdraw");
        
        deposits[asset][msg.sender] -= toWithdraw;
        totalDeposits[asset] -= toWithdraw;
        
        IERC20(asset).safeTransfer(msg.sender, toWithdraw);
        
        emit Withdrawn(msg.sender, asset, toWithdraw);
        return toWithdraw;
    }

    /**
     * @notice Gets the balance of an asset for the caller
     * @param asset The asset address
     * @return The balance
     */
    function getBalance(address asset) external view override returns (uint256) {
        return deposits[asset][msg.sender];
    }

    /**
     * @notice Gets balance for any address (for vault)
     * @param asset The asset address
     * @param account The account to check
     * @return The balance
     */
    function getBalanceOf(address asset, address account) external view returns (uint256) {
        return deposits[asset][account];
    }

    /**
     * @notice Gets the current supply rate for an asset
     * @param asset The asset address
     * @return The rate in basis points
     */
    function getSupplyRate(address asset) external view override returns (uint256) {
        return supplyRates[asset];
    }

    /**
     * @notice Gets total deposits for an asset
     * @param asset The asset address
     * @return Total deposits
     */
    function getTotalDeposits(address asset) external view returns (uint256) {
        return totalDeposits[asset];
    }
}
