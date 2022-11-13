// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IWhitelistedTokens.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @title List of tokens allowed in TGE
contract WhitelistedTokens is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IWhitelistedTokens
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev Token whitelist
     */
    EnumerableSetUpgradeable.AddressSet private _tokenWhitelist;

    /**
     * @dev Uniswap token swap path
     */
    mapping(address => bytes) public tokenSwapPath;

    /**
     * @dev Uniswap reverse swap path
     */
    mapping(address => bytes) public tokenSwapReversePath;

    // EVENTS

    /**
     * @dev Event emitted on change in token's whitelist status
     * @param token Token
     * @param whitelisted Is whitelisted
     */
    event TokenWhitelistedSet(address token, bool whitelisted);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once
     */
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * @dev Add tokens to whitelist
     * @param tokens Tokens
     * @param swapPaths Token swap paths
     * @param swapReversePaths Reverse swap paths
     */
    function addTokensToWhitelist(
        address[] calldata tokens,
        bytes[] calldata swapPaths,
        bytes[] calldata swapReversePaths
    ) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                _tokenWhitelist.add(tokens[i]),
                ExceptionsLibrary.ALREADY_WHITELISTED
            );

            tokenSwapPath[tokens[i]] = swapPaths[i];
            tokenSwapReversePath[tokens[i]] = swapReversePaths[i];

            emit TokenWhitelistedSet(tokens[i], true);
        }
    }

    /**
     * @dev Remove tokens from whitelist
     * @param tokens Tokens
     */
    function removeTokensFromWhitelist(address[] calldata tokens)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                _tokenWhitelist.remove(tokens[i]),
                ExceptionsLibrary.ALREADY_NOT_WHITELISTED
            );

            emit TokenWhitelistedSet(tokens[i], false);
        }
    }

    /**
     * @dev Return whitelisted tokens
     * @return Addresses of whitelisted tokens
     */
    function tokenWhitelist() external view returns (address[] memory) {
        return _tokenWhitelist.values();
    }

    /**
     * @dev Check if token is whitelisted
     * @param token Token
     * @return Is token whitelisted
     */
    function isTokenWhitelisted(address token)
        external
        view
        override
        returns (bool)
    {
        return _tokenWhitelist.contains(token);
    }

    function test83212() external pure returns (uint256) {
        return 3;
    }
}
