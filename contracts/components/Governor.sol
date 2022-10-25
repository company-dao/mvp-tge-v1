// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/gnosis/IGnosisGovernance.sol";

abstract contract Governor {
    struct Proposal {
        uint256 ballotQuorumThreshold;
        uint256 ballotDecisionThreshold;
        address target;
        uint256 value;
        bytes callData;
        uint256 startBlock;
        uint256 endBlock; // startBlock + ballotLifespan
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        ProposalExecutionState state;
        string description;
        uint256 totalSupply;
    }

    mapping(uint256 => Proposal) private _proposals;

    mapping(address => mapping(uint256 => uint256)) private _forVotes;
    mapping(address => mapping(uint256 => uint256)) private _againstVotes;

    uint256 public lastProposalId;

    enum ProposalState {
        None,
        Active,
        Failed,
        Successful,
        Executed
    }

    enum ProposalExecutionState {
        Initialized,
        Rejected,
        Accomplished
    }

    // EVENTS

    event ProposalCreated(
        uint256 proposalId,
        uint256 quorum,
        address targets,
        uint256 values,
        bytes calldatas,
        string description
    );

    event VoteCast(
        address voter,
        uint256 proposalId,
        uint256 votes,
        bool support
    );

    event ProposalExecuted(uint256 proposalId);

    // PUBLIC VIEW FUNCTIONS

    function proposalState(uint256 proposalId)
        public
        view
        returns (ProposalState)
    {
        Proposal memory proposal = _proposals[proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (proposal.startBlock == 0) {
            return ProposalState.None;
        }

        uint256 totalAvailableVotes = _getTotalSupply() -
            _getTotalTGELockedTokens();
        uint256 quorumVotes = (totalAvailableVotes *
            proposal.ballotQuorumThreshold);
        uint256 totalCastVotes = proposal.forVotes + proposal.againstVotes;

        if (
            totalCastVotes * 10000 >= quorumVotes && // /10000 because 10000 = 100%
            proposal.forVotes * 10000 >
            totalCastVotes * proposal.ballotDecisionThreshold // * 10000 because 10000 = 100%
        ) {
            return ProposalState.Successful;
        }
        if (
            (totalAvailableVotes - proposal.againstVotes) * 10000 <=
            totalAvailableVotes * proposal.ballotDecisionThreshold
        ) {
            return ProposalState.Failed;
        }
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        if (block.number > proposal.endBlock) {
            if (
                totalVotes >= quorumVotes &&
                proposal.forVotes * 10000 >
                totalVotes * proposal.ballotDecisionThreshold
            ) {
                return ProposalState.Successful;
            } else return ProposalState.Failed;
        }
        return ProposalState.Active;
    }

    function getProposalBallotQuorumThreshold(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _proposals[proposalId].ballotQuorumThreshold;
    }

    function getProposalBallotDecisionThreshold(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _proposals[proposalId].ballotDecisionThreshold;
    }

    function getProposalBallotLifespan(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return
            _proposals[proposalId].endBlock - _proposals[proposalId].startBlock;
    }

    function getProposal(uint256 proposalId)
        public
        view
        returns (Proposal memory)
    {
        return _proposals[proposalId];
    }

    function getForVotes(address user, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _forVotes[user][proposalId];
    }

    function getAgainstVotes(address user, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _againstVotes[user][proposalId];
    }

    // INTERNAL FUNCTIONS

    function _propose(
        uint256 ballotLifespan,
        uint256 ballotQuorumThreshold,
        uint256 ballotDecisionThreshold,
        address target,
        uint256 value,
        bytes memory callData,
        string memory description, 
        uint256 totalSupply
    ) internal returns (uint256 proposalId) {
        proposalId = ++lastProposalId;
        _proposals[proposalId] = Proposal({
            ballotQuorumThreshold: ballotQuorumThreshold,
            ballotDecisionThreshold: ballotDecisionThreshold,
            target: target,
            value: value,
            callData: callData,
            startBlock: block.number,
            endBlock: block.number + ballotLifespan,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            state: ProposalExecutionState.Initialized,
            description: description,
            totalSupply: totalSupply
        });
        _afterProposalCreated(proposalId);

        emit ProposalCreated(
            proposalId,
            ballotQuorumThreshold,
            target,
            value,
            callData,
            description
        );
    }

    function _castVote(
        uint256 proposalId,
        uint256 votes,
        bool support
    ) internal {
        require(
            _proposals[proposalId].endBlock > block.number,
            ExceptionsLibrary.VOTING_FINISHED
        );

        if (support) {
            _proposals[proposalId].forVotes += votes;
            _forVotes[msg.sender][proposalId] += votes;
        } else {
            _proposals[proposalId].againstVotes += votes;
            _againstVotes[msg.sender][proposalId] += votes;
        }

        emit VoteCast(msg.sender, proposalId, votes, support);
    }

    function _executeBallot(uint256 proposalId, address gnosisGovernance)
        internal
    {
        Proposal memory proposal = _proposals[proposalId];

        require(
            proposalState(proposalId) == ProposalState.Successful,
            ExceptionsLibrary.WRONG_STATE
        );
        require(
            _proposals[proposalId].state == ProposalExecutionState.Initialized,
            ExceptionsLibrary.ALREADY_EXECUTED
        );
        _proposals[proposalId].executed = true;

        /*
        string memory errorMessage = "Call reverted without message";
        (bool success, bytes memory returndata) = proposal.target.call{
            value: proposal.value
        }(proposal.callData);
        */
        bool success = true;

        IGnosisGovernance(gnosisGovernance).executeTransfer(
            address(0),
            proposal.target,
            proposal.value
        );

        // AddressUpgradeable.verifyCallResult(
        //     success,
        //     returndata,
        //     errorMessage
        // );

        // require(success, "Invalid execution result");

        if (success) {
            _proposals[proposalId].state = ProposalExecutionState.Accomplished;
        } else {
            _proposals[proposalId].state = ProposalExecutionState.Rejected;
        }

        emit ProposalExecuted(proposalId);
    }

    function _afterProposalCreated(uint256 proposalId) internal virtual;

    function _getTotalSupply() internal view virtual returns (uint256);

    function _getTotalTGELockedTokens() internal view virtual returns (uint256);
}
