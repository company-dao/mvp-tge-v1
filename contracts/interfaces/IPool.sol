// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./ITGE.sol";
import "./IGovernanceToken.sol";

interface IPool {
    function initialize(address owner_) external;

    function setToken(address token_) external;

    function setTGE(address tge_) external;

    function owner() external view returns (address);

    function token() external view returns (IGovernanceToken);

    function tge() external view returns (ITGE);
}
