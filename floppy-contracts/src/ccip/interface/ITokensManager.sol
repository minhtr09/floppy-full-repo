pragma solidity ^0.8.23;

interface ITokensManager {
  event TokenAdded(address indexed token);
  event TokenRemoved(address indexed token);
  event TokenRegistered(address indexed token, bool viaCCIPAdmin);
  event PoolSet(address indexed token, address indexed pool);
  event TokenAdminRegistrySet(address indexed tokenAdminRegistry);
  event RegistryModuleOwnerCustomSet(address indexed registryModuleOwnerCustom);
  event TokenCreated(address indexed token, address indexed deployer, uint256 initialSupply);

  error UnknownToken(address token);
  error UnauthorizedTokenDeployer(address token);

  function createTokenUnderManagement(
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 maxSupply,
    uint256 initialSupply
  ) external returns (address tokenAddress);
  function claimTokenOwnership(
    address token
  ) external;
  function registerToken(address token, bool viaCCIPAdmin) external;
  function updateTokens(address[] memory adds, address[] memory removes) external;
  function getManagedTokens() external view returns (address[] memory);
  function addToken(
    address token
  ) external;
  function isTokenUnderManagement(
    address token
  ) external view returns (bool);
}
