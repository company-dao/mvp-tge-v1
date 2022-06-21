// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

abstract contract Governor {
    struct Proposal {
        uint256 quorum;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;

    uint256 public lastProposalId;

    enum ProposalState {
        Active,
        Successful,
        Executed
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

    event VoteCast(address voter, uint256 proposalId, uint256 votes);

    event ProposalExecuted(uint256 proposalId);

    // PUBLIC FUNCTIONS

    function execute(uint256 proposalId) external {
        Proposal memory proposal = proposals[proposalId];

        require(
            proposalState(proposalId) == ProposalState.Successful,
            "Proposal is in wrong state"
        );

        proposals[proposalId].executed = true;

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
        } else if (
            proposal.startBlock != 0 &&
            proposal.endBlock <= block.number &&
            proposal.forVotes >= proposal.quorum
        ) {
            return ProposalState.Successful;
        } else {
            return ProposalState.Active;
        }
    }

    // INTERNAL FUNCTIONS

    function _propose(
        uint256 duration,
        uint256 quorum,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) internal returns (uint256 proposalId) {
        require(
            proposals[lastProposalId].endBlock <= block.number,
            "Already has active proposal"
        );
        // Temporarily disabled as arbitrary proposals are not supported in this version
        /*
        require(
            targets.length == values.length &&
                values.length == calldatas.length,
            "Lengths mismatch"
        );
        require(targets.length > 0, "Empty proposal");
        */

        proposalId = ++lastProposalId;
        proposals[proposalId] = Proposal({
            quorum: quorum,
            targets: targets,
            values: values,
            calldatas: calldatas,
            startBlock: block.number,
            endBlock: block.number + duration,
            forVotes: 0,
            executed: false
        });
        _afterProposalCreated(proposalId);

        emit ProposalCreated(
            proposalId,
            quorum,
            targets,
            values,
            calldatas,
            description
        );
    }

    function _castVote(uint256 proposalId, uint256 votes) internal {
        require(
            proposals[proposalId].endBlock > block.number,
            "Voting finished"
        );

        proposals[proposalId].forVotes += votes;

        emit VoteCast(msg.sender, proposalId, votes);
    }

    function _afterProposalCreated(uint256 proposalId) internal virtual;
}
