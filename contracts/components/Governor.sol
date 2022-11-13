// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/IService.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IDirectory.sol";
import "../interfaces/IProposalGateway.sol";

/// @dev Proposal module for Pool's Governance Token
abstract contract Governor {
    /**
     * @dev Proposal structure
     * @param ballotQuorumThreshold Ballot quorum threshold
     * @param ballotDecisionThreshold Ballot decision threshold
     * @param target Target
     * @param value ETH value
     * @param callData Call data to pass in .call() to target
     * @param startBlock Start block
     * @param endBlock End block
     * @param forVotes For votes
     * @param againstVotes Against votes
     * @param executed Is executed
     * @param state Proposal state
     * @param description Description
     * @param totalSupply Total supply
     * @param lastVoteBlock Block when last vote was cast
     * @param proposalType Proposal type
     * @param execDelay Execution delay for the proposal, blocks
     * @param amountERC20 Amount of ERC20 tokens
     */
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
        uint256 lastVoteBlock;
        IProposalGateway.ProposalType proposalType;
        uint256 execDelay;
        uint256 amountERC20;
    }

    /// @dev Proposals
    mapping(uint256 => Proposal) private _proposals;

    /// @dev For votes
    mapping(address => mapping(uint256 => uint256)) private _forVotes;

    /// @dev Against votes
    mapping(address => mapping(uint256 => uint256)) private _againstVotes;

    /// @dev Last proposal ID
    uint256 public lastProposalId;

    /// @dev Proposal statte
    enum ProposalState {
        None,
        Active,
        Failed,
        Successful,
        Executed,
        Cancelled
    }

    /// @dev Proposal execution state
    enum ProposalExecutionState {
        Initialized,
        Rejected,
        Accomplished,
        Cancelled
    }

    // EVENTS

    /**
     * @dev Event emitted on proposal creation
     * @param proposalId Proposal ID
     * @param quorum Quorum
     * @param targets Targets
     * @param values Values
     * @param calldatas Calldata
     * @param description Description
     */
    event ProposalCreated(
        uint256 proposalId,
        uint256 quorum,
        address targets,
        uint256 values,
        bytes calldatas,
        string description
    );

    /**
     * @dev Event emitted on proposal vote cast
     * @param voter Voter address
     * @param proposalId Proposal ID
     * @param votes Amount of votes
     * @param support Against or for
     */
    event VoteCast(
        address voter,
        uint256 proposalId,
        uint256 votes,
        bool support
    );

    /**
     * @dev Event emitted on proposal execution
     * @param proposalId Proposal ID
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Event emitted on proposal cancellation
     * @param proposalId Proposal ID
     */
    event ProposalCancelled(uint256 proposalId);

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Return proposal state
     * @param proposalId Proposal ID
     * @return ProposalState
     */
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

        if (proposal.state == ProposalExecutionState.Cancelled) {
            return ProposalState.Cancelled;
        }

        uint256 totalAvailableVotes = _getTotalSupply() -
            _getTotalTGELockedTokens();
        uint256 quorumVotes = (totalAvailableVotes *
            proposal.ballotQuorumThreshold);
        uint256 totalCastVotes = proposal.forVotes + proposal.againstVotes;

        if (
            totalCastVotes * 10000 >= quorumVotes && // /10000 because 10000 = 100%
            proposal.forVotes * 10000 >
            totalCastVotes * proposal.ballotDecisionThreshold && // * 10000 because 10000 = 100%
            proposal.forVotes >=
            totalAvailableVotes * proposal.ballotDecisionThreshold
        ) {
            return ProposalState.Successful;
        }
        if (
            totalCastVotes * 10000 >= quorumVotes && // /10000 because 10000 = 100%
            proposal.againstVotes * 10000 >
            totalCastVotes * proposal.ballotDecisionThreshold && // * 10000 because 10000 = 100%
            (totalAvailableVotes - proposal.againstVotes) * 10000 <
            totalAvailableVotes * proposal.ballotDecisionThreshold
        ) {
            return ProposalState.Failed;
        }

        if (block.number > proposal.endBlock) {
            if (
                totalCastVotes >= quorumVotes &&
                proposal.forVotes * 10000 >
                totalCastVotes * proposal.ballotDecisionThreshold
            ) {
                return ProposalState.Successful;
            } else return ProposalState.Failed;
        }
        return ProposalState.Active;
    }

    /**
     * @dev Return proposal quorum threshold
     * @param proposalId Proposal ID
     * @return Quorum threshold
     */
    function getProposalBallotQuorumThreshold(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _proposals[proposalId].ballotQuorumThreshold;
    }

    /**
     * @dev Return proposal decsision threshold
     * @param proposalId Proposal ID
     * @return Decision threshold
     */
    function getProposalBallotDecisionThreshold(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _proposals[proposalId].ballotDecisionThreshold;
    }

    /**
     * @dev Return proposal lifespan
     * @param proposalId Proposal ID
     * @return Lifespan
     */
    function getProposalBallotLifespan(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return
            _proposals[proposalId].endBlock - _proposals[proposalId].startBlock;
    }

    /**
     * @dev Return proposal
     * @param proposalId Proposal ID
     * @return Proposal
     */
    function getProposal(uint256 proposalId)
        public
        view
        returns (Proposal memory)
    {
        return _proposals[proposalId];
    }

    /**
     * @dev Return proposal for votes for a given user
     * @param user User address
     * @param proposalId Proposal ID
     * @return For votes
     */
    function getForVotes(address user, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _forVotes[user][proposalId];
    }

    /**
     * @dev Return proposal against votes for a given user
     * @param user User address
     * @param proposalId Proposal ID
     * @return Against votes
     */
    function getAgainstVotes(address user, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _againstVotes[user][proposalId];
    }

    /**
     * @dev Return proposal type
     * @param proposalId Proposal ID
     * @return Proposal type
     */
    function _getProposalType(uint256 proposalId)
        internal
        view
        returns (IProposalGateway.ProposalType)
    {
        return _proposals[proposalId].proposalType;
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Create proposal
     * @param ballotLifespan Ballot lifespan
     * @param ballotQuorumThreshold Ballot quorum threshold
     * @param ballotDecisionThreshold Ballot decision threshold
     * @param target Target
     * @param value Value
     * @param callData Calldata
     * @param description Description
     * @param totalSupply Total supply
     * @param execDelay Execution delay
     * @param proposalType Proposal type
     * @param amountERC20 Amount ERC20
     * @return proposalId Proposal ID
     */
    function _propose(
        uint256 ballotLifespan,
        uint256 ballotQuorumThreshold,
        uint256 ballotDecisionThreshold,
        address target,
        uint256 value,
        bytes calldata callData,
        string calldata description,
        uint256 totalSupply,
        uint256 execDelay,
        IProposalGateway.ProposalType proposalType,
        uint256 amountERC20
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
            totalSupply: totalSupply,
            lastVoteBlock: 0,
            proposalType: proposalType,
            execDelay: execDelay,
            amountERC20: amountERC20
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

    /**
     * @dev Cast vote for a proposal
     * @param proposalId Proposal ID
     * @param votes Amount of votes
     * @param support Against or for
     */
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

        _proposals[proposalId].lastVoteBlock = block.number;

        emit VoteCast(msg.sender, proposalId, votes, support);
    }

    /**
     * @dev Execute proposal
     * @param proposalId Proposal ID
     * @param service Service address
     * @param pool Pool address
     */
    function _executeBallot(
        uint256 proposalId,
        IService service,
        IPool pool
    ) internal {
        Proposal memory proposal = _proposals[proposalId];

        require(
            proposalState(proposalId) == ProposalState.Successful,
            ExceptionsLibrary.WRONG_STATE
        );
        require(
            _proposals[proposalId].state == ProposalExecutionState.Initialized,
            ExceptionsLibrary.ALREADY_EXECUTED
        );

        // Mitigate against FlashLoan attacks
        require(
            proposal.lastVoteBlock + proposal.execDelay <= block.number,
            ExceptionsLibrary.BLOCK_DELAY
        );

        // Give pool shareholders time to cancel bugged/hacked ballot execution
        require(
            isDelayCleared(pool, proposalId),
            ExceptionsLibrary.BLOCK_DELAY
        );

        _proposals[proposalId].executed = true;

        (bool success, bytes memory returndata) = proposal.target.call{
            value: proposal.value
        }(proposal.callData);

        if (
            proposal.proposalType == IProposalGateway.ProposalType.TransferETH
        ) {
            service.addEvent(
                IDirectory.EventType.TransferETH,
                proposalId,
                proposal.description
            );
        }

        if (
            proposal.proposalType == IProposalGateway.ProposalType.TransferERC20
        ) {
            service.addEvent(
                IDirectory.EventType.TransferERC20,
                proposalId,
                proposal.description
            );
        }

        if (proposal.proposalType == IProposalGateway.ProposalType.TGE) {
            service.addEvent(IDirectory.EventType.TGE, proposalId, "");
        }

        if (
            proposal.proposalType ==
            IProposalGateway.ProposalType.GovernanceSettings
        ) {
            service.addEvent(
                IDirectory.EventType.GovernanceSettings,
                proposalId,
                ""
            );
        }
        /*
        IGnosisGovernance(gnosisGovernance).executeTransfer(
            address(0),
            proposal.target,
            proposal.value
        );
        */

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

    /**
     * @dev Return: is proposal block delay cleared. Block delay is applied based on proposal type and pool governance settings.
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @return Is delay cleared
     */
    function isDelayCleared(IPool pool, uint256 proposalId)
        public
        returns (bool)
    {
        Proposal memory proposal = _proposals[proposalId];
        uint256 valueUSDT = 0;

        // proposal type based delay
        uint256 delay = pool.ballotExecDelay(
            uint256(proposal.proposalType) + 1
        );

        // delay for transfer type proposals
        if (
            proposal.proposalType ==
            IProposalGateway.ProposalType.TransferETH ||
            proposal.proposalType == IProposalGateway.ProposalType.TransferERC20
        ) {
            address from = pool.service().weth();
            uint256 amount = proposal.value;

            if (
                proposal.proposalType ==
                IProposalGateway.ProposalType.TransferERC20
            ) {
                from = proposal.target;
                amount = proposal.amountERC20;
            }

            // calculate USDT value of transfer tokens
            // Uniswap reverts if tokens are not supported.
            // In order to allow transfer of ERC20 tokens that are not supported on uniswap, we catch the revert
            // And allow the proposal token transfer to pass through
            // This is kinda vulnerable to Uniswap token/pool price/listing manipulation, perhaps this needs to be refactored some time later
            // In order to prevent executing proposals by temporary making token pair/pool not supported by uniswap (which would cause revert and allow proposal to be executed)
            try
                pool.service().uniswapQuoter().quoteExactInput(
                    abi.encodePacked(from, uint24(3000), pool.service().usdt()),
                    amount
                )
            returns (uint256 v) {
                valueUSDT = v;
            } catch (
                bytes memory /*lowLevelData*/
            ) {}

            if (
                valueUSDT >= pool.ballotExecDelay(0) &&
                block.number <= delay + proposal.lastVoteBlock
            ) {
                return false;
            }
        }

        // delay for non transfer type proposals
        if (
            proposal.proposalType == IProposalGateway.ProposalType.TGE ||
            proposal.proposalType ==
            IProposalGateway.ProposalType.GovernanceSettings
        ) {
            if (block.number <= delay + proposal.lastVoteBlock) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Cancel proposal
     * @param proposalId Proposal ID
     */
    function _cancelBallot(uint256 proposalId) internal {
        require(
            proposalState(proposalId) == ProposalState.Active ||
                proposalState(proposalId) == ProposalState.Successful,
            ExceptionsLibrary.WRONG_STATE
        );

        _proposals[proposalId].state = ProposalExecutionState.Cancelled;

        emit ProposalCancelled(proposalId);
    }

    function _afterProposalCreated(uint256 proposalId) internal virtual;

    function _getTotalSupply() internal view virtual returns (uint256);

    function _getTotalTGELockedTokens() internal view virtual returns (uint256);
}
