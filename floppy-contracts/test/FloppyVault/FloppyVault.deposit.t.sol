// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FloppyVaultTest } from "./FloppyVault.t.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract FloppyVault_Deposit_Test is FloppyVaultTest {
  // Happy cases for deposit() function.
  function testConcrete_Deposit100FLP_GetRightAmountOfShares_And_EmitEvent() public callAs(testAdmin) {
    uint256 sharesWillGet = _calShares({ tokenAmount: 100 ether, withTax: false });

    _expectEmitDeposit(testAdmin, testAdmin, 100 ether, sharesWillGet, 1);
    uint256 actualSharesWillGet = _floppyVault.deposit(100 ether, testAdmin);

    assertEq(sharesWillGet, actualSharesWillGet);
    assertEq(_floppyVault.balanceOf(testAdmin), sharesWillGet);
  }

  function testConcrete_Deposit100FLP_ForReceiver_GetRightAmountOfShares_And_EmitEvent() public callAs(testAdmin) {
    uint256 sharesWillGet = _calShares({ tokenAmount: 100 ether, withTax: false });

    _expectEmitDeposit(testAdmin, _user1, 100 ether, sharesWillGet, 1);
    uint256 actualSharesWillGet = _floppyVault.deposit(100 ether, _user1);

    assertEq(sharesWillGet, actualSharesWillGet);
    assertEq(_floppyVault.balanceOf(_user1), sharesWillGet);
  }

  function testConcrete_DepositTwoTimes_With_100FLP_GetRightAmountOfShares_EmitEvent_And_VerifyCumulativEffects()
    public
    callAs(testAdmin)
  {
    uint256 amount = 100 ether;
    uint256 sharesWillGet = _calShares({ tokenAmount: amount, withTax: false });

    _expectEmitDeposit(testAdmin, testAdmin, amount, sharesWillGet, 1);
    uint256 shares1 = _floppyVault.deposit(amount, testAdmin);
    _expectEmitDeposit(testAdmin, testAdmin, amount, sharesWillGet, 1);
    uint256 shares2 = _floppyVault.deposit(amount, testAdmin);

    assertEq(_floppyVault.balanceOf(testAdmin), shares1 + shares2);
    assertEq(_mockErc20.balanceOf(address(_floppyVault)), amount * 2);
  }

  function testConcrete_DepositAMinimumAmount_ToGetOneShare_And_EmitEvent() public callAs(testAdmin) {
    _mockErc20.transfer(address(_floppyVault), 100 ether);
    uint256 amount = _floppyVault.previewMint(1) + 2;
    uint256 sharesWillGet = 1;

    console2.log("Vault balance: ", (_mockErc20.balanceOf(address(_floppyVault)) / 1e18));
    console2.log("Total share: ", (_floppyVault.totalSupply()) / 1e18);
    console2.log("Shares will get: ", sharesWillGet);

    _expectEmitDeposit(testAdmin, testAdmin, amount, sharesWillGet, 1);
    uint256 actualSharesWillGet = _floppyVault.deposit(amount, testAdmin);

    assertEq(sharesWillGet, actualSharesWillGet);
    assertEq(_floppyVault.balanceOf(testAdmin), sharesWillGet);
  }

  function testConcrete_DepositAMaximumAmount_ToGetZeroShare_And_EmitEvent() public callAs(testAdmin) {
    _mockErc20.transfer(address(_floppyVault), 100 ether);
    uint256 amount = 100000000000000000;
    uint256 sharesWillGet = 0;

    console2.log("Vault balance: ", (_mockErc20.balanceOf(address(_floppyVault)) / 1e18));
    console2.log("Total share: ", (_floppyVault.totalSupply()) / 1e18);
    console2.log("Shares will get: ", sharesWillGet);

    _expectEmitDeposit(testAdmin, testAdmin, amount, sharesWillGet, 1);
    uint256 actualSharesWillGet = _floppyVault.deposit(amount, testAdmin);

    assertEq(sharesWillGet, actualSharesWillGet);
    assertEq(_floppyVault.balanceOf(testAdmin), sharesWillGet);
  }

  function test_DepositAVerySmallAmountOfToken_GetZeroAmountOfShares_And_EmitEvent() public callAs(testAdmin) {
    _mockErc20.transfer(address(_floppyVault), 100 ether);
    uint256 sharesWillGet = 0;

    console2.log("Shares will get: ", sharesWillGet);

    _expectEmitDeposit(testAdmin, testAdmin, 1, sharesWillGet, 1);
    uint256 actualSharesWillGet = _floppyVault.deposit(1, testAdmin);

    assertEq(sharesWillGet, actualSharesWillGet);
    assertEq(_floppyVault.balanceOf(testAdmin), sharesWillGet);
  }

  // Unhappy cases for deposit() function.
  function test_Revert_WhenVaultIsPaused() external pause {
    vm.expectRevert(EnforcedPause.selector);
    _floppyVault.deposit(100 ether, _user1);
  }

  function test_Revert_WhenDeposit_Invalid_Amount() external callAs(_user1) {
    vm.expectRevert(InvalidAmount.selector);
    _floppyVault.deposit(0 ether, _user1);
  }

  function test_Revert_WhenDeposit_MoreThanBalance() external callAs(_user1) {
    uint256 amount = _mockErc20.balanceOf(_user1) + 1;
    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientBalance.selector, _user1, _mockErc20.balanceOf(_user1), amount
      )
    );
    _floppyVault.deposit(amount, _user1);
  }
}
