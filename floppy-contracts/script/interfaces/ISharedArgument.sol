// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IGeneralConfig } from "@fdk/interfaces/IGeneralConfig.sol";
import { FloppyVault } from "@contracts/FloppyVault.sol";
import { FloppyGamble, IFloppyGamble } from "@contracts/FloppyGamble.sol";

interface ISharedArgument is IGeneralConfig {
  struct FloppyVaultParam {
    address admin;
    address token;
    uint256 taxPercent;
  }

  struct FLPParam {
    address owner;
  }

  struct FloppyGambleParam {
    address asset;
    address wallet;
    uint256 maxBetAmount;
    uint256 minBetAmount;
    address signer;
    uint256 penaltyForCanceledBet;
    // Points ranges for each bet tier
    // pointsRanges[0] -> Bronze
    // pointsRanges[1] -> Silver
    // pointsRanges[2] -> Gold
    // pointsRanges[3] -> Diamond
    IFloppyGamble.PointsRange[] pointsRanges;
    // Reward percentages for each bet tier
    // rewardPercentages[0] -> Bronze
    // rewardPercentages[1] -> Silver
    // rewardPercentages[2] -> Gold
    // rewardPercentages[3] -> Diamond
    uint256[] rewardPercentages;
  }

  struct SharedParameter {
    FloppyVaultParam floppyVault;
    FLPParam flp;
    FloppyGambleParam floppyGamble;
  }

  function sharedArguments() external view returns (SharedParameter memory param);
}
