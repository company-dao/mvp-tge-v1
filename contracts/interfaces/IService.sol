// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./IDirectory.sol";
import "./ITGE.sol";
import "./IMetadata.sol";
import "./IWhitelistedTokens.sol";

interface IService {
    function createSecondaryTGE(ITGE.TGEInfo memory tgeInfo) external;

    function addProposal(uint256 proposalId) external;

    function directory() external view returns (IDirectory);

    // function isTokenWhitelisted(address token) external view returns (bool);

    function tokenWhitelist() external view returns (address[] memory);

    function owner() external view returns (address);

    function proposalGateway() external view returns (address);

    function proposalQuorum() external view returns (uint256);

    function proposalThreshold() external view returns (uint256);

    function uniswapRouter() external view returns (ISwapRouter);

    function uniswapQuoter() external view returns (IQuoter);

    function whitelistedTokens() external view returns (IWhitelistedTokens);

    function metadata() external view returns (IMetadata);

    // function tokenSwapPath(address) external view returns (bytes memory);

    // function tokenSwapReversePath(address) external view returns (bytes memory);
}
