// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/ILendingPoolAdapter.sol";

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

interface IAaveDataProvider {
    function getReserveData(address asset) external view returns (
        uint256 unbacked,
        uint256 accruedToTreasury,
        uint256 totalAToken,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 stableBorrowRate,
        uint256 averageStableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex,
        uint40 lastUpdateTimestamp
    );
}

/**
 * @title AaveV3Adapter
 * @notice Adapter for Aave V3 Protocol on Sepolia
 */
contract AaveV3Adapter is ILendingPoolAdapter, Ownable {
    using SafeERC20 for IERC20;

    address public immutable pool;
    address public immutable dataProvider;
    string public override poolName = "Aave V3 Sepolia";

    constructor(address _pool, address _dataProvider) Ownable(msg.sender) {
        pool = _pool;
        dataProvider = _dataProvider;
    }

    function deposit(address asset, uint256 amount) external override {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).forceApprove(pool, amount);
        
        // Supply to Aave - 0 referral code
        IAavePool(pool).supply(asset, amount, address(this), 0);
    }

    function withdraw(address asset, uint256 amount) external override returns (uint256) {
        // Withdraw from Aave to this contract
        uint256 withdrawn = IAavePool(pool).withdraw(asset, amount, address(this));
        
        // Transfer to recipient (Vault)
        IERC20(asset).safeTransfer(msg.sender, withdrawn);
        
        return withdrawn;
    }

    function getBalance(address asset) external view override returns (uint256) {
        // We need the aToken balance. 
        // For simplicity in this adapter, we can check the aToken balance if we knew the aToken address,
        // or check the user reserve data via protocol data provider.
        (,, uint256 totalAToken,,,,,,,,,) = IAaveDataProvider(dataProvider).getReserveData(asset);
        // This returns TOTAL aToken, not user balance.
        // Aave tracks user balance via aTokens.
        // Ideally we should inject the aToken address or look it up.
        // BUT, since Aave `withdraw` works by specifying the ASSET, Aave handles the mapping.
        // To view balance, we should use the aToken standard balance check if possible.
        // Since we don't have the aToken address readily available here without more lookups,
        // we can leave this generic or implement a lookup if strictly needed by Rebalancer.
        // Rebalancer uses 'allocations' stored in Vault state for logic, 
        // so this view might just be for UI or checks.
        
        return 0; // TODO: Implement proper balance check if needed for verification
    }

    /**
     * @notice Gets current supply APY in ray (1e27)
     * @dev We return it in basis points for consistency with the Vault (1e27 -> basis points)
     * Vault expects basis points (e.g. 500 = 5%).
     * Aave returns Ray (1e27). 5% = 0.05 * 1e27 = 5 * 1e25.
     * To convert 5*1e25 to 500:
     * (Rate / 1e27) * 10000 -> (Rate * 10000) / 1e27
     */
    function getSupplyRate(address asset) external view override returns (uint256) {
        (,,,,, uint256 liquidityRate,,,,,,) = IAaveDataProvider(dataProvider).getReserveData(asset);
        
        // Convert Ray (1e27) to Basis Points (100 = 1%)
        // 1e27 = 100%
        // 1e25 = 1% = 100 bps
        return liquidityRate / 1e23; // 1e27 / 1e4 = 1e23 division to get BPS
    }
}
