// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./FLP.t.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract FLP_TransferFrom_Test is FLPTest {
  function testConcrete_WhiteListAddress_Spend100FLP_OfRandomUser() external callAs(_whileListAddress) {
    _flpToken.transferFrom(_randomUser1, _randomUser2, 100 ether);

    assertEq(_balance(_randomUser1), 900 ether);
    assertEq(_balance(_randomUser2), 1100 ether);
  }

  function testRevert_When_Spend100FLP_OfRandomUser_WithSufficientAllowed() external callAs(_randomUser3) {
    vm.expectRevert(
      abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, _randomUser3, 0, 100 ether)
    );
    _flpToken.transferFrom(_randomUser1, _randomUser2, 100 ether);
  }
}
