// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/destination/LendingVault.sol";
import "../src/destination/adapters/MockLendingPool.sol";
import "../src/mocks/MockERC20.sol";

contract LendingVaultTest is Test {
    LendingVault vault;
    MockLendingPool poolA;
    MockLendingPool poolB;
    MockUSDC token;
    
    address constant CALLBACK_PROXY = address(0x123);
    address constant RVM_ID = address(0x456);
    address user1 = address(0x1111);
    address user2 = address(0x2222);
    
    event Deposited(address indexed user, uint256 amount, uint256 shares);
    event Withdrawn(address indexed user, uint256 shares, uint256 amount);
    event Rebalanced(bool direction, uint256 amount, uint256 rateA, uint256 rateB);

    function setUp() public {
        // Deploy mock token
        token = new MockUSDC();
        
        // Deploy mock pools
        poolA = new MockLendingPool("Pool Alpha");
        poolB = new MockLendingPool("Pool Beta");
        
        // Deploy vault
        vault = new LendingVault(
            address(token),
            CALLBACK_PROXY,
            RVM_ID,
            address(poolA),
            address(poolB)
        );
        
        // Mint tokens to users
        token.mintTo(user1, 10000 * 1e6); // 10,000 USDC
        token.mintTo(user2, 5000 * 1e6);  // 5,000 USDC
        
        // Approve vault to spend user tokens
        vm.prank(user1);
        token.approve(address(vault), type(uint256).max);
        
        vm.prank(user2);
        token.approve(address(vault), type(uint256).max);
    }

    // ============ Constructor Tests ============

    function testConstructor() public view {
        assertEq(address(vault.asset()), address(token));
        assertEq(vault.callbackProxy(), CALLBACK_PROXY);
        assertEq(vault.authorizedReactVM(), RVM_ID);
        
        (address pA, uint256 allocA, bool activeA) = vault.poolA();
        (address pB, uint256 allocB, bool activeB) = vault.poolB();
        
        assertEq(pA, address(poolA));
        assertEq(pB, address(poolB));
        assertEq(allocA, 0);
        assertEq(allocB, 0);
        assertTrue(activeA);
        assertTrue(activeB);
    }

    // ============ Deposit Tests ============

    function testDepositFirstUser() public {
        uint256 depositAmount = 1000 * 1e6;
        
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit Deposited(user1, depositAmount, depositAmount);
        
        uint256 shares = vault.deposit(depositAmount);
        
        // First deposit: 1:1 share ratio
        assertEq(shares, depositAmount);
        assertEq(vault.shares(user1), depositAmount);
        assertEq(vault.totalShares(), depositAmount);
        
        // Assets should be in pool A
        (,uint256 allocA,) = vault.poolA();
        assertEq(allocA, depositAmount);
    }

    function testDepositMultipleUsers() public {
        // User 1 deposits first
        vm.prank(user1);
        vault.deposit(1000 * 1e6);
        
        // User 2 deposits
        vm.prank(user2);
        uint256 shares = vault.deposit(500 * 1e6);
        
        // Shares should be calculated based on total assets
        // User 2 gets shares proportional to deposit
        // Note: shares may not be exactly 1:1 due to pool accounting
        assertGt(shares, 0);
        assertEq(vault.shares(user2), shares);
        assertEq(vault.totalShares(), 1000 * 1e6 + shares);
    }

    function testDepositZeroReverts() public {
        vm.prank(user1);
        vm.expectRevert(LendingVault.InvalidAmount.selector);
        vault.deposit(0);
    }

    // ============ Withdraw Tests ============

    function testWithdraw() public {
        // Deposit first
        vm.startPrank(user1);
        vault.deposit(1000 * 1e6);
        
        // Withdraw half
        uint256 balanceBefore = token.balanceOf(user1);
        
        vm.expectEmit(true, false, false, true);
        emit Withdrawn(user1, 500 * 1e6, 500 * 1e6);
        
        uint256 amount = vault.withdraw(500 * 1e6);
        vm.stopPrank();
        
        assertEq(amount, 500 * 1e6);
        assertEq(token.balanceOf(user1), balanceBefore + 500 * 1e6);
        assertEq(vault.shares(user1), 500 * 1e6);
    }

    function testWithdrawInsufficientSharesReverts() public {
        vm.startPrank(user1);
        vault.deposit(1000 * 1e6);
        
        vm.expectRevert(LendingVault.InsufficientShares.selector);
        vault.withdraw(2000 * 1e6); // More than deposited
        vm.stopPrank();
    }

    // ============ Rebalance Tests ============

    function testRebalanceAuthorized() public {
        // Deposit funds first
        vm.prank(user1);
        vault.deposit(1000 * 1e6);
        
        // Verify initial allocation
        (,uint256 allocABefore,) = vault.poolA();
        (,uint256 allocBBefore,) = vault.poolB();
        assertEq(allocABefore, 1000 * 1e6);
        assertEq(allocBBefore, 0);
        
        // Simulate callback from ReactVM (A -> B)
        vm.prank(CALLBACK_PROXY);
        vm.expectEmit(false, false, false, true);
        emit Rebalanced(true, 500 * 1e6, 300, 500);
        
        vault.rebalance(RVM_ID, true, 500 * 1e6, 300, 500);
        
        // Verify new allocation
        (,uint256 allocAAfter,) = vault.poolA();
        (,uint256 allocBAfter,) = vault.poolB();
        assertEq(allocAAfter, 500 * 1e6);
        assertEq(allocBAfter, 500 * 1e6);
    }

    function testRebalanceUnauthorizedCallerReverts() public {
        vm.prank(user1);
        vault.deposit(1000 * 1e6);
        
        // Try to call rebalance without being callback proxy
        vm.prank(user1);
        vm.expectRevert(LendingVault.Unauthorized.selector);
        vault.rebalance(RVM_ID, true, 500 * 1e6, 300, 500);
    }

    function testRebalanceUnauthorizedRVMReverts() public {
        vm.prank(user1);
        vault.deposit(1000 * 1e6);
        
        // Call from callback proxy but with wrong RVM ID
        vm.prank(CALLBACK_PROXY);
        vm.expectRevert("Unauthorized ReactVM");
        vault.rebalance(address(0x999), true, 500 * 1e6, 300, 500);
    }

    // ============ View Function Tests ============

    function testGetTotalAssets() public {
        vm.prank(user1);
        vault.deposit(1000 * 1e6);
        
        assertEq(vault.getTotalAssets(), 1000 * 1e6);
    }

    function testGetSharePrice() public {
        // Before any deposits
        assertEq(vault.getSharePrice(), 1e18);
        
        // After deposit
        vm.prank(user1);
        vault.deposit(1000 * 1e6);
        
        assertEq(vault.getSharePrice(), 1e18);
    }

    function testGetAllocations() public {
        vm.prank(user1);
        vault.deposit(1000 * 1e6);
        
        (uint256 allocA, uint256 allocB, uint256 idle) = vault.getAllocations();
        assertEq(allocA, 1000 * 1e6);
        assertEq(allocB, 0);
        assertEq(idle, 0);
    }

    // ============ Admin Function Tests ============

    function testSetRebalanceThreshold() public {
        vault.setRebalanceThreshold(500); // 5%
        assertEq(vault.rebalanceThreshold(), 500);
    }

    function testSetAuthorizedReactVM() public {
        address newRVM = address(0x789);
        vault.setAuthorizedReactVM(newRVM);
        assertEq(vault.authorizedReactVM(), newRVM);
    }
}
