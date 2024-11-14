// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FloppyVaultTest } from "./FloppyVault.t.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IFloppyVault } from "@interfaces/IFloppyVault.sol";
import { StdStyle } from "forge-std/StdStyle.sol";

contract FloppyVault_Redeem_Test is FloppyVaultTest {
  using StdStyle for *;

  function setUp() public override {
    super.setUp();

    vm.prank(_user1);
    _floppyVault.deposit(100 ether, _user1);

    vm.prank(_user2);
    _floppyVault.deposit(100 ether, _user2);

    vm.prank(testAdmin);
    _floppyVault.deposit(100 ether, testAdmin);
  }

  // Happy cases for redeem() function.

  // Unhappy cases for withdraw() function.
}
