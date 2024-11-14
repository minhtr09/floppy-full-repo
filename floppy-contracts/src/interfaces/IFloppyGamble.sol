// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFloppyGamble {
  enum BetTier {
    Unknown,
    Bronze, // 50 -> 100
    Silver, // 101 -> 200
    Gold, // 201 -> 400
    Diamond // 401 -> Infinity
  }

  enum BetStatus {
    Unknown,
    Pending,
    Resolved,
    Canceled
  }

  struct BetInfo {
    address requester;
    address receiver;
    BetTier tier;
    BetStatus status;
    uint256 amount;
    uint256 points;
    uint256 reward;
    uint256 timestamp;
    bool win;
    bool claimed;
  }

  struct PointsRange {
    uint256 minPoints;
    uint256 maxPoints;
  }

  /// @dev Emit when the signer is updated.
  event SignerUpdated(address indexed signer);
  /// @dev Emit when the asset is updated.
  event AssetUpdated(address indexed asset);
  /// @dev Emit when the wallet used to distribute rewards is updated.
  event WalletUpdated(address indexed wallet);
  /// @dev Emit when the max bet amount is updated.
  event MaxBetAmountUpdated(uint256 maxBetAmount);
  /// @dev Emit when the min bet amount is updated.
  event MinBetAmountUpdated(uint256 minBetAmount);
  /// @dev Emit when the points ranges are updated.
  event PointsRangesUpdated(PointsRange[] pointsRanges);
  /// @dev Emit when a bet is placed.
  event BetPlaced(address indexed requester, uint256 betId);
  /// @dev Emit when a bet is canceled.
  event BetCanceled(address indexed requester, uint256 betId);
  /// @dev Emit when a bet is resolved.
  event BetResolved(uint256 indexed betId, bool win);
  /// @dev Emit when the penalty for canceled bet is updated.
  event PenaltyForCanceledBetUpdated(uint256 penaltyForCanceledBet);
  /// @dev Emit when the reward percentages are updated.
  event RewardPercentagesUpdated(uint256[] rewardPercentages);
  /// @dev Emit when a user claims their reward
  event RewardClaimed(address indexed receiver, uint256 amount);

  /// @dev Revert when the signature is invalid.
  error InvalidSignature();
  /// @dev Revert when the bet tier is invalid.
  error InvalidBetTier();
  /// @dev Revert when the bet id is invalid.
  error InvalidBetId();
  /// @dev Revert when the bet is already resolved.
  error BetAlreadyResolved(uint256 betId);
  /// @dev Revert when the bet amount is invalid.
  error InvalidBetAmount();
  /// @dev Revert when array length is invalid.
  error InvalidLength();
  /// @dev Revert when the bet is already canceled.
  error BetAlreadyCanceled(uint256 betId);
  /// @dev Revert when the bet status is not expected.
  error InvalidBetStatus(BetStatus expected, BetStatus actual);
  /// @dev Revert when the receiver is null.
  error NullAddress();
  /// @dev Revert when the user is not the requester.
  error ErrNotRequester();
  /// @dev Revert when claim the reward for lost bet.
  error BetLost(uint256 betId);
  /// @dev Revert when claim the reward for already claimed bet.
  error RewardAlreadyClaimed(uint256 betId);
  /// @dev Revert when signature expired.
  error SignatureExpired();
  /// @dev Revert when min bet amount is greater than max bet amount or equal to zero.
  error InvalidMinBetAmount();
  /// @dev Revert when max bet amount is less than min bet amount or equal to zero.
  error InvalidMaxBetAmount();
  /// @dev Revert when penalty for canceled bet is greater than 100% or equal to zero.
  error InvalidPenaltyForCanceledBet();
  /// @dev Revert when bet does not exist.
  error BetDoesNotExist();
  /// @dev Revert when too soon to cancel bet.
  error TooSoonToCancel();

  /**
   * @dev Places a bet with the specified amount and tier.
   * This function allows a user to place a bet by specifying the amount and the tier of the bet.
   * Emits a {BetPlaced} event.
   *
   * @param receiver The address of the receiver of the bet.
   * @param amount The amount of the bet.
   * @param tier The tier of the bet.
   */
  function placeBet(address receiver, uint256 amount, BetTier tier) external returns (uint256);

  /**
   * @dev Cancels a bet that has been placed.
   * This function allows the requester to cancel their bet.
   * Only the requester who placed the bet can cancel it.
   * Emits a {BetCanceled} event.
   *
   * @param betId The ID of the bet to be canceled.
   */
  function cancelBet(uint256 betId, bytes memory signature) external;

  /**
   * @dev Resolves a bet that has been placed.
   * This function determines the outcome of the bet and updates the bet information accordingly.
   * Emits a {BetResolved} event.
   *
   * @param betId The ID of the bet to be resolved.
   * @param points The number of points achieved in the bet.
   * @param deadline The timestamp after which the signature becomes invalid.
   * @param signature The cryptographic signature provided by the backend to validate the result.
   */
  function resolveBet(uint256 betId, uint256 points, uint256 deadline, bytes memory signature) external;
  /**
   * @dev Resolves a bet and claims the reward.
   * This function resolves a bet and distributes the reward to the receiver based on the bet outcome.
   * Emits a {BetResolved} event and a {RewardClaimed} event if the bet is won.
   *
   * @param betId The ID of the bet to be resolved.
   * @param points The number of points achieved in the bet.
   * @param deadline The timestamp after which the signature becomes invalid.
   * @param signature The cryptographic signature provided by the backend to validate the result.
   * @return The amount of the reward distributed, or 0 if the bet is lost.
   */
  function resolveBetAndClaimReward(
    uint256 betId,
    uint256 points,
    uint256 deadline,
    bytes memory signature
  ) external returns (uint256);

  /**
   * @dev Claims the reward for a bet that has been resolved.
   * This function allows the receiver to claim the reward based on the bet outcome.
   * Emits a {RewardClaimed} event.
   *
   * @param betId The ID of the bet to claim the reward for.
   */
  function claimReward(
    uint256 betId
  ) external returns (uint256);
  /**
   * @dev Sets the minimum bet amount.
   * @param minBetAmount The new minimum bet amount.
   * Only callable by the owner.
   */
  function setMinBetAmount(
    uint256 minBetAmount
  ) external;

  /**
   * @dev Sets the maximum bet amount.
   * @param maxBetAmount The new maximum bet amount.
   * Only callable by the owner.
   */
  function setMaxBetAmount(
    uint256 maxBetAmount
  ) external;

  /**
   * @dev Sets the signer address.
   * @param signer The new signer address.
   * Only callable by the owner.
   */
  function setSigner(
    address signer
  ) external;

  /**
   * @dev Sets the asset token.
   * @param asset The new asset token address.
   * Only callable by the owner.
   */
  function setAsset(
    IERC20 asset
  ) external;

  /**
   * @dev Sets the wallet address.
   * @param wallet The new wallet address.
   * Only callable by the owner.
   */
  function setWallet(
    address wallet
  ) external;

  /**
   * @dev Sets the penalty for canceled bets.
   * @param penaltyForCanceledBet The new penalty percentage.
   * Only callable by the owner.
   */
  function setPenaltyForCanceledBet(
    uint256 penaltyForCanceledBet
  ) external;

  /**
   * @dev Sets the reward percentages for bet tiers.
   * @param rewardPercentages The new reward percentages for each tier.
   * Only callable by the owner.
   */
  function setRewardPercentages(
    uint256[] calldata rewardPercentages
  ) external;

  /**
   * @dev Sets the points ranges for bet tiers.
   * @param pointsRanges The new points ranges for each tier.
   * Only callable by the owner.
   */
  function setPointsRanges(
    PointsRange[] calldata pointsRanges
  ) external;

  /// @dev Function to get the penalty for canceled bet
  function getPenaltyForCanceledBet() external view returns (uint256);

  /// @dev Function to get the maximum points for a given tier
  function getMaxPointsForTier(
    BetTier tier
  ) external view returns (uint256);

  /// @dev Function to get the minimum points for a given tier
  function getMinPointsForTier(
    BetTier tier
  ) external view returns (uint256);

  /// @dev Function to get the points range for a given tier
  function getPointsRangeForTier(
    BetTier tier
  ) external view returns (uint256, uint256);

  /// @dev Function to get the reward for a given tier and bet amount
  function getReward(BetTier tier, uint256 betAmount) external view returns (uint256);

  /// @dev Function to get the bet info for a given bet ID
  function getBetInfoById(
    uint256 betId
  ) external view returns (BetInfo memory);

  /// @dev Function to get bets by status.
  function getBetsByStatus(
    BetStatus status
  ) external view returns (uint256[] memory, BetInfo[] memory);

  /// @dev Function to get all bets.
  function getAllBets() external view returns (uint256[] memory, BetInfo[] memory);

  /// @dev Function to get the maximum bet amount
  function getMaxBetAmount() external view returns (uint256);

  /// @dev Function to get the minimum bet amount
  function getMinBetAmount() external view returns (uint256);

  /// @dev Function to get the current signer address
  function getSigner() external view returns (address);

  /// @dev Function to get the current asset address
  function getAsset() external view returns (address);

  /// @dev Function to get the current wallet address
  function getWallet() external view returns (address);
}
