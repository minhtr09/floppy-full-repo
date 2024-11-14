// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FloppyGambleTest, IFloppyGamble } from "./FloppyGamble.t.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { StdStyle } from "forge-std/StdStyle.sol";

contract FloppyGamble_ResolveBetAndClaimReward_Test is FloppyGambleTest {
  function testConcrete_ResolveBetAndClaimReward_A_ValidWinningBet() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Bronze);
    address receiver = makeAddr("Receiver");
    uint256 balanceBefore = _asset.balanceOf(receiver);
    bytes memory sig = _signPermitStruct(betId, _user1, receiver, 100, 100 ether, _deadline);
    _gamble.resolveBetAndClaimReward(betId, 100, _deadline, sig);

    IFloppyGamble.BetInfo memory betInfo = _gamble.getBetInfoById(betId);
    assertEq(betInfo.claimed, true);
    assertEq(betInfo.win, true);
    assertEq(betInfo.amount, 100 ether);
    assertEq(betInfo.reward, _gamble.getReward(IFloppyGamble.BetTier.Bronze, 100 ether));
    assertEq(uint8(betInfo.status), uint8(IFloppyGamble.BetStatus.Resolved));
    assertEq(_asset.balanceOf(receiver), balanceBefore + betInfo.reward);
  }
}
