// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/destination/adapters/MockLendingPool.sol";
import "../src/mocks/MockERC20.sol";

contract MockLendingPoolTest is Test {
    MockLendingPool pool;
    MockUSDC token;
    
    address user1 = address(0x1111);
    address owner = address(this);
    
    event Deposited(address indexed user, address indexed asset, uint256 amount);
    event Withdrawn(address indexed user, address indexed asset, uint256 amount);
    event RateUpdated(address indexed asset, uint256 indexed newRate);
    event PoolRateUpdated(uint256 indexed newRate);

    function setUp() public {
        token = new MockUSDC();
        pool = new MockLendingPool("Test Pool");
        
        // Mint tokens to user
        token.mintTo(user1, 10000 * 1e6);
        
        // Approve pool
        vm.prank(user1);
        token.approve(address(pool), type(uint256).max);
    }

    // ============ Basic Tests ============

    function testPoolName() public view {
        assertEq(pool.poolName(), "Test Pool");
    }

    function testSetSupplyRate() public {
        vm.expectEmit(true, true, false, false);
        emit RateUpdated(address(token), 500);
        
        vm.expectEmit(true, false, false, false);
        emit PoolRateUpdated(500);
        
        pool.setSupplyRate(address(token), 500); // 5%
        
        assertEq(pool.getSupplyRate(address(token)), 500);
    }

    // ============ Deposit Tests ============

    function testDeposit() public {
        uint256 amount = 1000 * 1e6;
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Deposited(user1, address(token), amount);
        
        pool.deposit(address(token), amount);
        
        vm.prank(user1);
        assertEq(pool.getBalance(address(token)), amount);
        assertEq(pool.getTotalDeposits(address(token)), amount);
    }

    function testDepositZeroReverts() public {
        vm.prank(user1);
        vm.expectRevert("Amount must be > 0");
        pool.deposit(address(token), 0);
    }

    // ============ Withdraw Tests ============

    function testWithdraw() public {
        uint256 depositAmount = 1000 * 1e6;
        uint256 withdrawAmount = 400 * 1e6;
        
        vm.startPrank(user1);
        
        pool.deposit(address(token), depositAmount);
        
        uint256 balanceBefore = token.balanceOf(user1);
        
        vm.expectEmit(true, true, false, true);
        emit Withdrawn(user1, address(token), withdrawAmount);
        
        uint256 withdrawn = pool.withdraw(address(token), withdrawAmount);
        
        vm.stopPrank();
        
        assertEq(withdrawn, withdrawAmount);
        assertEq(token.balanceOf(user1), balanceBefore + withdrawAmount);
        assertEq(pool.getBalanceOf(address(token), user1), 600 * 1e6);
    }

    function testWithdrawMoreThanBalance() public {
        vm.startPrank(user1);
        
        pool.deposit(address(token), 1000 * 1e6);
        
        // Try to withdraw more than deposited - should cap at balance
        uint256 withdrawn = pool.withdraw(address(token), 5000 * 1e6);
        
        vm.stopPrank();
        
        assertEq(withdrawn, 1000 * 1e6); // Capped at actual balance
    }

    function testWithdrawNothingReverts() public {
        vm.prank(user1);
        vm.expectRevert("Nothing to withdraw");
        pool.withdraw(address(token), 100 * 1e6);
    }

    // ============ Rate Tests ============

    function testOnlyOwnerCanSetRate() public {
        vm.prank(user1);
        vm.expectRevert();
        pool.setSupplyRate(address(token), 500);
    }

    function testMultipleRateUpdates() public {
        pool.setSupplyRate(address(token), 200); // 2%
        assertEq(pool.getSupplyRate(address(token)), 200);
        
        pool.setSupplyRate(address(token), 800); // 8%
        assertEq(pool.getSupplyRate(address(token)), 800);
    }
}
