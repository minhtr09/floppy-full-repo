// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@interfaces/IFloppyVault.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import { ERC20Upgradeable, IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract FloppyVault is IFloppyVault, ERC20Upgradeable, Pausable, AccessControlEnumerable {
  uint256 public constant MAX_PERCENTAGE = 100_000;

  /// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
  bytes32 public constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

  /// @dev keccak256("Permit(address requester,address recipient,uint256 nonce,uint256 amount,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0xb365888e64ab7bc61fb16d9b1949494d2eb12e26fcdf26e14b500893673a5a59;

  /// @dev Gap for upgradability.
  uint256[50] private _____gap;

  bytes32 public DOMAIN_SEPARATOR;

  /// @dev mapping: user => nonce
  mapping(address => uint256) internal _userNonceMap;

  /// @dev Address of the token asset.
  IERC20 internal _asset;

  /// @dev Tax percentage Vault would take per deposit or mint request. [0_000 -> 100_000] 0% -> 100%;
  uint256 internal _taxPercent;

  /// @dev Signer address.
  address _signer;

  modifier notZero(
    uint256 value
  ) {
    if (value == 0) revert InvalidAmount();
    _;
  }

  constructor() Pausable() {
    _disableInitializers();
  }

  function initialize(address admin, IERC20 token, uint256 taxPercent) external initializer {
    if (address(token) == address(0)) revert InvalidAssetAddress();
    __ERC20_init("Floppy Vault", "FVT");
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _updateDomainSeparator();
    _asset = token;
    _taxPercent = taxPercent;
    _signer = admin;
  }

  /// @inheritdoc IFloppyVault
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  /// @inheritdoc IFloppyVault
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  /// @inheritdoc IFloppyVault
  function setAsset(
    IERC20 asset
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _asset = asset;
    emit AssetUpdated(address(asset));
  }

  /// @inheritdoc IFloppyVault
  function setSigner(
    address signer
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _signer = signer;
    emit SignerUpdated(address(signer));
  }

  /// @inheritdoc IFloppyVault
  function deposit(
    uint256 tokenAmount,
    address receiver
  ) external whenNotPaused notZero(tokenAmount) returns (uint256 shares) {
    shares = previewDeposit(tokenAmount);
    _deposit(_msgSender(), receiver, tokenAmount, shares);
  }

  /// @inheritdoc IFloppyVault
  function withdraw(
    uint256 tokenAmount,
    address receiver,
    address owner
  ) external whenNotPaused notZero(tokenAmount) returns (uint256 shares) {
    // Save 2 times SLOAD.
    uint256 maxTokenAmount = maxWithdraw(owner);
    if (tokenAmount > maxTokenAmount) {
      revert ExceededMaxWithdraw(owner, tokenAmount, maxTokenAmount);
    }
    shares = previewWithdraw(tokenAmount);
    _withdraw(_msgSender(), owner, receiver, tokenAmount, shares);
  }

  /// @inheritdoc IFloppyVault
  function permitRewardWithdraw(
    address recipient,
    uint256 tokenAmount,
    uint256 nonce,
    uint256 deadline,
    bytes memory signature
  ) external whenNotPaused notZero(tokenAmount) {
    if (deadline < block.timestamp) revert SignatureExprired();
    if (nonce != _userNonceMap[_msgSender()]) revert ErrInvalidNonce();

    _validateSignature(_msgSender(), recipient, nonce, tokenAmount, deadline, signature);
    _increaseUserNonce(_msgSender());

    SafeERC20.safeTransfer(_asset, recipient, tokenAmount);
    emit WithdrawReward(recipient, tokenAmount);
  }

  /// @inheritdoc IFloppyVault
  function mint(uint256 shares, address receiver) external whenNotPaused notZero(shares) returns (uint256 tokenAmount) {
    tokenAmount = previewMint(shares);
    _deposit(_msgSender(), receiver, tokenAmount, shares);
  }

  /// @inheritdoc IFloppyVault
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) external whenNotPaused notZero(shares) returns (uint256 tokenAmount) {
    uint256 maxShares = maxRedeem(owner);
    if (shares > maxShares) {
      revert ExceededMaxRedeem(owner, shares, maxShares);
    }
    tokenAmount = previewRedeem(shares);
    _withdraw(_msgSender(), owner, receiver, tokenAmount, shares);
  }

  /// @inheritdoc IFloppyVault
  function asset() public view returns (address assetTokenAddress) {
    assetTokenAddress = address(_asset);
  }

  /// @inheritdoc IFloppyVault
  function totalAssets() public view returns (uint256 totalManagedAssets) {
    totalManagedAssets = _asset.balanceOf(address(this));
  }

  /// @inheritdoc IFloppyVault
  function maxWithdraw(
    address user
  ) public view returns (uint256 tokenAmount) {
    tokenAmount = previewRedeem(balanceOf(user));
  }

  /// @inheritdoc IFloppyVault
  function maxRedeem(
    address user
  ) public view returns (uint256 shares) {
    shares = balanceOf(user);
  }

  /// @inheritdoc IFloppyVault
  function convertToShares(
    uint256 assetAmount
  ) public view returns (uint256 shares) {
    shares = _convertToShares(assetAmount);
  }

  /// @inheritdoc IFloppyVault
  function convertToAssets(
    uint256 shares
  ) public view returns (uint256 assetAmount) {
    assetAmount = _convertToAssets(shares);
  }

  /// @inheritdoc IFloppyVault
  function previewDeposit(
    uint256 tokenAmount
  ) public view returns (uint256 shares) {
    shares = _convertToShares(tokenAmount);
  }

  /// @inheritdoc IFloppyVault
  function previewWithdraw(
    uint256 tokenAmount
  ) public view returns (uint256 shares) {
    uint256 taxFee = _calTaxFee(tokenAmount);
    shares = _convertToShares(tokenAmount + taxFee);
  }

  /// @inheritdoc IFloppyVault
  function previewMint(
    uint256 shares
  ) public view returns (uint256 tokenAmount) {
    tokenAmount = _convertToAssets(shares);
  }

  /// @inheritdoc IFloppyVault
  function previewRedeem(
    uint256 shares
  ) public view returns (uint256 tokenAmount) {
    uint256 idealAmount = _convertToAssets(shares);
    uint256 taxFee = _calTaxFee(idealAmount);
    tokenAmount = idealAmount - taxFee;
  }

  /// @inheritdoc IFloppyVault
  function getUserNonce(
    address user
  ) external view returns (uint256) {
    return _userNonceMap[user];
  }

  function _convertToShares(
    uint256 tokenAmount
  ) internal view returns (uint256 shares) {
    shares = (tokenAmount * (totalSupply() + 10 ** _virtualOffset())) / (totalAssets() + 1);
  }

  function _convertToAssets(
    uint256 shares
  ) internal view returns (uint256 assetAmount) {
    assetAmount = (shares * (totalAssets() + 1)) / (totalSupply() + 10 ** _virtualOffset());
  }

  function _deposit(address caller, address receiver, uint256 tokenAmount, uint256 shares) internal {
    SafeERC20.safeTransferFrom(_asset, caller, address(this), tokenAmount);
    _mint(receiver, shares);
    emit Deposit(caller, receiver, tokenAmount, shares);
  }

  function _withdraw(address caller, address owner, address receiver, uint256 tokenAmount, uint256 shares) internal {
    if (caller != owner) {
      _spendAllowance(owner, caller, shares);
    }
    _burn(owner, shares);
    SafeERC20.safeTransfer(_asset, receiver, tokenAmount);
    emit Withdraw(caller, owner, receiver, tokenAmount, shares);
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

  /// @dev Virtual offset to prevent inflation attacks.
  function _virtualOffset() private pure returns (uint8) {
    return 3;
  }

  /// @dev Helper function to calculate tax.
  function _calTaxFee(
    uint256 tokenAmount
  ) private view returns (uint256 taxFee) {
    taxFee = (tokenAmount * _taxPercent) / MAX_PERCENTAGE;
  }

  /// @dev Updates domain separator.
  function _updateDomainSeparator() internal {
    bytes32 nameHash = keccak256(bytes("FloppyVault"));
    bytes32 versionHash = keccak256(bytes("1"));
    assembly ("memory-safe") {
      let free_mem_ptr := mload(0x40) // Load the free memory pointer.
      mstore(free_mem_ptr, DOMAIN_TYPEHASH)
      mstore(add(free_mem_ptr, 0x20), nameHash)
      mstore(add(free_mem_ptr, 0x40), versionHash)
      mstore(add(free_mem_ptr, 0x60), chainid())
      mstore(add(free_mem_ptr, 0x80), address())
      sstore(DOMAIN_SEPARATOR.slot, keccak256(free_mem_ptr, 0xa0))
    }
  }

  function _validateSignature(
    address requester,
    address recipient,
    uint256 nonce,
    uint256 tokenAmount,
    uint256 deadline,
    bytes memory signature
  ) internal view {
    address signer = ECDSA.recover(
      MessageHashUtils.toTypedDataHash(
        DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, requester, recipient, nonce, tokenAmount, deadline))
      ),
      signature
    );
    if (signer != _signer) revert InvalidSignature();
  }

  function _increaseUserNonce(
    address user
  ) internal returns (uint256 newNonce) {
    newNonce = ++_userNonceMap[user];
    emit UserNonceIncreased(user, newNonce);
  }
}
