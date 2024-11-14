// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISharedArgument, Migration } from "@script/Migration.s.sol";
import { Contract } from "@script/utils/Contract.sol";
import { FLP } from "@contracts/token/FLP.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DefaultNetwork } from "@fdk/utils/DefaultNetwork.sol";

contract FLPDeploy is Migration {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    ISharedArgument.FLPParam memory param = config.sharedArguments().flp;
    args = abi.encodeCall(FLP.initialize, (param.owner));
  }

  function run() public virtual returns (FLP) {
    FLP deployed = FLP(_deployProxy(Contract.FLP.key()));
    _checkAdmin(address(deployed));

    return deployed;
  }
}
