// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Migration } from "../Migration.s.sol";
import { FloppyVaultDeploy, FloppyVault } from "../contracts/FloppyVaultDeploy.s.sol";
import { FLPDeploy, FLP, IERC20 } from "../contracts/FLPDeploy.s.sol";

contract Migration__20240910_Deploy_FLP_Vault is Migration {
  FLP internal _flpToken;
  FloppyVault internal _vault;
  address internal _defaultAdmin = 0x62aE17Ea20Ac44915B57Fa645Ce8c0f31cBD873f;

  function run() public {
    _flpToken = new FLPDeploy().run();
    _vault = new FloppyVaultDeploy().run();
    vm.startBroadcast(_defaultAdmin);
    _flpToken.whitelist(address(_vault));
    _vault.setAsset(IERC20(_flpToken));
    vm.stopBroadcast();
  }

  function _postCheck() internal override {
    assertEq(_vault.asset(), address(_flpToken));
    assertTrue(_flpToken.whitelisted(address(_vault)));

    vm.prank(address(_vault));
    _flpToken.transferFrom(address(_defaultAdmin), address(_vault), 1e18);
  }
}
