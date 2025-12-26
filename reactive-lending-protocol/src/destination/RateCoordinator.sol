// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RateCoordinator
 * @notice Aggregates rates from multiple lending pools and emits a single event
 * @dev This pattern is essential for Reactive Network's stateless ReactVM
 *      Each pool reports its rate here, and a single event is emitted with all data
 */
contract RateCoordinator is Ownable {
    
    // ============ State ============
    
    struct PoolRate {
        address pool;
        uint256 rate;
        uint256 lastUpdate;
        bool active;
    }
    
    // Pool identifier => PoolRate
    mapping(bytes32 => PoolRate) public poolRates;
    bytes32[] public poolIds;
    
    // Primary pools for comparison (can be extended)
    bytes32 public constant POOL_A = keccak256("POOL_A");
    bytes32 public constant POOL_B = keccak256("POOL_B");
    
    // Rate for Pool A and Pool B (cached for easy access)
    uint256 public rateA;
    uint256 public rateB;
    
    // ============ Events ============
    
    // Single event with both rates - this is what ReactVM subscribes to
    event RatesUpdated(
        uint256 indexed rateA,
        uint256 indexed rateB,
        uint256 timestamp
    );
    
    event PoolRegistered(bytes32 indexed poolId, address pool);
    event PoolRateReported(bytes32 indexed poolId, uint256 rate);
    
    // ============ Constructor ============
    
    constructor(
        address _poolA,
        address _poolB
    ) Ownable(msg.sender) {
        // Register initial pools
        if (_poolA != address(0)) {
            poolRates[POOL_A] = PoolRate({
                pool: _poolA,
                rate: 0,
                lastUpdate: 0,
                active: true
            });
            poolIds.push(POOL_A);
            emit PoolRegistered(POOL_A, _poolA);
        }
        
        if (_poolB != address(0)) {
            poolRates[POOL_B] = PoolRate({
                pool: _poolB,
                rate: 0,
                lastUpdate: 0,
                active: true
            });
            poolIds.push(POOL_B);
            emit PoolRegistered(POOL_B, _poolB);
        }
    }
    
    // ============ Rate Reporting ============
    
    /**
     * @notice Reports rate for Pool A and emits combined event
     * @param rate The new rate in basis points (100 = 1%)
     */
    function reportRateA(uint256 rate) external onlyOwner {
        rateA = rate;
        poolRates[POOL_A].rate = rate;
        poolRates[POOL_A].lastUpdate = block.timestamp;
        
        emit PoolRateReported(POOL_A, rate);
        
        // Always emit combined event for ReactVM
        emit RatesUpdated(rateA, rateB, block.timestamp);
    }
    
    /**
     * @notice Reports rate for Pool B and emits combined event
     * @param rate The new rate in basis points (100 = 1%)
     */
    function reportRateB(uint256 rate) external onlyOwner {
        rateB = rate;
        poolRates[POOL_B].rate = rate;
        poolRates[POOL_B].lastUpdate = block.timestamp;
        
        emit PoolRateReported(POOL_B, rate);
        
        // Always emit combined event for ReactVM
        emit RatesUpdated(rateA, rateB, block.timestamp);
    }
    
    /**
     * @notice Reports both rates at once (most efficient)
     * @param _rateA Rate for Pool A in basis points
     * @param _rateB Rate for Pool B in basis points
     */
    function reportRates(uint256 _rateA, uint256 _rateB) external onlyOwner {
        rateA = _rateA;
        rateB = _rateB;
        
        poolRates[POOL_A].rate = _rateA;
        poolRates[POOL_A].lastUpdate = block.timestamp;
        poolRates[POOL_B].rate = _rateB;
        poolRates[POOL_B].lastUpdate = block.timestamp;
        
        emit PoolRateReported(POOL_A, _rateA);
        emit PoolRateReported(POOL_B, _rateB);
        emit RatesUpdated(rateA, rateB, block.timestamp);
    }
    
    // ============ Admin Functions ============
    
    /**
     * @notice Registers a new pool
     */
    function registerPool(bytes32 poolId, address pool) external onlyOwner {
        require(!poolRates[poolId].active, "Pool already registered");
        
        poolRates[poolId] = PoolRate({
            pool: pool,
            rate: 0,
            lastUpdate: 0,
            active: true
        });
        poolIds.push(poolId);
        
        emit PoolRegistered(poolId, pool);
    }
    
    /**
     * @notice Updates pool address
     */
    function setPoolAddress(bytes32 poolId, address pool) external onlyOwner {
        require(poolRates[poolId].active, "Pool not registered");
        poolRates[poolId].pool = pool;
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Gets both rates in a single call
     */
    function getRates() external view returns (uint256, uint256) {
        return (rateA, rateB);
    }
    
    /**
     * @notice Gets rate for a specific pool
     */
    function getPoolRate(bytes32 poolId) external view returns (uint256 rate, uint256 lastUpdate) {
        PoolRate storage pr = poolRates[poolId];
        return (pr.rate, pr.lastUpdate);
    }
    
    /**
     * @notice Gets total number of registered pools
     */
    function getPoolCount() external view returns (uint256) {
        return poolIds.length;
    }
}
