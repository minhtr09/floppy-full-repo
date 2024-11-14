// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FloppyGambleTest, IFloppyGamble } from "./FloppyGamble.t.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { StdStyle } from "forge-std/StdStyle.sol";

contract FloppyGamble_ResolveBet_Test is FloppyGambleTest {
  function testConcrete_ResolveValidWinning_BronzeTierBet() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Bronze);
    bytes memory sig = _signPermitStruct(betId, _user1, makeAddr("Receiver"), 50, 100 ether, _deadline);
    vm.expectEmit(true, false, false, true);
    emit IFloppyGamble.BetResolved(betId, true);
    _gamble.resolveBet(betId, 50, _deadline, sig);

    IFloppyGamble.BetInfo memory betInfo = _gamble.getBetInfoById(betId);
    assertEq(betInfo.points, 50);
    assertEq(uint8(betInfo.tier), uint8(IFloppyGamble.BetTier.Bronze));
    assertEq(uint8(betInfo.status), uint8(IFloppyGamble.BetStatus.Resolved));
    assertEq(betInfo.win, true);
    assertEq(betInfo.reward, _gamble.getReward(IFloppyGamble.BetTier.Bronze, 100 ether));
  }

  function testConcrete_ResolveValidWinning_SilverTierBet() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Silver);
    bytes memory sig = _signPermitStruct(betId, _user1, makeAddr("Receiver"), 101, 100 ether, _deadline);
    vm.expectEmit(true, false, false, true);
    emit IFloppyGamble.BetResolved(betId, true);
    _gamble.resolveBet(betId, 101, _deadline, sig);

    IFloppyGamble.BetInfo memory betInfo = _gamble.getBetInfoById(betId);
    assertEq(uint8(betInfo.tier), uint8(IFloppyGamble.BetTier.Silver));
    assertEq(betInfo.points, 101);
    assertEq(uint8(betInfo.status), uint8(IFloppyGamble.BetStatus.Resolved));
    assertEq(betInfo.win, true);
    assertEq(betInfo.reward, _gamble.getReward(IFloppyGamble.BetTier.Silver, 100 ether));
  }

  function testConcrete_ResolveValidWinning_GoldTierBet() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Gold);
    bytes memory sig = _signPermitStruct(betId, _user1, makeAddr("Receiver"), 201, 100 ether, _deadline);
    vm.expectEmit(true, false, false, true);
    emit IFloppyGamble.BetResolved(betId, true);
    _gamble.resolveBet(betId, 201, _deadline, sig);

    IFloppyGamble.BetInfo memory betInfo = _gamble.getBetInfoById(betId);
    assertEq(uint8(betInfo.tier), uint8(IFloppyGamble.BetTier.Gold));
    assertEq(betInfo.points, 201);
    assertEq(uint8(betInfo.status), uint8(IFloppyGamble.BetStatus.Resolved));
    assertEq(betInfo.win, true);
    assertEq(betInfo.reward, _gamble.getReward(IFloppyGamble.BetTier.Gold, 100 ether));
  }

  function testConcrete_ResolveValidWinning_DiamondTierBet() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Diamond);
    bytes memory sig = _signPermitStruct(betId, _user1, makeAddr("Receiver"), 401, 100 ether, _deadline);
    vm.expectEmit(true, false, false, true);
    emit IFloppyGamble.BetResolved(betId, true);
    _gamble.resolveBet(betId, 401, _deadline, sig);

    IFloppyGamble.BetInfo memory betInfo = _gamble.getBetInfoById(betId);
    assertEq(uint8(betInfo.tier), uint8(IFloppyGamble.BetTier.Diamond));
    assertEq(betInfo.points, 401);
    assertEq(uint8(betInfo.status), uint8(IFloppyGamble.BetStatus.Resolved));
    assertEq(betInfo.win, true);
    assertEq(betInfo.reward, _gamble.getReward(IFloppyGamble.BetTier.Diamond, 100 ether));
  }

  function testConcrete_ResolveValidLosing_BronzeTierBet() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Bronze);
    bytes memory sig = _signPermitStruct(betId, _user1, makeAddr("Receiver"), 40, 100 ether, _deadline);
    vm.expectEmit(true, false, false, true);
    emit IFloppyGamble.BetResolved(betId, false);
    _gamble.resolveBet(betId, 40, _deadline, sig);

    IFloppyGamble.BetInfo memory betInfo = _gamble.getBetInfoById(betId);
    assertEq(uint8(betInfo.tier), uint8(IFloppyGamble.BetTier.Bronze));
    assertEq(betInfo.points, 40);
    assertEq(uint8(betInfo.status), uint8(IFloppyGamble.BetStatus.Resolved));
    assertEq(betInfo.win, false);
    assertEq(betInfo.reward, 0);
  }

  function testConcrete_ResolveValidLosing_SilverTierBet() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Silver);
    bytes memory sig = _signPermitStruct(betId, _user1, makeAddr("Receiver"), 0, 100 ether, _deadline);
    vm.expectEmit(true, false, false, true);
    emit IFloppyGamble.BetResolved(betId, false);
    _gamble.resolveBet(betId, 0, _deadline, sig);

    IFloppyGamble.BetInfo memory betInfo = _gamble.getBetInfoById(betId);
    assertEq(uint8(betInfo.tier), uint8(IFloppyGamble.BetTier.Silver));
    assertEq(betInfo.points, 0);
    assertEq(uint8(betInfo.status), uint8(IFloppyGamble.BetStatus.Resolved));
    assertEq(betInfo.win, false);
    assertEq(betInfo.reward, 0);
  }

  function testConcrete_ResolveValidLosing_GoldTierBet() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Gold);
    bytes memory sig = _signPermitStruct(betId, _user1, makeAddr("Receiver"), 0, 100 ether, _deadline);
    vm.expectEmit(true, false, false, true);
    emit IFloppyGamble.BetResolved(betId, false);
    _gamble.resolveBet(betId, 0, _deadline, sig);

    IFloppyGamble.BetInfo memory betInfo = _gamble.getBetInfoById(betId);
    assertEq(uint8(betInfo.tier), uint8(IFloppyGamble.BetTier.Gold));
    assertEq(betInfo.points, 0);
    assertEq(uint8(betInfo.status), uint8(IFloppyGamble.BetStatus.Resolved));
    assertEq(betInfo.win, false);
    assertEq(betInfo.reward, 0);
  }

  function testConcrete_ResolveValidLosing_DiamondTierBet() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Diamond);
    bytes memory sig = _signPermitStruct(betId, _user1, makeAddr("Receiver"), 0, 100 ether, _deadline);
    vm.expectEmit(true, false, false, true);
    emit IFloppyGamble.BetResolved(betId, false);
    _gamble.resolveBet(betId, 0, _deadline, sig);

    IFloppyGamble.BetInfo memory betInfo = _gamble.getBetInfoById(betId);
    assertEq(uint8(betInfo.tier), uint8(IFloppyGamble.BetTier.Diamond));
    assertEq(betInfo.points, 0);
    assertEq(uint8(betInfo.status), uint8(IFloppyGamble.BetStatus.Resolved));
    assertEq(betInfo.win, false);
    assertEq(betInfo.reward, 0);
  }

  function testRevert_CannotResolve_NonExistentBet() public {
    vm.expectRevert(IFloppyGamble.BetDoesNotExist.selector);
    _gamble.resolveBet(1, 100, block.timestamp + 100, "0x");
  }

  function testRevert_BetIsNotPending() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Bronze);
    vm.warp(block.timestamp + 2 hours);
    vm.prank(_user1);
    _gamble.cancelBet(betId);

    vm.expectRevert(
      abi.encodeWithSelector(
        IFloppyGamble.InvalidBetStatus.selector, IFloppyGamble.BetStatus.Canceled, IFloppyGamble.BetStatus.Pending
      )
    );
    _gamble.resolveBet(betId, 100, block.timestamp + 100, "0x");
  }

  function testRevert_SignatureExpired() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Bronze);
    uint256 deadline = block.timestamp + 2 hours;
    vm.warp(deadline + 1);
    vm.expectRevert(IFloppyGamble.SignatureExpired.selector);
    _gamble.resolveBet(betId, 100, deadline, "0x");
  }

  function testRevert_InvalidSignature() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Bronze);
    bytes memory sig = _signPermitStruct(betId, _user1, makeAddr("Receiver"), 0, 100 ether, _deadline);
    vm.expectRevert(IFloppyGamble.InvalidSignature.selector);
    _gamble.resolveBet(betId, 100, _deadline, sig);
  }

  function testRevert_CouldNotReplaySignature() public {
    uint256 betId = _placeBet(IFloppyGamble.BetTier.Bronze);
    bytes memory sig = _signPermitStruct(betId, _user1, makeAddr("Receiver"), 200, 100 ether, _deadline);
    _gamble.resolveBet(betId, 200, _deadline, sig);

    vm.expectRevert(
      abi.encodeWithSelector(
        IFloppyGamble.InvalidBetStatus.selector, IFloppyGamble.BetStatus.Resolved, IFloppyGamble.BetStatus.Pending
      )
    );
    _gamble.resolveBet(betId, 200, _deadline, sig);
  }
}
