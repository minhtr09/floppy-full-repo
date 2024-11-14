// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FloppyVaultTest } from "./FloppyVault.t.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IFloppyVault } from "@interfaces/IFloppyVault.sol";

contract FloppyVault_PermitWithdraw_Test is FloppyVaultTest {
  function setUp() public override {
    super.setUp();
    vm.startPrank(testAdmin);
    _mockErc20.transfer(address(_floppyVault), 1000 ether);
  }

  // Happy cases for permitWithdraw() function.
  function testConcrete_PermitWithdraw_90FLP_EmitEvent_CheckRecipientBalance() external callAs(_user1) {
    address requester = _user1;
    address recipient = _user1;
    uint256 nonce = _floppyVault.getUserNonce(requester);
    uint256 tokenAmount = 90 ether;
    uint256 deadline = block.timestamp + 1 days;
    bytes memory sig = _signPermitStruct(requester, recipient, nonce, tokenAmount, deadline);

    _floppyVault.permitRewardWithdraw(recipient, tokenAmount, nonce, deadline, sig);
  }
  // Unhappy cases for permitWithdraw() function.
}
