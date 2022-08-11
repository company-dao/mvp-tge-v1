// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

abstract contract Governor {
    struct Proposal {
        uint256 ballotQuorumThreshold;
        uint256 ballotDecisionThreshold;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock; // startBlock + ballotLifespan
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool accepted;
        ProposalExecutionState state;
        string description;
    }

    mapping(uint256 => Proposal) public proposals;

    uint256 public lastProposalId;

    enum ProposalState {
        None,
        Active,
        Failed,
        Successful,
        Executed
    }

    enum ProposalExecutionState {
        Rejected,
        Accomplished
    }

    // EVENTS

    event ProposalCreated(
        uint256 proposalId,
        uint256 quorum,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        string description
    );

    event VoteCast(
        address voter,
        uint256 proposalId,
        uint256 votes,
        bool support
    );

    event ProposalExecuted(uint256 proposalId);

    // PUBLIC FUNCTIONS

    function executeBallot(uint256 proposalId) external {
        Proposal memory proposal = proposals[proposalId];

        proposals[proposalId].executed = true;
        require(
            proposalState(proposalId) == ProposalState.Successful,
            "Proposal is in wrong state"
        );

        proposals[proposalId].accepted = true;

        string memory errorMessage = "Call reverted without message";
        for (uint256 i = 0; i < proposal.targets.length; ++i) {
            (bool success, bytes memory returndata) = proposal.targets[i].call{
                value: proposal.values[i]
            }(proposal.calldatas[i]);
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                errorMessage
            );
        }
        proposals[proposalId].state = ProposalExecutionState.Accomplished;

        emit ProposalExecuted(proposalId);
    }

    // PUBLIC VIEW FUNCTIONS

    function proposalState(uint256 proposalId)
        public
        view
        returns (ProposalState)
    {
        Proposal memory proposal = proposals[proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (proposal.startBlock == 0) {
            return ProposalState.None;
        }
        if (proposal.endBlock > block.number) {
            return ProposalState.Active;
        }

        uint256 quorumVotes = (_getTotalVotes() * proposal.ballotQuorumThreshold) / 10000; // / 10000 because 10000 = 100% 
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        if (
            totalVotes >= quorumVotes &&
            proposal.forVotes * 10000 > totalVotes * proposal.ballotDecisionThreshold // * 10000 because 10000 = 100% 
        ) {
            return ProposalState.Successful;
        } else {
            return ProposalState.Failed;
        }
    }

    function getProposalBallotQuorumThreshold(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return proposals[proposalId].ballotQuorumThreshold;
    }

    function getProposalBallotDecisionThreshold(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return proposals[proposalId].ballotDecisionThreshold;
    }

    function getProposalBallotLifespan(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return proposals[proposalId].endBlock - proposals[proposalId].startBlock;
    }

    function getProposal(uint256 proposalId) public view returns (Proposal memory) {
        return proposals[proposalId];
    }

    // INTERNAL FUNCTIONS

    function _propose(
        uint256 ballotLifespan, 
        uint256 ballotQuorumThreshold, 
        uint256 ballotDecisionThreshold, 
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) internal returns (uint256 proposalId) {
        require(
            proposals[lastProposalId].endBlock <= block.number,
            "Already has active proposal"
        );

        proposalId = ++lastProposalId;
        proposals[proposalId] = Proposal({
            ballotQuorumThreshold: ballotQuorumThreshold,
            ballotDecisionThreshold: ballotDecisionThreshold,
            targets: targets,
            values: values,
            calldatas: calldatas,
            startBlock: block.number,
            endBlock: block.number + ballotLifespan,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            accepted: false,
            state: ProposalExecutionState.Rejected,
            description: description
        });
        _afterProposalCreated(proposalId);

        emit ProposalCreated(
            proposalId,
            ballotQuorumThreshold,
            targets,
            values,
            calldatas,
            description
        );
    }

    function _castVote(
        uint256 proposalId,
        uint256 votes,
        bool support
    ) internal {
        require(
            proposals[proposalId].endBlock > block.number,
            "Voting finished"
        );

        if (support) {
            proposals[proposalId].forVotes += votes;
        } else {
            proposals[proposalId].againstVotes += votes;
        }

        emit VoteCast(msg.sender, proposalId, votes, support);
    }

    function _afterProposalCreated(uint256 proposalId) internal virtual;

    function _getTotalVotes() internal view virtual returns (uint256);
}
