// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Migration } from "../Migration.s.sol";
import { FloppyGambleDeploy, FloppyGamble } from "../contracts/FloppyGambleDeploy.s.sol";
import { IFloppyGamble } from "../../src/interfaces/IFloppyGamble.sol";
import { Contract } from "../utils/Contract.sol";

contract Migration__20241509_Upgrade_Gamble is Migration {
  FloppyGamble internal _gamble;

  function run() public {
    bytes memory callData = abi.encodeCall(IFloppyGamble.getBetsByStatus, (IFloppyGamble.BetStatus.Pending));
    _gamble = FloppyGamble(_upgradeProxy(Contract.FloppyGamble.key(), callData));
  }

  function _postCheck() internal override {
    (uint256[] memory betIds, IFloppyGamble.BetInfo[] memory bets) =
      _gamble.getBetsByStatus(IFloppyGamble.BetStatus.Pending);
    assertEq(betIds.length, 7);
    assertEq(bets.length, 7);
  }
}
