// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FloppyVaultTest } from "./FloppyVault.t.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IFloppyVault } from "@interfaces/IFloppyVault.sol";

contract FloppyVault_Withdraw_Test is FloppyVaultTest {
  function setUp() public override {
    super.setUp();
    vm.prank(_user1);
    _floppyVault.deposit(100 ether, _user1);
    vm.prank(_user2);
    _floppyVault.deposit(100 ether, _user2);
    vm.prank(testAdmin);
    _floppyVault.deposit(100 ether, testAdmin);
  }
  // Happy cases for withdraw() function.

  function testConcrete_Withdraw_90FLP_BurnRightAmountOfShare_And_EmitEvent() external callAs(_user1) {
    uint256 balance1 = _mockErc20.balanceOf(_user1);
    uint256 tokenAmount = 90 ether;
    uint256 totalSharesOwned = _floppyVault.balanceOf(_user1);
    uint256 idealSharesBurned = _floppyVault.convertToShares(tokenAmount);
    uint256 sharesBurned = _floppyVault.previewWithdraw(tokenAmount);

    console2.log("Total shares owned: ", totalSharesOwned / 1e21);
    console2.log("Ideal share burned: ", idealSharesBurned / 1e21);
    console2.log("Actual share burned: ", sharesBurned / 1e21);
    console2.log("Max withdraw: ", _floppyVault.maxWithdraw(_user1) / 1e18);

    _expectEmitWithdraw(_user1, _user1, _user1, tokenAmount, sharesBurned, 1);
    _floppyVault.withdraw(tokenAmount, _user1, _user1);

    assertEq(_floppyVault.balanceOf(_user1), totalSharesOwned - sharesBurned);
    assertEq(_mockErc20.balanceOf(_user1), balance1 + tokenAmount);

    console2.log("Share left: ", _floppyVault.balanceOf(_user1) / 1e21);
  }

  function testConcrete_Withdraw_50FLP_ForReceiver_BurnRightAmountOfShare_And_EmitEvent() public callAs(_user1) {
    uint256 initialBalanceUser1 = _floppyVault.balanceOf(_user1);
    uint256 initialBalanceUser2 = _mockErc20.balanceOf(_user2);
    uint256 withdrawAmount = 50 ether;
    uint256 sharesBurned = _floppyVault.previewWithdraw(withdrawAmount);

    _expectEmitWithdraw(_user1, _user1, _user2, withdrawAmount, sharesBurned, 1);
    _floppyVault.withdraw(withdrawAmount, _user2, _user1);

    assertEq(_floppyVault.balanceOf(_user1), initialBalanceUser1 - sharesBurned);
    assertEq(_mockErc20.balanceOf(_user2), initialBalanceUser2 + withdrawAmount);
  }

  function testConcrete_WithdrawTwoTimes_40FLP_Each_BurnRightAmountOfShare_And_EmitEvent() external callAs(_user1) {
    uint256 balance1 = _mockErc20.balanceOf(_user1);
    uint256 tokenAmount = 40 ether;
    uint256 totalSharesOwned1 = _floppyVault.balanceOf(_user1);
    uint256 sharesBurned1 = _floppyVault.previewWithdraw(tokenAmount);

    _expectEmitWithdraw(_user1, _user1, _user1, tokenAmount, sharesBurned1, 1);
    _floppyVault.withdraw(tokenAmount, _user1, _user1);

    assertEq(_floppyVault.balanceOf(_user1), totalSharesOwned1 - sharesBurned1);
    assertEq(_mockErc20.balanceOf(_user1), balance1 + tokenAmount);

    uint256 balance2 = _mockErc20.balanceOf(_user1);
    uint256 totalSharesOwned2 = _floppyVault.balanceOf(_user1);
    uint256 sharesBurned2 = _floppyVault.previewWithdraw(tokenAmount);

    _expectEmitWithdraw(_user1, _user1, _user1, tokenAmount, sharesBurned2, 1);
    _floppyVault.withdraw(tokenAmount, _user1, _user1);

    assertEq(_floppyVault.balanceOf(_user1), totalSharesOwned2 - sharesBurned2);
    assertEq(_mockErc20.balanceOf(_user1), balance2 + tokenAmount);
  }

  function testConcrete_Withdraw_A_1Wei_StillBurnShares() external callAs(_user1) {
    _expectEmitWithdraw(_user1, _user1, _user1, 1, _floppyVault.previewWithdraw(1), 1);
    _floppyVault.withdraw(1, _user1, _user1);
  }

  function testFuzz_Withdraw_For_Receiver(
    uint256 amount
  ) external callAs(_user1) {
    vm.assume(amount < _floppyVault.maxWithdraw(_user1) && amount > 0);

    _expectEmitWithdraw(_user1, _user1, _user2, amount, _floppyVault.previewWithdraw(amount), 1);
    _floppyVault.withdraw(amount, _user2, _user1);
  }

  function testFuzz_Withdraw_For_Myself(
    uint256 amount
  ) external callAs(_user1) {
    vm.assume(amount < _floppyVault.maxWithdraw(_user1) && amount > 0);
    _expectEmitWithdraw(_user1, _user1, _user1, amount, _floppyVault.previewWithdraw(amount), 1);
    _floppyVault.withdraw(amount, _user1, _user1);
  }

  // Unhappy cases for withdraw() function.
  function test_Revert_When_VaultIsPaused() external pause {
    vm.prank(_user1);
    vm.expectRevert(EnforcedPause.selector);
    _floppyVault.withdraw(100 ether, _user1, _user1);
  }

  function test_Revert_When_WithdrawExceedMaxWithdraw() external callAs(_user1) {
    vm.expectRevert(
      abi.encodeWithSelector(
        IFloppyVault.ExceededMaxWithdraw.selector, _user1, 100 ether, _floppyVault.maxWithdraw(_user1)
      )
    );
    _floppyVault.withdraw(100 ether, _user1, _user1);
  }

  function test_Revert_When_TokenAmountIsZero() external callAs(_user1) {
    vm.expectRevert(IFloppyVault.InvalidAmount.selector);
    _floppyVault.withdraw(0 ether, _user1, _user1);
  }
}
