// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IService.sol";
import "./ITGE.sol";
import "./IGovernanceToken.sol";

interface IPool {
    function initialize(address owner_) external;

    function setToken(address token_) external;

    function setTGE(address tge_) external;

    function setCompanyDomain(string memory companyDomain_) external;

    function setBallotParams(
        uint256 ballotQuorumThreshold_, 
        uint256 ballotDecisionThreshold_, 
        uint256 ballotLifespan_
    ) external;

    function proposeSingleAction(
        uint256 duration,
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
}
