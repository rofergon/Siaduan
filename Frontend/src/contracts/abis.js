// MockERC20 ABI (minimal for mint and balance)
export const MockERC20ABI = [
    "function mint(uint256 amount) external",
    "function balanceOf(address account) view returns (uint256)",
    "function approve(address spender, uint256 amount) returns (bool)",
    "function allowance(address owner, address spender) view returns (uint256)",
    "function decimals() view returns (uint8)",
    "function symbol() view returns (string)",
];

// LendingVault ABI
export const LendingVaultABI = [
    "function deposit(uint256 amount) external returns (uint256)",
    "function withdraw(uint256 shareAmount) external returns (uint256)",
    "function shares(address account) view returns (uint256)",
    "function totalShares() view returns (uint256)",
    "function getTotalAssets() view returns (uint256)",
    "function getSharePrice() view returns (uint256)",
    "function getAllocations() view returns (uint256 allocA, uint256 allocB, uint256 idle)",
    "function rebalanceThreshold() view returns (uint256)",
    "event Deposited(address indexed user, uint256 amount, uint256 shares)",
    "event Withdrawn(address indexed user, uint256 shares, uint256 amount)",
    "event Rebalanced(bool direction, uint256 amount, uint256 rateA, uint256 rateB)",
];

// RateCoordinator ABI
export const RateCoordinatorABI = [
    "function reportRates(uint256 _rateA, uint256 _rateB) external",
    "function rateA() view returns (uint256)",
    "function rateB() view returns (uint256)",
    "function lastUpdate() view returns (uint256)",
    "event RatesUpdated(uint256 indexed rateA, uint256 indexed rateB, uint256 timestamp)",
];

// MockLendingPool ABI
export const MockLendingPoolABI = [
    "function poolName() view returns (string)",
    "function getSupplyRate(address asset) view returns (uint256)",
    "function getTotalDeposits(address asset) view returns (uint256)",
];
