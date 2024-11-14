// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FLPDeploy } from "@script/contracts/FLPDeploy.s.sol";
import { FLP } from "@contracts/token/FLP.sol";
import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SpenderWhitelist } from "@contracts/common/SpenderWhitelist.sol";

contract FLPTest is Test {
  event SpenderWhitelisted(address indexed _spender);
  event SpenderUnwhitelisted(address indexed _spender);

  FLP internal _flpToken = new FLPDeploy().run();
  address internal _tokenOwner = 0x62aE17Ea20Ac44915B57Fa645Ce8c0f31cBD873f;
  address internal _whileListAddress = makeAddr("White List Address");
  address internal _randomUser1 = makeAddr("Random User 1");
  address internal _randomUser2 = makeAddr("Random User 2");
  address internal _randomUser3 = makeAddr("Random User 3");
  address internal _randomUser4 = makeAddr("Random User 4");

  modifier callAs(
    address caller
  ) {
    vm.startPrank(caller);
    _;
    vm.stopPrank();
  }

  function setUp() public virtual {
    vm.startPrank(_tokenOwner);
    _flpToken.whitelist(_whileListAddress);
    _flpToken.transfer(_randomUser1, 1000 ether);
    _flpToken.transfer(_randomUser2, 1000 ether);
    _flpToken.transfer(_randomUser3, 1000 ether);
    _flpToken.transfer(_randomUser4, 1000 ether);
    vm.stopPrank();
  }

  function _balance(
    address user
  ) internal returns (uint256) {
    return _flpToken.balanceOf(user);
  }

  function testConcrete_Whitelist_WithTokenOwner() external callAs(_tokenOwner) {
    vm.expectEmit(true, false, false, false);
    emit SpenderWhitelisted(address(1));
    _flpToken.whitelist(address(1));
  }

  function testConcrete_UnWhitelist_WithTokenOwner() external callAs(_tokenOwner) {
    vm.expectEmit(true, false, false, false);
    emit SpenderUnwhitelisted(address(1));
    _flpToken.unwhitelist(address(1));
  }
}
