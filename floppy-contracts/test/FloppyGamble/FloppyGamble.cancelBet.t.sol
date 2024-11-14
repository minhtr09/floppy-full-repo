// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FloppyGambleTest, IFloppyGamble } from "./FloppyGamble.t.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { StdStyle } from "forge-std/StdStyle.sol";

contract FloppyGamble_CancelBet_Test is FloppyGambleTest {
  // Happy cases for cancelBet() function.
  function testConcrete_Cancel_A_ValidBet() public callAs(_user1) {
    uint256 betId = _gamble.placeBet(_user2, 10 ether, IFloppyGamble.BetTier.Bronze);
    uint256 penalty = _gamble.getPenaltyForCanceledBet();
    _cheatTime();
    _gamble.cancelBet(betId);
    assertEq(uint8(_gamble.getBetInfoById(betId).status), uint8(IFloppyGamble.BetStatus.Canceled));
  }

  function testConcrete_CancelBet_ShouldTransferPenaltyToWallet() public callAs(_user1) {
    uint256 betAmount = 10 ether;
    uint256 betId = _gamble.placeBet(_user2, betAmount, IFloppyGamble.BetTier.Bronze);
    uint256 penaltyPercentage = _gamble.getPenaltyForCanceledBet();
    uint256 expectedPenalty = betAmount * penaltyPercentage / _gamble.MAX_PERCENTAGE();

    uint256 walletBalanceBefore = _asset.balanceOf(_wallet);
    _cheatTime();
    _gamble.cancelBet(betId);

    uint256 walletBalanceAfter = _asset.balanceOf(_wallet);
    assertEq(
      walletBalanceAfter - walletBalanceBefore, expectedPenalty, "Penalty amount not transferred to wallet correctly"
    );
  }

  function testConcrete_CancelBet_ShouldRefundRemainingAmountToRequester() public callAs(_user1) {
    uint256 betAmount = 10 ether;
    uint256 betId = _gamble.placeBet(_user2, betAmount, IFloppyGamble.BetTier.Bronze);
    uint256 penaltyPercentage = _gamble.getPenaltyForCanceledBet();
    uint256 expectedPenalty = betAmount * penaltyPercentage / _gamble.MAX_PERCENTAGE();
    uint256 expectedRefund = betAmount - expectedPenalty;

    uint256 requesterBalanceBefore = _asset.balanceOf(_user1);
    _cheatTime();
    _gamble.cancelBet(betId);

    uint256 requesterBalanceAfter = _asset.balanceOf(_user1);
    assertEq(
      requesterBalanceAfter - requesterBalanceBefore,
      expectedRefund,
      "Remaining amount not refunded to requester correctly"
    );
  }

  function testConcrete_CancelBet_ShouldEmitBetCanceledEvent() public callAs(_user1) {
    uint256 betId = _gamble.placeBet(_user2, 10 ether, IFloppyGamble.BetTier.Bronze);
    _cheatTime();
    vm.expectEmit(true, true, false, true);
    emit IFloppyGamble.BetCanceled(_user1, betId);
    _gamble.cancelBet(betId);
  }

  // Unhappy cases for cancelBet() function.

  function testRevert_CancelBet_ShouldRevert_WhenBetDoesNotExist() public callAs(_user1) {
    vm.expectRevert(IFloppyGamble.BetDoesNotExist.selector);
    _gamble.cancelBet(0);
  }

  function testRevert_CancelBet_ShouldRevert_WhenCallerIsNotRequester() public {
    vm.prank(_user1);
    uint256 betId = _gamble.placeBet(_user2, 10 ether, IFloppyGamble.BetTier.Bronze);

    vm.prank(_user2);
    vm.expectRevert(IFloppyGamble.ErrNotRequester.selector);
    _gamble.cancelBet(betId);
  }
}
