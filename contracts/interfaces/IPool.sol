// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IService.sol";
import "./ITGE.sol";
import "./IGovernanceToken.sol";

interface IPool {
    function initialize(
        address poolCreator_, 
        uint256 jurisdiction_, 
        string memory poolEIN_, 
        string memory dateOfIncorporation, 
        string memory legalAddress, 
        string memory taxationStatus, 
        string memory registeredName, 
        uint256 ballotQuorumThreshold_, 
        uint256 ballotDecisionThreshold_, 
        uint256 ballotLifespan_, 
        string memory trademark
    ) external;

    function setToken(address token_) external;

    function setTGE(address tge_) external;

    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_, 
        uint256 ballotDecisionThreshold_, 
        uint256 ballotLifespan_
    ) external;

    function proposeSingleAction(
        address target,
        uint256 value,
        bytes memory cd,
        string memory description
    ) external returns (uint256 proposalId);

    function getTVL() external returns (uint256);

    function owner() external view returns (address);

    function service() external view returns (IService);

    function token() external view returns (IGovernanceToken);

    function tge() external view returns (ITGE);

    function getPoolTrademark() external view returns (string memory);
}
