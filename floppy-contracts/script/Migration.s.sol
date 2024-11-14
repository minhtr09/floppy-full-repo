// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseMigration } from "@fdk/BaseMigration.s.sol";
import { DefaultNetwork } from "@fdk/utils/DefaultNetwork.sol";
import { GeneralConfig } from "./GeneralConfig.sol";
import "./interfaces/ISharedArgument.sol";
import { LibProxy } from "@fdk/libraries/LibProxy.sol";
import { FloppyGamble, IFloppyGamble } from "@contracts/FloppyGamble.sol";

abstract contract Migration is BaseMigration {
  ISharedArgument public constant config = ISharedArgument(address(CONFIG));

  function _configByteCode() internal virtual override returns (bytes memory) {
    return abi.encodePacked(type(GeneralConfig).creationCode);
  }

  function _sharedArguments() internal virtual override returns (bytes memory rawArgs) {
    ISharedArgument.SharedParameter memory param;

    if (network() == DefaultNetwork.RoninTestnet.key() || network() == DefaultNetwork.LocalHost.key()) {
      address defaultAdmin = 0x62aE17Ea20Ac44915B57Fa645Ce8c0f31cBD873f;
      address signer = 0x74FE5f04CCBe9C0DbCd0039cfb8d7212B2E6e452;
      address tempErc20Token = 0x7DCdfe41708fdB651bAAFD2A392A1eCB808A25FE;
      address proxyAdminOwner = 0x02eB3F2A2779A023ff5c700eddAc5620806fcf27;
      vm.label(defaultAdmin, "Default Admin");
      vm.label(tempErc20Token, "Temp Erc20 Token");

      // FloppyVault
      param.floppyVault.admin = defaultAdmin;
      param.floppyVault.token = tempErc20Token;
      param.floppyVault.taxPercent = 5_000;
      // FLP
      param.flp.owner = defaultAdmin;
      // FloppyGamble
      param.floppyGamble.asset = tempErc20Token;
      param.floppyGamble.wallet = defaultAdmin;
      param.floppyGamble.maxBetAmount = 1 ether;
      param.floppyGamble.minBetAmount = 1000 ether;
      param.floppyGamble.signer = signer;
      param.floppyGamble.penaltyForCanceledBet = 10_000;
      param.floppyGamble.pointsRanges = new IFloppyGamble.PointsRange[](4);
      param.floppyGamble.pointsRanges[0] = IFloppyGamble.PointsRange({ minPoints: 50, maxPoints: 100 });
      param.floppyGamble.pointsRanges[1] = IFloppyGamble.PointsRange({ minPoints: 101, maxPoints: 200 });
      param.floppyGamble.pointsRanges[2] = IFloppyGamble.PointsRange({ minPoints: 201, maxPoints: 400 });
      param.floppyGamble.pointsRanges[3] = IFloppyGamble.PointsRange({ minPoints: 401, maxPoints: type(uint256).max });
      param.floppyGamble.rewardPercentages = new uint256[](4);
      param.floppyGamble.rewardPercentages[0] = 30_000;
      param.floppyGamble.rewardPercentages[1] = 50_000;
      param.floppyGamble.rewardPercentages[2] = 70_000;
      param.floppyGamble.rewardPercentages[3] = 100_000;
    } else {
      revert("Missing param");
    }

    rawArgs = abi.encode(param);
  }

  function _checkAdmin(
    address deployedContract
  ) internal {
    if (network() == DefaultNetwork.RoninTestnet.key()) {
      string memory proxyAdmin = vm.envString("PROXY_ADMIN");
      vm.assertEq(vm.toString(LibProxy.getProxyAdmin(address(deployedContract), false)), proxyAdmin);
    }
  }

  function _toSingletonArray(
    address addr
  ) internal pure returns (address[] memory arr) {
    arr = new address[](1);
    arr[0] = addr;
  }
}
