// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FloppyVaultTest } from "./FloppyVault.t.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { StdStyle } from "forge-std/StdStyle.sol";

contract FloppyVault_Mint_Test is FloppyVaultTest {
  using StdStyle for *;

  // Happy cases for mint() function.
  function testConcrete_Mint100Shares_GetRightAmountOfShares_TransferRightAmountOfToken_And_EmitEvent()
    public
    callAs(testAdmin)
  {
    uint256 tokenWillPay = _calToken({ shares: 100 ether, withTax: false });
    uint256 userTokenBalanceBeforeMint = _mockErc20.balanceOf(testAdmin);
    uint256 vaultTokenBalanceBeforeMint = _mockErc20.balanceOf(address(_floppyVault));
    uint256 totalSharesBeforeMint = _floppyVault.totalSupply();

    console2.log("token will pay: ".cyan(), tokenWillPay);

    _expectEmitDeposit(testAdmin, testAdmin, tokenWillPay, 100 ether, 1);
    uint256 actualTokenWillPay = _floppyVault.mint(100 ether, testAdmin);

    assertEq(tokenWillPay, actualTokenWillPay);
    assertEq(_mockErc20.balanceOf(testAdmin), userTokenBalanceBeforeMint - actualTokenWillPay);
    assertEq(_mockErc20.balanceOf(address(_floppyVault)), vaultTokenBalanceBeforeMint + actualTokenWillPay);
    assertEq(_floppyVault.totalSupply(), totalSharesBeforeMint + 100 ether);
  }

  function testConcrete_Mint100Shares_ForReceiver_GetRightAmountOfShares_TransferRightAmountOfToken_And_EmitEvent()
    public
    callAs(testAdmin)
  {
    uint256 tokenWillPay = _calToken({ shares: 100 ether, withTax: false });
    uint256 userTokenBalanceBeforeMint = _mockErc20.balanceOf(testAdmin);
    uint256 vaultTokenBalanceBeforeMint = _mockErc20.balanceOf(address(_floppyVault));
    uint256 totalSharesBeforeMint = _floppyVault.totalSupply();

    console2.log("token will pay: ".cyan(), tokenWillPay);

    _expectEmitDeposit(testAdmin, _user1, tokenWillPay, 100 ether, 1);
    uint256 actualTokenWillPay = _floppyVault.mint(100 ether, _user1);

    assertEq(tokenWillPay, actualTokenWillPay);
    assertEq(_mockErc20.balanceOf(testAdmin), userTokenBalanceBeforeMint - actualTokenWillPay);
    assertEq(_mockErc20.balanceOf(address(_floppyVault)), vaultTokenBalanceBeforeMint + actualTokenWillPay);
    assertEq(_floppyVault.totalSupply(), totalSharesBeforeMint + 100 ether);
  }

  // Unhappy cases for deposit() function.
}
