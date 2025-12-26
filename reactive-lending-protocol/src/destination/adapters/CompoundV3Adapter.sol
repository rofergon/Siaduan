// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/ILendingPoolAdapter.sol";

interface IComet {
    function supply(address asset, uint256 amount) external;
    function withdraw(address asset, uint256 amount) external;
    function getSupplyRate(uint256 utilization) external view returns (uint64);
    function getUtilization() external view returns (uint256);
    function userBasic(address account) external view returns (int104 principal, uint64 baseTrackingIndex, uint64 baseTrackingAccrued, uint16 assetsIn, uint8 _reserved);
    function baseToken() external view returns (address);
}

/**
 * @title CompoundV3Adapter
 * @notice Adapter for Compound V3 (Comet) on Sepolia
 */
contract CompoundV3Adapter is ILendingPoolAdapter, Ownable {
    using SafeERC20 for IERC20;

    address public immutable comet;
    string public override poolName = "Compound V3 Sepolia";

    constructor(address _comet) Ownable(msg.sender) {
        comet = _comet;
    }

    function deposit(address asset, uint256 amount) external override {
        // Compound V3 Comet usually only accepts the base token for supply (e.g. USDC for cUSDCv3)
        // Check if asset matches base token (optional safety check)
        require(asset == IComet(comet).baseToken(), "Invalid asset for this Comet");
        
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).forceApprove(comet, amount);
        
        IComet(comet).supply(asset, amount);
    }

    function withdraw(address asset, uint256 amount) external override returns (uint256) {
        // Withdraw from Comet
        IComet(comet).withdraw(asset, amount);
        
        // Transfer to recipient (Vault)
        IERC20(asset).safeTransfer(msg.sender, amount);
        
        return amount;
    }

    function getBalance(address asset) external view override returns (uint256) {
        // Comet stores balance in `userBasic`
        (int104 principal,,,,) = IComet(comet).userBasic(address(this));
        if (principal > 0) {
            return uint256(int256(principal));
        }
        return 0;
    }

    /**
     * @notice Gets current supply APY in basis points
     * @dev Compound returns rate as uint64 per second? Or similar.
     * We need to check getSupplyRate signature and return format.
     * Standard Comet `getSupplyRate` returns rate per second in 1e18 scale usually.
     * We need Annual Percentage Rate (APR) in bps.
     * APR = RatePerSecond * SecondsPerYear
     */
    function getSupplyRate(address asset) external view override returns (uint256) {
        uint256 utilization = IComet(comet).getUtilization();
        uint64 ratePerSecond = IComet(comet).getSupplyRate(utilization);
        
        // Rate per second is scaled by 1e18?
        // Let's assume standard Compound math:
        // APR = ratePerSecond * 31536000 (seconds per year)
        // Rate is likely 1e18 based.
        // Result needed in Basis Points (1e4).
        
        // Example: 5% APY -> 0.05
        // RatePerSec ~ 1.58e-9 (approx) * 1e18 = 1.58e9
        
        uint256 apr = uint256(ratePerSecond) * 31536000;
        
        // Convert to basis points
        // If ratePerSecond is 1e18 based:
        // APR (1e18) / 1e14 -> Basis Points (1e4)
        return apr / 1e14;
    }
}
