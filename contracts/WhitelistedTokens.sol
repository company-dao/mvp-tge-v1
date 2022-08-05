// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IService.sol";
import "./interfaces/IWhitelistedTokens.sol";

contract WhitelistedTokens is IWhitelistedTokens, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _tokenWhitelist;

    mapping(address => bytes) public tokenSwapPath;

    mapping(address => bytes) public tokenSwapReversePath;

    event TokenWhitelistedSet(address token, bool whitelisted);

    function addTokensToWhitelist(
        address[] memory tokens,
        bytes[] memory swapPaths,
        bytes[] memory swapReversePaths
    ) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            require(_tokenWhitelist.add(tokens[i]), "Already whitelisted");
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
            require(
                _tokenWhitelist.remove(tokens[i]),
                "Already not whitelisted"
            );
            emit TokenWhitelistedSet(tokens[i], false);
        }
    }

    function tokenWhitelist()
        external
        view
        returns (address[] memory)
    {
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