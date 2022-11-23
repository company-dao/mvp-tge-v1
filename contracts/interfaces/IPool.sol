// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IService.sol";
import "./ITGE.sol";
import "./IGovernanceToken.sol";
import "./IProposalGateway.sol";

interface IPool {
    function initialize(
        address poolCreator_,
        uint256 jurisdiction_,
        string memory poolEIN_,
        string memory dateOfIncorporation,
        uint256 entityType,
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] memory ballotExecDelay_,
        uint256 metadataIndex,
        string memory trademark
    ) external;

    function setToken(address token_) external;

    function setTGE(address tge_) external;

    function setPrimaryTGE(address tge_) external;

    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] calldata ballotExecDelay
    ) external;

    function proposeSingleAction(
        address target,
        uint256 value,
        bytes memory cd,
        string memory description,
        IProposalGateway.ProposalType proposalType,
        string memory metaHash
    ) external returns (uint256 proposalId);

    function proposeTransfer(
        address[] memory targets,
        uint256[] memory values,
        string memory description,
        IProposalGateway.ProposalType proposalType,
        string memory metaHash,
        address token_
    ) external returns (uint256 proposalId);

    function serviceCancelBallot(uint256 proposalId) external;

    function getTVL() external returns (uint256);

    function owner() external view returns (address);

    function service() external view returns (IService);

    function token() external view returns (IGovernanceToken);

    function tge() external view returns (ITGE);

    function maxProposalId() external view returns (uint256);

    function isDAO() external view returns (bool);

    function getPoolTrademark() external view returns (string memory);

    function addTGE(address tge_) external;

    function getProposalType(uint256 proposalId)
        external
        view
        returns (IProposalGateway.ProposalType);

    function ballotExecDelay(uint256 _index) external view returns (uint256);
}
