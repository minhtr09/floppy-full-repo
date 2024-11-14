// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@interfaces/IFloppyGamble.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract FloppyGamble is IFloppyGamble, Initializable, Ownable {
  uint256 public constant MAX_PERCENTAGE = 100_000;
  /// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
  bytes32 public constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
  /// @dev keccak256("Permit(uint256 betId,address requester,address receiver,uint256 points,uint256 betAmount,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x50868ac445b6de6f2e1973a0c096591dec8882fe4d476c7b8682133b74f74523;
  /// @dev keccak256("Permit(uint256 betId,address requester)")
  bytes32 public constant CANCEL_PERMIT_TYPEHASH = 0x0;

  /// @dev Time period within which a bet can be canceled
  uint256 public constant CANCELLATION_PERIOD = 1 hours;
  bytes32 public DOMAIN_SEPARATOR;
  /// @dev Mapping of bet IDs to their corresponding bet information
  mapping(uint256 betId => BetInfo info) internal _bets;
  /// @dev Mapping of bet tiers to their corresponding points ranges
  mapping(BetTier tier => PointsRange range) internal _pointsRanges;
  /// @dev Mapping of bet tiers to their corresponding reward percentages
  mapping(BetTier tier => uint256 rewardPercentage) internal _rewardPercentages;
  /// @dev Counter for bet IDs
  uint256 internal _ids;
  /// @dev Maximum allowed bet amount
  uint256 internal _maxBetAmount;
  /// @dev Minimum allowed bet amount
  uint256 internal _minBetAmount;
  /// @dev Percentage of the bet amount to be deducted as a penalty when a bet is canceled
  uint256 internal _penaltyForCanceledBet;
  /// @dev Address of the signer for bet validation
  address internal _signer;
  /// @dev ERC20 token used for betting
  IERC20 internal _asset;
  /// @dev Address of the wallet used to distribute rewards
  address internal _wallet;
  /// @dev Reserved space for upgradeability
  uint256[50] private _____gap;

  constructor() Ownable(_msgSender()) {
    _disableInitializers();
  }

  function initialize(
    IERC20 asset,
    address wallet,
    uint256 maxBetAmount,
    uint256 minBetAmount,
    address signer,
    uint256 penaltyForCanceledBet,
    // Points ranges for each bet tier
    // pointsRanges[0] -> Bronze
    // pointsRanges[1] -> Silver
    // pointsRanges[2] -> Gold
    // pointsRanges[3] -> Diamond
    PointsRange[] calldata pointsRanges,
    // Reward percentages for each bet tier
    // rewardPercentages[0] -> Bronze
    // rewardPercentages[1] -> Silver
    // rewardPercentages[2] -> Gold
    // rewardPercentages[3] -> Diamond
    uint256[] calldata rewardPercentages
  ) external initializer {
    _transferOwnership(_msgSender());
    _updateDomainSeparator();
    _setPointsRanges(pointsRanges);
    _setRewardPercentages(rewardPercentages);
    _setAsset(asset);
    _setWallet(wallet);
    _setSigner(signer);
    _setMaxBetAmount(maxBetAmount);
    _setMinBetAmount(minBetAmount);
    _setPenaltyForCanceledBet(penaltyForCanceledBet);
  }

  /// @inheritdoc IFloppyGamble
  function placeBet(address receiver, uint256 amount, BetTier tier) external returns (uint256 betId) {
    if (amount > _maxBetAmount || amount < _minBetAmount) {
      revert InvalidBetAmount();
    }
    if (tier == BetTier.Unknown) revert InvalidBetTier();
    if (receiver == address(0)) revert NullAddress();
    address requester = _msgSender();

    SafeERC20.safeTransferFrom(_asset, requester, address(this), amount);
    betId = _ids++;

    _bets[betId] = BetInfo({
      requester: requester,
      receiver: receiver,
      amount: amount,
      tier: tier,
      status: BetStatus.Pending,
      timestamp: block.timestamp,
      points: 0,
      reward: 0,
      win: false,
      claimed: false
    });

    emit BetPlaced(requester, betId);
  }

  /// @inheritdoc IFloppyGamble
  function cancelBet(uint256 betId, bytes memory signature) external {
    BetInfo storage betInfo = _bets[betId];
    address requester = _msgSender();

    _requireBetExists(betId);
    _requireBetStatus(betInfo.status, BetStatus.Pending);
    if (betInfo.requester != requester) revert ErrNotRequester();

    _validateCancelSignature(betId, requester, signature);

    uint256 betAmount = betInfo.amount;
    uint256 penaltyAmount = (betAmount * _penaltyForCanceledBet) / MAX_PERCENTAGE;
    SafeERC20.safeTransfer(_asset, _wallet, penaltyAmount);
    SafeERC20.safeTransfer(_asset, requester, betAmount - penaltyAmount);

    betInfo.status = BetStatus.Canceled;
    emit BetCanceled(requester, betId);
  }

  function cancelBet(
    uint256 betId
  ) external {
    BetInfo storage betInfo = _bets[betId];
    address requester = _msgSender();

    _requireBetExists(betId);
    _requireBetStatus(betInfo.status, BetStatus.Pending);
    if (betInfo.requester != requester) revert ErrNotRequester();

    uint256 betAmount = betInfo.amount;
    uint256 penaltyAmount = (betAmount * _penaltyForCanceledBet) / MAX_PERCENTAGE;
    SafeERC20.safeTransfer(_asset, _wallet, penaltyAmount);
    SafeERC20.safeTransfer(_asset, requester, betAmount - penaltyAmount);

    betInfo.status = BetStatus.Canceled;
    emit BetCanceled(requester, betId);
  }

  /// @inheritdoc IFloppyGamble
  function resolveBet(uint256 betId, uint256 points, uint256 deadline, bytes memory signature) external {
    BetInfo storage betInfo = _bets[betId];
    uint256 betAmount = betInfo.amount;
    _requireBetExists(betId);
    _requireBetStatus(betInfo.status, BetStatus.Pending);
    if (deadline < block.timestamp) revert SignatureExpired();

    _validateSignature(betId, betInfo.requester, betInfo.receiver, points, betAmount, deadline, signature);

    betInfo.status = BetStatus.Resolved;
    betInfo.points = points;
    bool isWin = points >= _pointsRanges[betInfo.tier].minPoints;
    betInfo.win = isWin;
    if (isWin) {
      betInfo.reward = (betAmount * _rewardPercentages[betInfo.tier]) / MAX_PERCENTAGE;
    }

    emit BetResolved(betId, isWin);
  }

  /// @inheritdoc IFloppyGamble
  function claimReward(
    uint256 betId
  ) external returns (uint256 rewardAmount) {
    BetInfo storage betInfo = _bets[betId];
    _requireBetExists(betId);
    _requireBetStatus(betInfo.status, BetStatus.Resolved);
    if (!betInfo.win) revert BetLost(betId);
    if (betInfo.claimed) revert RewardAlreadyClaimed(betId);

    betInfo.claimed = true;
    rewardAmount = betInfo.reward;
    _claimReward(betInfo.receiver, rewardAmount);
  }

  /// @inheritdoc IFloppyGamble
  function resolveBetAndClaimReward(
    uint256 betId,
    uint256 points,
    uint256 deadline,
    bytes memory signature
  ) external returns (uint256 rewardAmount) {
    this.resolveBet(betId, points, deadline, signature);
    rewardAmount = this.claimReward(betId);
  }

  /// @inheritdoc IFloppyGamble
  function setMinBetAmount(
    uint256 minBetAmount
  ) external onlyOwner {
    if (minBetAmount > _maxBetAmount || minBetAmount == 0) {
      revert InvalidMinBetAmount();
    }
    _setMinBetAmount(minBetAmount);
  }

  /// @inheritdoc IFloppyGamble
  function setMaxBetAmount(
    uint256 maxBetAmount
  ) external onlyOwner {
    if (maxBetAmount < _minBetAmount || maxBetAmount == 0) {
      revert InvalidMaxBetAmount();
    }
    _setMaxBetAmount(maxBetAmount);
  }

  /// @inheritdoc IFloppyGamble
  function setSigner(
    address signer
  ) external onlyOwner {
    if (signer == address(0)) revert NullAddress();
    _setSigner(signer);
  }

  /// @inheritdoc IFloppyGamble
  function setAsset(
    IERC20 asset
  ) external onlyOwner {
    if (address(asset) == address(0)) revert NullAddress();
    _setAsset(asset);
  }

  /// @inheritdoc IFloppyGamble
  function setWallet(
    address wallet
  ) external onlyOwner {
    if (wallet == address(0)) revert NullAddress();
    _setWallet(wallet);
  }

  /// @inheritdoc IFloppyGamble
  function setPenaltyForCanceledBet(
    uint256 penaltyForCanceledBet
  ) external onlyOwner {
    if (penaltyForCanceledBet >= MAX_PERCENTAGE || penaltyForCanceledBet == 0) revert InvalidPenaltyForCanceledBet();
    _setPenaltyForCanceledBet(penaltyForCanceledBet);
  }

  /// @inheritdoc IFloppyGamble
  function setPointsRanges(
    PointsRange[] calldata pointsRanges
  ) external onlyOwner {
    if (pointsRanges.length != 4) revert InvalidLength();
    _setPointsRanges(pointsRanges);
  }

  /// @inheritdoc IFloppyGamble
  function setRewardPercentages(
    uint256[] calldata rewardPercentages
  ) external onlyOwner {
    if (rewardPercentages.length != 4) revert InvalidLength();
    _setRewardPercentages(rewardPercentages);
  }

  /// @inheritdoc IFloppyGamble
  function getMaxPointsForTier(
    BetTier tier
  ) external view returns (uint256) {
    return _pointsRanges[tier].maxPoints;
  }

  /// @inheritdoc IFloppyGamble
  function getMinPointsForTier(
    BetTier tier
  ) external view returns (uint256) {
    return _pointsRanges[tier].minPoints;
  }

  /// @inheritdoc IFloppyGamble
  function getPointsRangeForTier(
    BetTier tier
  ) external view returns (uint256, uint256) {
    PointsRange memory range = _pointsRanges[tier];
    return (range.minPoints, range.maxPoints);
  }

  /// @inheritdoc IFloppyGamble
  function getPenaltyForCanceledBet() external view returns (uint256) {
    return _penaltyForCanceledBet;
  }

  /// @inheritdoc IFloppyGamble
  function getReward(BetTier tier, uint256 betAmount) external view returns (uint256) {
    return (betAmount * _rewardPercentages[tier]) / MAX_PERCENTAGE;
  }

  /// @inheritdoc IFloppyGamble
  function getBetInfoById(
    uint256 betId
  ) external view returns (BetInfo memory) {
    return _bets[betId];
  }

  function getLastBetId() external view returns (uint256) {
    return _ids - 1;
  }

  /// @inheritdoc IFloppyGamble
  function getBetsByStatus(
    BetStatus status
  ) external view returns (uint256[] memory betIds, BetInfo[] memory bets) {
    uint256 length = _ids;
    uint256 count;
    for (uint256 i = 0; i < length; ++i) {
      if (_bets[i].status == status) ++count;
    }

    betIds = new uint256[](count);
    bets = new BetInfo[](count);

    for (uint256 i = 0; i < length; ++i) {
      if (_bets[i].status == status) {
        betIds[i] = i;
        bets[i] = _bets[i];
      }
    }
  }

  /// @inheritdoc IFloppyGamble
  function getAllBets() external view returns (uint256[] memory betIds, BetInfo[] memory bets) {
    uint256 length = _ids;
    betIds = new uint256[](length);
    bets = new BetInfo[](length);

    for (uint256 i = 0; i < length; ++i) {
      betIds[i] = i;
      bets[i] = _bets[i];
    }
  }

  /// @inheritdoc IFloppyGamble
  function getMaxBetAmount() external view returns (uint256) {
    return _maxBetAmount;
  }

  /// @inheritdoc IFloppyGamble
  function getMinBetAmount() external view returns (uint256) {
    return _minBetAmount;
  }

  /// @inheritdoc IFloppyGamble
  function getSigner() external view returns (address) {
    return _signer;
  }

  /// @inheritdoc IFloppyGamble
  function getAsset() external view returns (address) {
    return address(_asset);
  }

  /// @inheritdoc IFloppyGamble
  function getWallet() external view returns (address) {
    return _wallet;
  }

  function _setMinBetAmount(
    uint256 minBetAmount
  ) internal {
    _minBetAmount = minBetAmount;
    emit MinBetAmountUpdated(minBetAmount);
  }

  function _setMaxBetAmount(
    uint256 maxBetAmount
  ) internal {
    _maxBetAmount = maxBetAmount;
    emit MaxBetAmountUpdated(maxBetAmount);
  }

  function _setSigner(
    address signer
  ) internal {
    _signer = signer;
    emit SignerUpdated(signer);
  }

  function _setAsset(
    IERC20 asset
  ) internal {
    _asset = asset;
    emit AssetUpdated(address(asset));
  }

  function _setWallet(
    address wallet
  ) internal {
    _wallet = wallet;
    emit WalletUpdated(wallet);
  }

  function _setPenaltyForCanceledBet(
    uint256 penaltyForCanceledBet
  ) internal {
    _penaltyForCanceledBet = penaltyForCanceledBet;
    emit PenaltyForCanceledBetUpdated(penaltyForCanceledBet);
  }

  function _setPointsRanges(
    PointsRange[] calldata pointsRanges
  ) internal {
    _pointsRanges[BetTier.Bronze] = pointsRanges[0];
    _pointsRanges[BetTier.Silver] = pointsRanges[1];
    _pointsRanges[BetTier.Gold] = pointsRanges[2];
    _pointsRanges[BetTier.Diamond] = pointsRanges[3];
    emit PointsRangesUpdated(pointsRanges);
  }

  function _setRewardPercentages(
    uint256[] calldata rewardPercentages
  ) internal {
    _rewardPercentages[BetTier.Bronze] = rewardPercentages[0];
    _rewardPercentages[BetTier.Silver] = rewardPercentages[1];
    _rewardPercentages[BetTier.Gold] = rewardPercentages[2];
    _rewardPercentages[BetTier.Diamond] = rewardPercentages[3];
    emit RewardPercentagesUpdated(rewardPercentages);
  }

  /// @dev Helper function for claiming reward.
  function _claimReward(address receiver, uint256 amount) internal {
    SafeERC20.safeTransfer(_asset, receiver, amount);
    emit RewardClaimed(receiver, amount);
  }

  function _requireBetStatus(BetStatus status, BetStatus expected) internal pure {
    if (status != expected) revert InvalidBetStatus(status, expected);
  }

  function _requireBetExists(
    uint256 betId
  ) internal view {
    if (betId >= _ids) revert BetDoesNotExist();
  }

  function _validateSignature(
    uint256 betId,
    address requester,
    address receiver,
    uint256 points,
    uint256 betAmount,
    uint256 deadline,
    bytes memory signature
  ) internal view {
    address signer = ECDSA.recover(
      MessageHashUtils.toTypedDataHash(
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, betId, requester, receiver, points, betAmount, deadline))
      ),
      signature
    );
    if (signer != _signer) revert InvalidSignature();
  }

  function _validateCancelSignature(uint256 betId, address requester, bytes memory signature) internal view {
    address signer = ECDSA.recover(
      MessageHashUtils.toTypedDataHash(
        DOMAIN_SEPARATOR, keccak256(abi.encode(CANCEL_PERMIT_TYPEHASH, betId, requester))
      ),
      signature
    );
    if (signer != _signer) revert InvalidSignature();
  }

  /// @dev Updates domain separator.
  function _updateDomainSeparator() internal {
    bytes32 nameHash = keccak256(bytes("FloppyGamble"));
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
}
