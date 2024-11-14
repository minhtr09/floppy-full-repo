// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ERC20SpenderWhitelist } from "src/common/ERC20SpenderWhitelist.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

contract FLP is ERC20SpenderWhitelist, Ownable {
  constructor() Ownable(_msgSender()) {
    _disableInitializers();
  }

  function initialize(
    address owner
  ) external initializer {
    __ERC20_init("Floppy", "FLP");
    _mint(owner, 100 * 1e9 * 1e18);
    _transferOwnership(owner);
  }

  function whitelist(
    address _spender
  ) external onlyOwner {
    _whitelist(_spender);
  }

  function unwhitelist(
    address _spender
  ) external onlyOwner {
    _unwhitelist(_spender);
  }

  function _msgSender() internal view override(Context, ContextUpgradeable) returns (address) {
    return super._msgSender();
  }

  function _msgData() internal view override(Context, ContextUpgradeable) returns (bytes calldata) {
    return super._msgData();
  }

  function _contextSuffixLength() internal view override(Context, ContextUpgradeable) returns (uint256) {
    return super._contextSuffixLength();
  }
}
