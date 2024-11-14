// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISharedArgument, Migration } from "@script/Migration.s.sol";
import { Contract } from "@script/utils/Contract.sol";
import { FloppyGamble } from "@contracts/FloppyGamble.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseGeneralConfig } from "@fdk/BaseGeneralConfig.sol";

contract FloppyGambleDeploy is Migration {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    ISharedArgument.FloppyGambleParam memory param = config.sharedArguments().floppyGamble;
    args = abi.encodeCall(
      FloppyGamble.initialize,
      (
        IERC20(config.getAddressFromCurrentNetwork(Contract.FLP.key())),
        param.wallet,
        param.maxBetAmount,
        param.minBetAmount,
        param.signer,
        param.penaltyForCanceledBet,
        param.pointsRanges,
        param.rewardPercentages
      )
    );
  }

  function run() public virtual returns (FloppyGamble) {
    FloppyGamble deployed = FloppyGamble(_deployProxy(Contract.FloppyGamble.key()));
    _checkAdmin(address(deployed));
    return deployed;
  }
}
