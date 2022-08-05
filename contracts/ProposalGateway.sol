// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IService.sol";

contract ProposalGateway is OwnableUpgradeable {
    // INITIALIZER

    function initialize() external initializer {
        __Ownable_init();
    }

    // PROPOSAL FUNCTIONS

    function createTransferETHProposal(
        IPool pool,
        address to,
        uint256 value,
        string memory description
    ) external onlyPoolShareholder(pool) returns (uint256 proposalId) {
        proposalId = pool.proposeSingleAction(
            to,
            value,
            "",
            description
        );
    }

    function createTransferERC20Proposal(
        IPool pool,
        address token,
        address to,
        uint256 value,
        string memory description
    ) external onlyPoolShareholder(pool) returns (uint256 proposalId) {
        proposalId = pool.proposeSingleAction(
            token,
            0,
            abi.encodeWithSelector(
                IERC20Upgradeable.transfer.selector,
                to,
                value
            ),
            description
        );
    }

    function createTGEProposal(
        IPool pool,
        ITGE.TGEInfo memory info,
        string memory description
    ) external onlyPoolShareholder(pool) returns (uint256 proposalId) {
        proposalId = pool.proposeSingleAction(
            address(pool.service()),
            0,
            abi.encodeWithSelector(IService.createSecondaryTGE.selector, info),
            description
        );
    }

    function createGovernanceSettingsProposal(
        IPool pool,
        uint256 ballotQuorumThreshold, 
        uint256 ballotDecisionThreshold, 
        uint256 ballotLifespan,
        string memory description
    ) external onlyPoolShareholder(pool) returns (uint256 proposalId) {
        proposalId = pool.proposeSingleAction(
            address(pool),
            0,
            abi.encodeWithSelector(
                IPool.setGovernanceSettings.selector,
                ballotQuorumThreshold,
                ballotDecisionThreshold,
                ballotLifespan
            ),
            description
        );
    }

    // MODIFIERS

    modifier onlyPoolShareholder(IPool pool) {
        require(pool.token().balanceOf(msg.sender) > 0, "Not shareholder");
        _;
    }
}
