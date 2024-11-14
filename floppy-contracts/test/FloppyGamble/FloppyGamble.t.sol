// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FloppyGamble, IFloppyGamble, IERC20 } from "@contracts/FloppyGamble.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { StdStyle } from "forge-std/StdStyle.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { FLPDeploy, FLP } from "@script/contracts/FLPDeploy.s.sol";

contract FloppyGambleTest is Test {
  using StdStyle for *;

  FloppyGamble internal _gamble;
  FLP internal _flpToken = new FLPDeploy().run();
  address internal _tokenOwner = 0x62aE17Ea20Ac44915B57Fa645Ce8c0f31cBD873f;
  address internal _proxyAdmin = makeAddr("Proxy Admin");
  address internal _user1 = makeAddr("User 1");
  address internal _user2 = makeAddr("User 2");
  address internal _signer;
  uint256 internal _signerPk;
  address internal _wallet;
  uint256 internal _penaltyForCanceledBet;
  uint256 internal _maxBetAmount;
  uint256 internal _minBetAmount;
  uint256 internal _deadline = block.timestamp + 1 days;
  IERC20 internal _asset;

  modifier callAs(
    address caller
  ) {
    vm.startPrank(caller);
    _;
    vm.stopPrank();
  }

  function setUp() public {
    _wallet = _tokenOwner;
    (_signer, _signerPk) = makeAddrAndKey("Signer");
    _penaltyForCanceledBet = 10_000;
    _maxBetAmount = 1 ether;
    _minBetAmount = 1000 ether;

    IFloppyGamble.PointsRange[] memory pointsRange = new IFloppyGamble.PointsRange[](4);
    pointsRange[0] = IFloppyGamble.PointsRange({ minPoints: 50, maxPoints: 100 });
    pointsRange[1] = IFloppyGamble.PointsRange({ minPoints: 101, maxPoints: 200 });
    pointsRange[2] = IFloppyGamble.PointsRange({ minPoints: 201, maxPoints: 400 });
    pointsRange[3] = IFloppyGamble.PointsRange({ minPoints: 401, maxPoints: type(uint256).max });

    uint256[] memory rewardPercentage = new uint256[](4);
    rewardPercentage[0] = 70_000;
    rewardPercentage[1] = 80_000;
    rewardPercentage[2] = 90_000;
    rewardPercentage[3] = 100_000;

    bytes memory data = abi.encodeCall(
      FloppyGamble.initialize,
      (
        IERC20(address(_flpToken)),
        _wallet,
        _minBetAmount,
        _maxBetAmount,
        _signer,
        _penaltyForCanceledBet,
        pointsRange,
        rewardPercentage
      )
    );
    address logic = address(new FloppyGamble());

    address proxy = address(new TransparentUpgradeableProxy(logic, _proxyAdmin, data));
    vm.label(proxy, "FloppyGamble");
    _gamble = FloppyGamble(proxy);
    _asset = IERC20(_gamble.getAsset());
    vm.startPrank(_tokenOwner);
    _flpToken.transfer(_user1, 10000 ether);
    _flpToken.transfer(_user2, 10000 ether);
    _flpToken.whitelist(address(_gamble));
    vm.stopPrank();
  }

  function testConcrete_GetAllBets() public {
    uint256 betId1 = _placeBet(IFloppyGamble.BetTier.Bronze);
    uint256 betId2 = _placeBet(IFloppyGamble.BetTier.Silver);
    uint256 betId3 = _placeBet(IFloppyGamble.BetTier.Gold);
    uint256 betId4 = _placeBet(IFloppyGamble.BetTier.Diamond);

    (uint256[] memory betIds, IFloppyGamble.BetInfo[] memory bets) = _gamble.getAllBets();
    assertEq(betIds.length, 4);
    assertEq(bets.length, 4);
    assertEq(betIds[0], betId1);
    assertEq(betIds[1], betId2);
    assertEq(betIds[2], betId3);
    assertEq(betIds[3], betId4);
  }

  function testConcrete_GetBetByStatus() public {
    uint256 betId1 = _placeBet(IFloppyGamble.BetTier.Bronze);
    uint256 betId2 = _placeBet(IFloppyGamble.BetTier.Silver);
    uint256 betId3 = _placeBet(IFloppyGamble.BetTier.Gold);
    uint256 betId4 = _placeBet(IFloppyGamble.BetTier.Diamond);

    (uint256[] memory betIds, IFloppyGamble.BetInfo[] memory bets) =
      _gamble.getBetsByStatus(IFloppyGamble.BetStatus.Pending);
    assertEq(betIds.length, 4);
    assertEq(bets.length, 4);
    assertEq(betIds[0], betId1);
    assertEq(betIds[1], betId2);
    assertEq(betIds[2], betId3);
    assertEq(betIds[3], betId4);
    assertEq(uint8(bets[0].status), uint8(IFloppyGamble.BetStatus.Pending));
    assertEq(uint8(bets[1].status), uint8(IFloppyGamble.BetStatus.Pending));
    assertEq(uint8(bets[2].status), uint8(IFloppyGamble.BetStatus.Pending));
    assertEq(uint8(bets[3].status), uint8(IFloppyGamble.BetStatus.Pending));
  }

  function _checkBetInfoChanged(IFloppyGamble.BetInfo memory expectedBetInfo, uint256 betId) internal {
    IFloppyGamble.BetInfo memory actualBetInfo = _gamble.getBetInfoById(betId);
    assertEq(expectedBetInfo.amount, actualBetInfo.amount);
    assertEq(uint8(expectedBetInfo.tier), uint8(actualBetInfo.tier));
    assertEq(uint8(expectedBetInfo.status), uint8(actualBetInfo.status));
    assertEq(expectedBetInfo.requester, actualBetInfo.requester);
    assertEq(expectedBetInfo.receiver, actualBetInfo.receiver);
    assertEq(expectedBetInfo.timestamp, actualBetInfo.timestamp);
  }

  function _cheatTime() internal {
    vm.warp(block.timestamp + 2 hours);
  }

  function _signPermitStruct(
    uint256 betId,
    address requester,
    address receiver,
    uint256 points,
    uint256 betAmount,
    uint256 deadline
  ) internal view returns (bytes memory) {
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      _signerPk,
      MessageHashUtils.toTypedDataHash(
        _gamble.DOMAIN_SEPARATOR(),
        keccak256(abi.encode(_gamble.PERMIT_TYPEHASH(), betId, requester, receiver, points, betAmount, deadline))
      )
    );
    return abi.encodePacked(r, s, v);
  }

  function _placeBet(
    IFloppyGamble.BetTier tier
  ) internal returns (uint256 betId) {
    vm.prank(_user1);
    betId = _gamble.placeBet(makeAddr("Receiver"), 100 ether, tier);
  }
}
