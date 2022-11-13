// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IService.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IProposalGateway.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Protocol entry point to create any proposal
contract ProposalGateway is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // INITIALIZER

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // PROPOSAL FUNCTIONS

    /**
     * @dev Create TransferETH proposal
     * @param pool Pool address
     * @param to Transfer recipient
     * @param value Token amount
     * @param description Proposal description
     * @return proposalId Created proposal's ID
     */
    function createTransferETHProposal(
        IPool pool,
        address to,
        uint256 value,
        string calldata description
    ) external onlyPoolShareholder(pool) returns (uint256 proposalId) {
        proposalId = pool.proposeSingleAction(
            to,
            value,
            "",
            description,
            IProposalGateway.ProposalType.TransferETH,
            0
        );
    }

    /**
     * @dev Create TransferERC20 proposal
     * @param pool Pool address
     * @param token Token to be transfered
     * @param to Transfer recipient
     * @param value Token amount
     * @param description Proposal description
     * @return proposalId Created proposal's ID
     */
    function createTransferERC20Proposal(
        IPool pool,
        address token,
        address to,
        uint256 value,
        string calldata description
    ) external onlyPoolShareholder(pool) returns (uint256 proposalId) {
        proposalId = pool.proposeSingleAction(
            token,
            0,
            abi.encodeWithSelector(
                IERC20Upgradeable.transfer.selector,
                to,
                value
            ),
            description,
            IProposalGateway.ProposalType.TransferERC20,
            value
        );
    }

    /**
     * @dev Create TGE proposal
     * @param pool Pool address
     * @param info TGE parameters
     * @param description Proposal description
     * @return proposalId Created proposal's ID
     */
    function createTGEProposal(
        IPool pool,
        ITGE.TGEInfo calldata info,
        string calldata description
    ) external onlyPoolShareholder(pool) returns (uint256 proposalId) {
        proposalId = pool.proposeSingleAction(
            address(pool.service()),
            0,
            abi.encodeWithSelector(IService.createSecondaryTGE.selector, info),
            description,
            IProposalGateway.ProposalType.TGE,
            0
        );
    }

    /**
     * @dev Create GovernanceSettings proposal
     * @param pool Pool address
     * @param ballotQuorumThreshold Ballot quorum threshold
     * @param ballotDecisionThreshold Ballot decision threshold
     * @param ballotLifespan Ballot lifespan
     * @param description Proposal description
     * @param ballotExecDelay_ Ballot execution delay parameters
     * @return proposalId Created proposal's ID
     */
    function createGovernanceSettingsProposal(
        IPool pool,
        uint256 ballotQuorumThreshold,
        uint256 ballotDecisionThreshold,
        uint256 ballotLifespan,
        string calldata description,
        uint256[10] calldata ballotExecDelay_
    ) external onlyPoolShareholder(pool) returns (uint256 proposalId) {
        proposalId = pool.proposeSingleAction(
            address(pool),
            0,
            abi.encodeWithSelector(
                IPool.setGovernanceSettings.selector,
                ballotQuorumThreshold,
                ballotDecisionThreshold,
                ballotLifespan,
                ballotExecDelay_
            ),
            description,
            IProposalGateway.ProposalType.GovernanceSettings,
            0
        );
    }

    // MODIFIERS

    modifier onlyPoolShareholder(IPool pool) {
        require(
            pool.token().balanceOf(msg.sender) > 0,
            ExceptionsLibrary.NOT_SHAREHOLDER
        );
        require(pool.isDAO(), ExceptionsLibrary.NOT_DAO);
        _;
    }

    function test82312() external pure returns (uint256) {
        return 3;
    }
}
