// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILendingPoolAdapter
 * @notice Interface for lending pool adapters (Aave, Compound, Mock, etc.)
 */
interface ILendingPoolAdapter {
    /**
     * @notice Deposits assets into the lending pool
     * @param asset The address of the asset to deposit
     * @param amount The amount to deposit
     */
    function deposit(address asset, uint256 amount) external;

    /**
     * @notice Withdraws assets from the lending pool
     * @param asset The address of the asset to withdraw
     * @param amount The amount to withdraw
     * @return The actual amount withdrawn
     */
    function withdraw(address asset, uint256 amount) external returns (uint256);

    /**
     * @notice Gets the current balance of an asset in the pool
     * @param asset The address of the asset
     * @return The balance of the asset
     */
    function getBalance(address asset) external view returns (uint256);

    /**
     * @notice Gets the current supply rate (APY) for an asset
     * @param asset The address of the asset
     * @return The supply rate in ray (1e27) or basis points depending on implementation
     */
    function getSupplyRate(address asset) external view returns (uint256);

    /**
     * @notice Gets the pool's name for identification
     * @return The pool name
     */
    function poolName() external view returns (string memory);
}
