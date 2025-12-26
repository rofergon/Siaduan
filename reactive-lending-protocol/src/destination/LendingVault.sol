// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title LendingVault
 * @notice A cross-chain automated lending vault that rebalances between two pools
 * @dev Receives rebalancing commands from ReactOracleHub via Reactive Network callbacks
 */
contract LendingVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Structs ============
    struct PoolInfo {
        address pool;           // Pool contract address
        uint256 allocation;     // Amount currently allocated to this pool
        bool active;            // Is pool active
    }

    // ============ State ============
    IERC20 public immutable asset;          // The token this vault accepts
    address public immutable callbackProxy; // Reactive Network Callback Proxy
    address public authorizedReactVM;       // The LendingRebalancer address on Reactive
    
    PoolInfo public poolA;
    PoolInfo public poolB;
    
    // User shares
    mapping(address => uint256) public shares;
    uint256 public totalShares;
    
    // Configuration
    uint256 public rebalanceThreshold = 200; // 2% in basis points
    uint256 public constant BASIS_POINTS = 10000;
    
    // ============ Events ============
    event Deposited(address indexed user, uint256 amount, uint256 shares);
    event Withdrawn(address indexed user, uint256 shares, uint256 amount);
    event Rebalanced(bool direction, uint256 amount, uint256 rateA, uint256 rateB);
    event PoolUpdated(bool isPoolA, address pool);
    event AuthorizedReactVMUpdated(address newReactVM);

    // ============ Errors ============
    error Unauthorized();
    error InvalidAmount();
    error InsufficientShares();
    error PoolNotActive();
    error NoRebalanceNeeded();

    // ============ Modifiers ============
    modifier onlyReactive() {
        if (msg.sender != callbackProxy) revert Unauthorized();
        _;
    }

    constructor(
        address _asset,
        address _callbackProxy,
        address _authorizedReactVM,
        address _poolA,
        address _poolB
    ) Ownable(msg.sender) {
        require(_asset != address(0), "Invalid asset");
        require(_callbackProxy != address(0), "Invalid callback proxy");
        
        asset = IERC20(_asset);
        callbackProxy = _callbackProxy;
        authorizedReactVM = _authorizedReactVM;
        
        poolA = PoolInfo({
            pool: _poolA,
            allocation: 0,
            active: _poolA != address(0)
        });
        
        poolB = PoolInfo({
            pool: _poolB,
            allocation: 0,
            active: _poolB != address(0)
        });
        
        // Approve pools to spend vault's tokens
        if (_poolA != address(0)) {
            asset.approve(_poolA, type(uint256).max);
        }
        if (_poolB != address(0)) {
            asset.approve(_poolB, type(uint256).max);
        }
    }

    // ============ User Functions ============

    /**
     * @notice Deposits assets into the vault
     * @param amount The amount to deposit
     * @return sharesReceived The number of shares minted
     */
    function deposit(uint256 amount) external nonReentrant returns (uint256 sharesReceived) {
        if (amount == 0) revert InvalidAmount();
        
        // Transfer tokens from user
        asset.safeTransferFrom(msg.sender, address(this), amount);
        
        // Calculate shares
        uint256 totalAssets = getTotalAssets();
        if (totalShares == 0 || totalAssets == 0) {
            sharesReceived = amount;
        } else {
            sharesReceived = (amount * totalShares) / totalAssets;
        }
        
        // Mint shares
        shares[msg.sender] += sharesReceived;
        totalShares += sharesReceived;
        
        // Deposit to Pool A by default (or split based on strategy)
        _depositToPool(true, amount);
        
        emit Deposited(msg.sender, amount, sharesReceived);
    }

    /**
     * @notice Withdraws assets from the vault by burning shares
     * @param shareAmount The number of shares to burn
     * @return amountReceived The amount of assets received
     */
    function withdraw(uint256 shareAmount) external nonReentrant returns (uint256 amountReceived) {
        if (shareAmount == 0) revert InvalidAmount();
        if (shares[msg.sender] < shareAmount) revert InsufficientShares();
        
        // Calculate assets to return
        uint256 totalAssets = getTotalAssets();
        amountReceived = (shareAmount * totalAssets) / totalShares;
        
        // Burn shares
        shares[msg.sender] -= shareAmount;
        totalShares -= shareAmount;
        
        // Withdraw from pools (proportionally)
        _withdrawFromPools(amountReceived);
        
        // Transfer to user
        asset.safeTransfer(msg.sender, amountReceived);
        
        emit Withdrawn(msg.sender, shareAmount, amountReceived);
    }

    // ============ Reactive Callback ============

    /**
     * @notice Rebalances funds between pools. Called by LendingRebalancer via Reactive.
     * @param _sender The ReactVM ID (must match authorizedReactVM)
     * @param direction true = move from A to B, false = move from B to A
     * @param amount The amount to move
     * @param rateA Current rate of pool A (for logging)
     * @param rateB Current rate of pool B (for logging)
     */
    function rebalance(
        address _sender,
        bool direction,
        uint256 amount,
        uint256 rateA,
        uint256 rateB
    ) external onlyReactive {
        require(_sender == authorizedReactVM, "Unauthorized ReactVM");
        
        // If amount is 0, calculate optimal rebalance amount (50% of source pool)
        if (amount == 0) {
            if (direction) {
                // A -> B: move 50% of Pool A's allocation
                amount = poolA.allocation / 2;
            } else {
                // B -> A: move 50% of Pool B's allocation
                amount = poolB.allocation / 2;
            }
        }
        
        // Skip if nothing to move
        if (amount == 0) return;
        
        if (direction) {
            // A -> B
            _withdrawFromPoolA(amount);
            _depositToPool(false, amount);
        } else {
            // B -> A
            _withdrawFromPoolB(amount);
            _depositToPool(true, amount);
        }
        
        emit Rebalanced(direction, amount, rateA, rateB);
    }

    // ============ Internal Functions ============

    function _depositToPool(bool isPoolA, uint256 amount) internal {
        PoolInfo storage pool = isPoolA ? poolA : poolB;
        if (!pool.active) return;
        
        // Call pool's deposit function
        (bool success,) = pool.pool.call(
            abi.encodeWithSignature("deposit(address,uint256)", address(asset), amount)
        );
        
        if (success) {
            pool.allocation += amount;
        }
    }

    function _withdrawFromPoolA(uint256 amount) internal {
        if (amount > poolA.allocation) {
            amount = poolA.allocation;
        }
        
        (bool success,) = poolA.pool.call(
            abi.encodeWithSignature("withdraw(address,uint256)", address(asset), amount)
        );
        
        if (success) {
            poolA.allocation -= amount;
        }
    }

    function _withdrawFromPoolB(uint256 amount) internal {
        if (amount > poolB.allocation) {
            amount = poolB.allocation;
        }
        
        (bool success,) = poolB.pool.call(
            abi.encodeWithSignature("withdraw(address,uint256)", address(asset), amount)
        );
        
        if (success) {
            poolB.allocation -= amount;
        }
    }

    function _withdrawFromPools(uint256 amount) internal {
        // Withdraw proportionally from both pools
        uint256 totalAlloc = poolA.allocation + poolB.allocation;
        if (totalAlloc == 0) return;
        
        uint256 fromA = (amount * poolA.allocation) / totalAlloc;
        uint256 fromB = amount - fromA;
        
        if (fromA > 0) _withdrawFromPoolA(fromA);
        if (fromB > 0) _withdrawFromPoolB(fromB);
    }

    // ============ View Functions ============

    /**
     * @notice Gets total assets managed by the vault
     * @return Total assets (in pools + idle in vault)
     */
    function getTotalAssets() public view returns (uint256) {
        return poolA.allocation + poolB.allocation + asset.balanceOf(address(this));
    }

    /**
     * @notice Gets the share price (assets per share)
     * @return Price per share in asset units
     */
    function getSharePrice() external view returns (uint256) {
        if (totalShares == 0) return 1e18;
        return (getTotalAssets() * 1e18) / totalShares;
    }

    /**
     * @notice Gets current allocations
     * @return allocA Allocation in pool A
     * @return allocB Allocation in pool B
     * @return idle Idle assets in vault
     */
    function getAllocations() external view returns (uint256 allocA, uint256 allocB, uint256 idle) {
        return (poolA.allocation, poolB.allocation, asset.balanceOf(address(this)));
    }

    // ============ Admin Functions ============

    function setPool(bool isPoolA, address _pool) external onlyOwner {
        if (isPoolA) {
            poolA.pool = _pool;
            poolA.active = _pool != address(0);
            if (_pool != address(0)) {
                asset.approve(_pool, type(uint256).max);
            }
        } else {
            poolB.pool = _pool;
            poolB.active = _pool != address(0);
            if (_pool != address(0)) {
                asset.approve(_pool, type(uint256).max);
            }
        }
        emit PoolUpdated(isPoolA, _pool);
    }

    function setAuthorizedReactVM(address _reactVM) external onlyOwner {
        authorizedReactVM = _reactVM;
        emit AuthorizedReactVMUpdated(_reactVM);
    }

    function setRebalanceThreshold(uint256 _threshold) external onlyOwner {
        rebalanceThreshold = _threshold;
    }

    // ============ ETH Management for Reactive Callbacks ============
    
    /**
     * @notice Allows the contract to receive ETH for Reactive Network callback payments
     */
    receive() external payable {}

    /**
     * @notice Allows owner to withdraw ETH from the contract
     * @param amount Amount of ETH to withdraw (in wei)
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient ETH balance");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");
    }
}
