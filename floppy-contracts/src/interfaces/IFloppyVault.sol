// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFloppyVault is IERC20 {
  /// @dev Emit when the vault's asset is updated.
  event AssetUpdated(address indexed asset);

  // @dev Emit when the signer is updated.
  event SignerUpdated(address indexed asset);

  /// @dev Emit when user deposit ERC20 token.
  event Deposit(address indexed sender, address indexed owner, uint256 tokenAmount, uint256 shares);

  /// @dev Emit when user withdraw ERC20 token.
  event Withdraw(
    address indexed sender, address indexed owner, address indexed receiver, uint256 tokenAmount, uint256 shares
  );

  /// @dev Emit when user withdraw reward.
  event WithdrawReward(address indexed sender, uint256 tokenAmount);

  /// @dev Emit when user's nonce is increased.
  event UserNonceIncreased(address indexed user, uint256 newNonce);

  /// @dev Revert when asset is address(0);
  error InvalidAssetAddress();

  /// @dev Revert when nonce is not increase by one.
  error ErrInvalidNonce();

  /// @dev Revert signature expired.
  error SignatureExprired();

  /// @dev Revert when deposit or mint amount is 0;
  error InvalidAmount();

  /// @dev Revert when signature is invalid.
  error InvalidSignature();

  /// @dev Attempted to withdraw more assets than the max amount for `receiver`.
  error ExceededMaxWithdraw(address owner, uint256 assets, uint256 max);

  /// @dev Attempted to redeem more shares than the max amount for `receiver`.
  error ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

  /// @dev Return domain type hash.
  function DOMAIN_TYPEHASH() external pure returns (bytes32);

  /// @dev Return permit type hash.
  function PERMIT_TYPEHASH() external pure returns (bytes32);

  /// @dev Return domain seperator.
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /// @dev Return token address managed by this vault.
  function asset() external view returns (address assetTokenAddress);

  /// @dev Return total token amout of this vault.
  function totalAssets() external view returns (uint256 totalManagedAssets);

  /// @dev Return maximum amount of tokens user can withdraw.
  function maxWithdraw(
    address user
  ) external view returns (uint256 tokenAmount);

  /// @dev Return maximum shares user can burn.
  function maxRedeem(
    address user
  ) external view returns (uint256 shares);

  /// @dev Return the ideal amount of shares the Vault would exchange for the amount of tokens recieved.
  function convertToShares(
    uint256 assetAmount
  ) external view returns (uint256 shares);

  /// @dev Return the ideal amount of tokens the Vault would exchange for the amount of shares.
  function convertToAssets(
    uint256 shares
  ) external view returns (uint256 assetAmount);

  /**
   * @dev Return the actual shares would be recieved when deposit amount of tokens.
   * NOTE: this function may not equal to convertToShares because of tax, etc.
   */
  function previewDeposit(
    uint256 tokenAmount
  ) external view returns (uint256 shares);

  /**
   * @dev Return the amount of shares need to burn in order to withdraw exactly an amount of tokens.
   * NOTE: this function may not equal to convertToShares because of tax, etc.
   */
  function previewWithdraw(
    uint256 tokenAmount
  ) external view returns (uint256 shares);

  /**
   * @dev Return the token amount would need to deposit in order to mint exactly amount of shares.
   * NOTE: this function may not equal to convertToAssets because of tax, etc.
   */
  function previewMint(
    uint256 shares
  ) external view returns (uint256 tokenAmount);

  /**
   * @dev Return the actual token amount would get when burn amount of shares.
   * NOTE: this function may not equal to convertToAssets because of tax, etc.
   */
  function previewRedeem(
    uint256 shares
  ) external view returns (uint256 tokenAmount);

  /**
   * @dev Return user's nonce.
   * Emit an {UserNonceIncreased} event.
   */
  function getUserNonce(
    address user
  ) external view returns (uint256);

  /**
   * @dev Set Vault's asset.
   * Just admin can call this function.
   * Emit an {AssetUpdated} event.
   */
  function setAsset(
    IERC20 asset
  ) external;

  /**
   * @dev Set Vault signer.
   * Just admin can call this function.
   * Emit an {SignerUpdated} event.
   */
  function setSigner(
    address signer
  ) external;

  /**
   * @dev Deposits assets into the vault and mints shares to the receiver.
   *
   * This function transfers assets from the caller to the vault and mints corresponding shares to the receiver.
   *
   * @param tokenAmount The amount of tokens to deposit.
   * @param receiver The address receiving the minted shares.
   * @return shares The number of shares minted to the receiver.
   *
   * @notice The actual number of shares minted may differ from the ideal conversion due to rounding or fees.
   *
   * Emits a {Deposit} event.
   */
  function deposit(uint256 tokenAmount, address receiver) external returns (uint256 shares);

  /**
   * @dev Withdraws assets from the vault by burning shares from the owner.
   *
   * This function burns shares from the owner and transfers the corresponding assets to the receiver.
   *
   * @param tokenAmount The amount of tokens to withdraw.
   * @param receiver The address receiving the withdrawn assets.
   * @param owner The address whose shares are being burned.
   * @return shares The number of shares burned from the owner.
   *
   * @notice The caller must have approval to burn the owner's shares if not the owner.
   *
   * Emits a {Withdraw} event.
   */
  function withdraw(uint256 tokenAmount, address receiver, address owner) external returns (uint256 shares);

  /**
   * @dev Withdraws reward with signature of the authorized signer.
   *
   * This function transfers assets directly to the recipient without burning shares.
   * It requires a valid signature from the authorized signer.
   *
   * @param recipient The address receiving the reward.
   * @param tokenAmount The amount of tokens to withdraw as a reward.
   * @param nonce The current nonce of the recipient, used to prevent replay attacks.
   * @param deadline The timestamp after which the signature is no longer valid.
   * @param signature The cryptographic signature authorizing the withdrawal.
   *
   * @notice This operation does not affect the recipient's share balance.
   *
   * Emits a {WithdrawReward} event.
   */
  function permitRewardWithdraw(
    address recipient,
    uint256 tokenAmount,
    uint256 nonce,
    uint256 deadline,
    bytes memory signature
  ) external;

  /**
   * @dev Mints a specific amount of shares to the receiver by depositing assets.
   *
   * This function calculates the required asset amount and transfers it from the caller to mint the specified shares.
   *
   * @param shares The number of shares to mint.
   * @param receiver The address receiving the minted shares.
   * @return tokenAmount The amount of tokens deposited to mint the shares.
   *
   * @notice The actual amount of assets required may be higher than expected due to rounding or fees.
   *
   * Emits a {Deposit} event.
   */
  function mint(uint256 shares, address receiver) external returns (uint256 tokenAmount);

  /**
   * @dev Redeems a specific amount of shares from the owner for assets.
   *
   * This function burns the specified amount of shares from the owner and transfers the corresponding assets to the receiver.
   *
   * @param shares The number of shares to redeem.
   * @param receiver The address receiving the assets.
   * @param owner The address whose shares are being redeemed.
   * @return tokenAmount The amount of tokens transferred to the receiver.
   *
   * @notice The caller must have approval to burn the owner's shares if not the owner.
   *
   * Emits a {Withdraw} event.
   */
  function redeem(uint256 shares, address receiver, address owner) external returns (uint256 tokenAmount);

  /**
   * @dev Pauses the Vault functionality.
   *
   * Requirements:
   * - The caller must have the admin role.
   *
   */
  function pause() external;

  /**
   * @dev Unpauses the registrar controller's functionality.
   *
   * Requirements:
   * - The caller must have the admin role.
   *
   */
  function unpause() external;
}
