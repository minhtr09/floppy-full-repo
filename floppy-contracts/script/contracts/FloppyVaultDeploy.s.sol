// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISharedArgument, Migration } from "@script/Migration.s.sol";
import { Contract } from "@script/utils/Contract.sol";
import { FloppyVault } from "@contracts/FloppyVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseGeneralConfig } from "@fdk/BaseGeneralConfig.sol";

contract FloppyVaultDeploy is Migration {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    ISharedArgument.FloppyVaultParam memory param = config.sharedArguments().floppyVault;
    args = abi.encodeCall(FloppyVault.initialize, (param.admin, IERC20(param.token), param.taxPercent));
  }

  function run() public virtual returns (FloppyVault) {
    FloppyVault deployed = FloppyVault(_deployProxy(Contract.FloppyVault.key()));
    _checkAdmin(address(deployed));
    return deployed;
  }
}
