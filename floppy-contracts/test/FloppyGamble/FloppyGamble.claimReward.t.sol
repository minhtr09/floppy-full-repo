// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FloppyGambleTest, IFloppyGamble } from "./FloppyGamble.t.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { StdStyle } from "forge-std/StdStyle.sol";

contract FloppyGamble_ClaimReward_Test is FloppyGambleTest {
  function testConcrete_ClaimReward_BronzeTierBet() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Bronze);
    address receiver = makeAddr("Receiver");
    uint256 balanceBefore = _asset.balanceOf(receiver);
    bytes memory sig = _signPermitStruct(betId, _user1, receiver, 100, 100 ether, _deadline);
    _gamble.resolveBet(betId, 100, _deadline, sig);
    _gamble.claimReward(betId);
    IFloppyGamble.BetInfo memory betInfo = _gamble.getBetInfoById(betId);
    assertEq(betInfo.claimed, true);
    assertEq(_asset.balanceOf(receiver), balanceBefore + _gamble.getReward(IFloppyGamble.BetTier.Bronze, 100 ether));
  }

  function testRevert_When_ClaimNonExistentBet() public {
    vm.expectRevert(IFloppyGamble.BetDoesNotExist.selector);
    _gamble.claimReward(0);
  }

  function testRevert_When_BetIsNotResolved() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Bronze);
    vm.expectRevert(
      abi.encodeWithSelector(
        IFloppyGamble.InvalidBetStatus.selector, IFloppyGamble.BetStatus.Pending, IFloppyGamble.BetStatus.Resolved
      )
    );
    _gamble.claimReward(betId);
  }

  function testRevert_When_BetIsNotWon() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Bronze);
    bytes memory sig = _signPermitStruct(betId, _user1, makeAddr("Receiver"), 0, 100 ether, _deadline);
    _gamble.resolveBet(betId, 0, _deadline, sig);

    vm.expectRevert(abi.encodeWithSelector(IFloppyGamble.BetLost.selector, betId));
    _gamble.claimReward(betId);
  }

  function testRevert_When_RewardAlreadyClaimed() public {
    testConcrete_ClaimReward_BronzeTierBet();
    vm.expectRevert(abi.encodeWithSelector(IFloppyGamble.RewardAlreadyClaimed.selector, 0));
    _gamble.claimReward(0);
  }
}
