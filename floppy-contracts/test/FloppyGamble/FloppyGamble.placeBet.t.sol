// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FloppyGambleTest, IFloppyGamble } from "./FloppyGamble.t.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { StdStyle } from "forge-std/StdStyle.sol";

contract FloppyGamble_PlaceBet_Test is FloppyGambleTest {
  // Happy cases for placeBet() function.
  function testConcrete_PlaceBet_10FLP_Should_EmitBetPlacedEvent() public callAs(_user1) {
    vm.expectEmit(true, false, false, true);
    emit IFloppyGamble.BetPlaced(_user1, 0);
    _gamble.placeBet(_user1, 100 ether, IFloppyGamble.BetTier.Bronze);
    _checkBetInfoChanged(
      IFloppyGamble.BetInfo({
        requester: _user1,
        receiver: _user1,
        amount: 100 ether,
        tier: IFloppyGamble.BetTier.Bronze,
        status: IFloppyGamble.BetStatus.Pending,
        points: 0,
        reward: 0,
        timestamp: block.timestamp,
        win: false,
        claimed: false
      }),
      0
    );
  }

  // Unhappy cases for placeBet() function.
  function testRevert_PlaceBet_ShouldRevert_WhenAmountExceedsMaxBetAmount() public callAs(_user1) {
    uint256 maxBetAmount = _gamble.getMaxBetAmount();
    vm.expectRevert(abi.encodeWithSelector(IFloppyGamble.InvalidBetAmount.selector));
    _gamble.placeBet(_user1, maxBetAmount + 1, IFloppyGamble.BetTier.Bronze);
  }

  function testRevert_PlaceBet_ShouldRevert_WhenAmountBelowMinBetAmount() public callAs(_user1) {
    uint256 minBetAmount = _gamble.getMinBetAmount();
    vm.expectRevert(abi.encodeWithSelector(IFloppyGamble.InvalidBetAmount.selector));
    _gamble.placeBet(_user1, minBetAmount - 1, IFloppyGamble.BetTier.Bronze);
  }

  function testRevert_PlaceBet_ShouldRevert_WhenTierIsUnknown() public callAs(_user1) {
    vm.expectRevert(abi.encodeWithSelector(IFloppyGamble.InvalidBetTier.selector));
    _gamble.placeBet(_user1, 100 ether, IFloppyGamble.BetTier.Unknown);
  }

  function testRevert_PlaceBet_ShouldRevert_WhenReceiverIsZeroAddress() public callAs(_user1) {
    vm.expectRevert(abi.encodeWithSelector(IFloppyGamble.NullAddress.selector));
    _gamble.placeBet(address(0), 100 ether, IFloppyGamble.BetTier.Bronze);
  }
}
