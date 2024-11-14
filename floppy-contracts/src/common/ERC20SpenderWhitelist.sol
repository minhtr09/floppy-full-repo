// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { SpenderWhitelist } from "./SpenderWhitelist.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ERC20SpenderWhitelist is SpenderWhitelist, ERC20Upgradeable {
  function allowance(address _owner, address _spender) public view virtual override returns (uint256 _value) {
    if (whitelisted[_spender]) {
      return type(uint256).max;
    }

    return super.allowance(_owner, _spender);
  }
}
