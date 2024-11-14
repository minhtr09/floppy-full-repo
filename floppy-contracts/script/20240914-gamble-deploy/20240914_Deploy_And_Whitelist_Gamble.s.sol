// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Migration } from "../Migration.s.sol";
import { FloppyGambleDeploy, FloppyGamble } from "../contracts/FloppyGambleDeploy.s.sol";
import { FLPDeploy, FLP, IERC20 } from "../contracts/FLPDeploy.s.sol";
import { Contract } from "../utils/Contract.sol";

contract Migration__20240914_Deploy_And_Whitelist_Gamble is Migration {
  FLP internal _flpToken;
  FloppyGamble internal _gamble;
  address internal _defaultAdmin = 0x62aE17Ea20Ac44915B57Fa645Ce8c0f31cBD873f;

  function run() public {
    _flpToken = FLP(config.getAddressFromCurrentNetwork(Contract.FLP.key()));
    _gamble = new FloppyGambleDeploy().run();
    vm.startBroadcast(_defaultAdmin);
    _flpToken.whitelist(address(_gamble));
    vm.stopBroadcast();
  }

  function _postCheck() internal override {
    assertEq(_gamble.getAsset(), address(_flpToken));
    assertTrue(_flpToken.whitelisted(address(_gamble)));

    vm.prank(address(_gamble));
    _flpToken.transferFrom(address(_defaultAdmin), address(_gamble), 100 ether);
  }
}
