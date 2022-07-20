// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./components/Governor.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";

contract Pool is IPool, OwnableUpgradeable, Governor {
    IService public service;

    IGovernanceToken public token;

    ITGE public tge;

    string public companyId;

    string public companyDomain;

    uint256 public ballotQuorumThreshold;

    uint256 public ballotDecisionThreshold;

    uint256 public ballotLifespan;

    // INITIALIZER AND CONFIGURATOR

    function initialize(
        address owner_, 
    ) external initializer {
        service = IService(msg.sender);
        _transferOwnership(owner_);
    }

    function setToken(address token_) external onlyService {
        token = IGovernanceToken(token_);
    }

    function setTGE(address tge_) external onlyService {
        tge = ITGE(tge_);
    }

    function setCompanyId(string memory companyId_) external onlyServiceOwner {
        require(bytes(companyId).length == 0, "Already set");
        require(bytes(companyId_).length != 0, "Can not be empty");
        companyId = companyId_;
    }

    function setCompanyDomain(string memory companyDomain_) external {
        if (bytes(companyDomain).length == 0) {
            require(
                msg.sender == service.owner(),
                "Initial setter should be admin"
            );
        } else {
            require(
                msg.sender == address(this),
                "Changer should be pool governance"
            );
        }
        require(bytes(companyDomain_).length != 0, "Can not be empty");
        companyDomain = companyDomain_;
    }

    function setBallotParams(
        uint256 ballotQuorumThreshold_, 
        uint256 ballotDecisionThreshold_, 
        uint256 ballotLifespan_
    ) external onlyServiceOwner {
        require(ballotQuorumThreshold_ <= 10000, "Invalid ballotQuorumThreshold");
        require(ballotDecisionThreshold_ <= 10000, "Invalid ballotDecisionThreshold");
        require(ballotLifespan_ > 0, "Invalid ballotLifespan");

        ballotQuorumThreshold = ballotQuorumThreshold_;
        ballotDecisionThreshold = ballotDecisionThreshold_;
        ballotLifespan = ballotLifespan_;
    }

    // PUBLIC FUNCTIONS

    function castVote(
        uint256 proposalId,
        uint256 votes,
        bool support
    ) external {
        if (votes == type(uint256).max) {
            votes = token.unlockedBalanceOf(msg.sender);
        } else {
            require(
                votes <= token.unlockedBalanceOf(msg.sender),
                "Not enough unlocked balance"
            );
        }
        require(votes > 0, "No votes");
        token.lock(msg.sender, votes, proposals[proposalId].endBlock);
        _castVote(proposalId, votes, support);
    }

    function proposeSingleAction(
        uint256 duration,
        address target,
        uint256 value,
        bytes memory cd,
        string memory description
    ) external onlyProposalGateway returns (uint256 proposalId) {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory values = new uint256[](1);
        values[0] = value;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = cd;
        proposalId = _propose(
            duration,
            service.proposalQuorum(),
            service.proposalThreshold(),
            targets,
            values,
            calldatas,
            description
        );
    }

    // RECEIVE

    receive() external payable {
        // Supposed to be empty
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

    function _afterProposalCreated(uint256 proposalId) internal override {
        service.addProposal(proposalId);
    }

    function _getTotalVotes() internal view override returns (uint256) {
        return token.totalSupply();
    }

    // MODIFIER

    modifier onlyService() {
        require(msg.sender == address(service), "Not service");
        _;
    }

    modifier onlyServiceOwner() {
        require(msg.sender == service.owner(), "Not service owner");
        _;
    }

    modifier onlyProposalGateway() {
        require(
            msg.sender == service.proposalGateway(),
            "Not proposal gateway"
        );
        _;
    }
}
