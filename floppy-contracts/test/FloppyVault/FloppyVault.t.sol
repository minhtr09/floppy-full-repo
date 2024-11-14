// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2, Test } from "forge-std/Test.sol";
import { FloppyVaultDeploy } from "@script/contracts/FloppyVaultDeploy.s.sol";
import { FloppyVault } from "@contracts/FloppyVault.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { StdStyle } from "forge-std/StdStyle.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MockERC20 is ERC20, Test {
  address testAdmin = makeAddr("Test Admin");

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    _mint(testAdmin, 100e9 ether);
  }
}

contract FloppyVaultTest is Test {
  using StdStyle for *;

  event Deposit(address indexed sender, address indexed owner, uint256 tokenAmount, uint256 shares);
  event Withdraw(
    address indexed sender, address indexed receiver, address indexed owner, uint256 tokenAmount, uint256 shares
  );

  error EnforcedPause();
  error InvalidAmount();

  FloppyVault internal _floppyVault = new FloppyVaultDeploy().run();
  MockERC20 internal _mockErc20;
  address testAdmin = makeAddr("Test Admin");
  address internal _vaultAdmin = 0x62aE17Ea20Ac44915B57Fa645Ce8c0f31cBD873f;
  address internal _user1 = makeAddr("User 1");
  address internal _user2 = makeAddr("User 2");
  address _signer;
  uint256 _singerPk;

  modifier callAs(
    address caller
  ) {
    vm.startPrank(caller);
    _;
    vm.stopPrank();
  }

  modifier pause() {
    vm.prank(_vaultAdmin);
    _floppyVault.pause();
    _;
    vm.prank(_vaultAdmin);
    _floppyVault.unpause();
  }

  function setUp() public virtual {
    (_signer, _singerPk) = makeAddrAndKey("Signer");
    _mockErc20 = new MockERC20("Floppy", "FLP");

    vm.startPrank(_vaultAdmin);
    _floppyVault.setAsset(_mockErc20);
    _floppyVault.setSigner(_signer);
    vm.stopPrank();

    vm.startPrank(testAdmin);
    _mockErc20.transfer(_user1, 1000 ether);
    _mockErc20.transfer(_user2, 1000 ether);
    _mockErc20.approve(address(_floppyVault), type(uint256).max);
    vm.stopPrank();

    vm.prank(_user1);
    _mockErc20.approve(address(_floppyVault), type(uint256).max);

    vm.prank(_user2);
    _mockErc20.approve(address(_floppyVault), type(uint256).max);
  }

  function _calShares(uint256 tokenAmount, bool withTax) internal view returns (uint256) {
    if (withTax) {
      tokenAmount = ((tokenAmount) * 95_000) / 100_000;
    }
    return (tokenAmount * (_floppyVault.totalSupply() + 1e3)) / (_mockErc20.balanceOf(address(_floppyVault)) + 1);
  }

  function _calToken(uint256 shares, bool withTax) internal view returns (uint256) {
    uint256 tokenAmount =
      (shares * (_mockErc20.balanceOf(address(_floppyVault)) + 1)) / (_floppyVault.totalSupply() + 1e3);
    if (withTax) tokenAmount += tokenAmount * 5_000 / 100_000;
    return tokenAmount;
  }

  function _expectEmitDeposit(
    address sender,
    address owner,
    uint256 tokenAmount,
    uint256 shares,
    uint256 times
  ) internal {
    vm.expectEmit(true, true, false, true);
    for (uint256 i = 0; i < times; ++i) {
      emit Deposit(sender, owner, tokenAmount, shares);
    }
  }

  function _expectEmitWithdraw(
    address sender,
    address owner,
    address receiver,
    uint256 tokenAmount,
    uint256 shares,
    uint256 times
  ) internal {
    vm.expectEmit(true, true, true, true);
    for (uint256 i = 0; i < times; ++i) {
      emit Withdraw(sender, owner, receiver, tokenAmount, shares);
    }
  }

  function _signPermitStruct(
    address requester,
    address recipient,
    uint256 nonce,
    uint256 tokenAmount,
    uint256 deadline
  ) internal view returns (bytes memory) {
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      _singerPk,
      MessageHashUtils.toTypedDataHash(
        _floppyVault.DOMAIN_SEPARATOR(),
        keccak256(abi.encode(_floppyVault.PERMIT_TYPEHASH(), requester, recipient, nonce, tokenAmount, deadline))
      )
    );

    return abi.encodePacked(r, s, v);
  }
}
