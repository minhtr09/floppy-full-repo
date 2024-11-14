// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract SpenderWhitelist {
  event SpenderWhitelisted(address indexed _spender);
  event SpenderUnwhitelisted(address indexed _spender);

  mapping(address => bool) public whitelisted;

  function _whitelist(
    address _spender
  ) internal {
    whitelisted[_spender] = true;
    emit SpenderWhitelisted(_spender);
  }

  function _unwhitelist(
    address _spender
  ) internal {
    delete whitelisted[_spender];
    emit SpenderUnwhitelisted(_spender);
  }
}
