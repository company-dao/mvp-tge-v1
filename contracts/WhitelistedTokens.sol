// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IWhitelistedTokens.sol";
import "./libraries/ExceptionsLibrary.sol";

contract WhitelistedTokens is
  Initializable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  IWhitelistedTokens
{
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  EnumerableSetUpgradeable.AddressSet private _tokenWhitelist;

  mapping(address => bytes) public tokenSwapPath;

  mapping(address => bytes) public tokenSwapReversePath;

  // EVENTS

  event TokenWhitelistedSet(address token, bool whitelisted);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  function addTokensToWhitelist(
    address[] memory tokens,
    bytes[] memory swapPaths,
    bytes[] memory swapReversePaths
  ) external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      require(_tokenWhitelist.add(tokens[i]), ExceptionsLibrary.ALREADY_WHITELISTED);

      tokenSwapPath[tokens[i]] = swapPaths[i];
      tokenSwapReversePath[tokens[i]] = swapReversePaths[i];

      emit TokenWhitelistedSet(tokens[i], true);
    }
  }

  function removeTokensFromWhitelist(address[] memory tokens)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < tokens.length; i++) {
      require(_tokenWhitelist.remove(tokens[i]), ExceptionsLibrary.ALREADY_NOT_WHITELISTED);

      emit TokenWhitelistedSet(tokens[i], false);
    }
  }

  function tokenWhitelist() external view returns (address[] memory) {
    return _tokenWhitelist.values();
  }

  function isTokenWhitelisted(address token)
    external
    view
    override
    returns (bool)
  {
    return _tokenWhitelist.contains(token);
  }
}
