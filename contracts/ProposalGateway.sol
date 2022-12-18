// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IService.sol";
import "./interfaces/IDispatcher.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IToken.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Protocol entry point to create any proposal
contract ProposalGateway is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    address public dispatcher;
    // INITIALIZER

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address dispatcher_) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        require(dispatcher_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        dispatcher = dispatcher_;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}


    /**
     * @dev Create TransferETH proposal
     * @param pool Pool address
     * @param recipients Transfer recipients
     * @param values Token amounts
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function createTransferETHProposal(
        IPool pool,
        address[] memory recipients,
        uint256[] memory values,
        string memory description,
        string memory metaHash
    ) external onlyPoolShareholder(pool) returns (uint256 proposalId) {
        require(recipients.length == values.length, ExceptionsLibrary.INVALID_VALUE);

        proposalId = pool.proposeTransfer(
            recipients,
            values,
            description,
            IDispatcher.ProposalType.TransferETH,
            metaHash,
            address(0)
        );
        pool.setLastProposalIdForAccount(msg.sender, proposalId);
    }

    /**
     * @dev Create TransferERC20 proposal
     * @param pool Pool address
     * @param token Token to transfer
     * @param recipients Transfer recipients
     * @param values Token amounts
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function createTransferERC20Proposal(
        IPool pool,
        address token,
        address[] memory recipients,
        uint256[] memory values,
        string memory description,
        string memory metaHash
    ) external onlyPoolShareholder(pool) returns (uint256 proposalId) {
        require(recipients.length == values.length, ExceptionsLibrary.INVALID_VALUE);

        proposalId = pool.proposeTransfer(
            recipients,
            values,
            description,
            IDispatcher.ProposalType.TransferERC20,
            metaHash,
            token
        );
        pool.setLastProposalIdForAccount(msg.sender, proposalId);
    }

    /**
     * @dev Create TGE proposal
     * @param pool Pool address
     * @param info TGE parameters
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @param tokenType Token type
     * @param preferenceTokenDescription Description for preference token
     * @param preferenceTokenCap Preference token cap
     * @return proposalId Created proposal's ID
     */
    function createTGEProposal(
        IPool pool,
        ITGE.TGEInfo calldata info,
        string calldata description,
        string calldata metaHash,
        string memory metadataURI,
        IToken.TokenType tokenType,
        string memory preferenceTokenDescription,
        uint256 preferenceTokenCap
    ) external onlyPoolShareholder(pool) returns (uint256 proposalId) {
        // IDispatcher(dispatcher).validateTGEInfo(info, pool.token());
        // if (tokenType == IToken.TokenType.Preference) {
        //     require(
        //         !pool.preferenceToken().isPrimaryTGESuccessful(), 
        //         ExceptionsLibrary.ACTIVE_TGE_EXISTS // probably rename
        //     );
        // }

        proposalId = pool.proposeSingleAction(
            address(pool.service()),
            0,
            abi.encodeWithSelector(
                IService.createSecondaryTGE.selector, 
                info, 
                metadataURI, 
                tokenType, 
                preferenceTokenDescription,
                preferenceTokenCap
            ),
            description,
            IDispatcher.ProposalType.TGE,
            metaHash
        );
        pool.setLastProposalIdForAccount(msg.sender, proposalId);
    }

    /**
     * @dev Create GovernanceSettings proposal
     * @param pool Pool address
     * @param ballotQuorumThreshold Ballot quorum threshold
     * @param ballotDecisionThreshold Ballot decision threshold
     * @param ballotLifespan Ballot lifespan
     * @param ballotExecDelay Ballot execution delay parameters
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function createGovernanceSettingsProposal(
        IPool pool,
        uint256 ballotQuorumThreshold,
        uint256 ballotDecisionThreshold,
        uint256 ballotLifespan,
        uint256[10] calldata ballotExecDelay,
        string calldata description,
        string calldata metaHash
    ) external onlyPoolShareholder(pool) returns (uint256 proposalId) {
        IDispatcher(dispatcher).validateBallotParams(
            ballotQuorumThreshold,
            ballotDecisionThreshold, 
            ballotLifespan,
            ballotExecDelay
        );

        proposalId = pool.proposeSingleAction(
            address(pool),
            0,
            abi.encodeWithSelector(
                IPool.setGovernanceSettings.selector,
                ballotQuorumThreshold,
                ballotDecisionThreshold,
                ballotLifespan,
                ballotExecDelay
            ),
            description,
            IDispatcher.ProposalType.GovernanceSettings,
            metaHash
        );
        pool.setLastProposalIdForAccount(msg.sender, proposalId);
    }

    modifier onlyPoolShareholder(IPool pool) {
        require(
            pool.governanceToken().balanceOf(msg.sender) > 0,
            ExceptionsLibrary.NOT_SHAREHOLDER
        );
        require(pool.isDAO(), ExceptionsLibrary.NOT_DAO);
        _;
    }

}