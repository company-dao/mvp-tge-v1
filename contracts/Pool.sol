// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Governor.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";

contract Pool is IPool, OwnableUpgradeable, Governor {
    IService public service;

    IGovernanceToken public token;

    ITGE public tge;

    // INITIALIZER AND CONFIGURATOR

    function initialize(address owner_) external initializer {
        service = IService(msg.sender);
        _transferOwnership(owner_);
    }

    function setToken(address token_) external onlyService {
        token = IGovernanceToken(token_);
    }

    function setTGE(address tge_) external onlyService {
        tge = ITGE(tge_);
    }

    // PUBLIC FUNCTIONS

    function createTransferETHProposal(
        uint256 duration,
        uint256 quorum,
        address to,
        uint256 value,
        string memory description
    ) external onlyShareholder returns (uint256 proposalId) {
        proposalId = _proposeSingleAction(
            duration,
            quorum,
            to,
            value,
            "",
            description
        );
    }

    function createTGEProposal(
        uint256 duration,
        uint256 quorum,
        ITGE.TGEInfo memory info,
        string memory description
    ) external onlyShareholder returns (uint256 proposalId) {
        proposalId = _proposeSingleAction(
            duration,
            quorum,
            address(service),
            0,
            abi.encodeWithSelector(IService.createSecondaryTGE.selector, info),
            description
        );
    }

    function castVote(uint256 proposalId) external {
        uint256 votes = token.unlockedBalanceOf(msg.sender);
        require(votes > 0, "No votes");
        token.lock(msg.sender, votes, proposals[proposalId].endBlock);
        _castVote(proposalId, votes);
    }

    // PUBLIC VIEW FUNCTIONS

    function owner()
        public
        view
        override(IPool, OwnableUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    // INTERNAL FUNCTIONS

    function _proposeSingleAction(
        uint256 duration,
        uint256 quorum,
        address target,
        uint256 value,
        bytes memory cd,
        string memory description
    ) internal returns (uint256 proposalId) {
        // TODO: check that there are no active TGE's

        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory values = new uint256[](1);
        values[0] = value;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = cd;
        proposalId = _propose(
            duration,
            quorum,
            targets,
            values,
            calldatas,
            description
        );
    }

    function _afterProposalCreated(uint256 proposalId) internal override {
        service.addProposal(proposalId);
    }

    // MODIFIER

    modifier onlyShareholder() {
        require(token.balanceOf(msg.sender) > 0, "Not shareholder");
        _;
    }

    modifier onlyService() {
        require(msg.sender == address(service), "Not service");
        _;
    }
}
