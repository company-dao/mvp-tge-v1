// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./components/Governor.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IWhitelistedTokens.sol";
import "./interfaces/IMetadata.sol";

contract Pool is IPool, OwnableUpgradeable, Governor {
    IService public service;

    IGovernanceToken public token;

    ITGE public tge;

    uint256 private _ballotQuorumThreshold; 

    uint256 private _ballotDecisionThreshold; 

    uint256 private _ballotLifespan; 

    string private _poolRegisteredName;

    string private _poolTrademark;

    uint256 private _poolJurisdiction; 

    string private _poolEIN; 

    uint256 private _poolMetadataIndex;

    string private _poolDateOfIncorporation; 

    string private _poolLegalAddress; 

    string private _poolTaxationStatus; 

    // INITIALIZER AND CONFIGURATOR

    function initialize(
        address poolCreator_, 
        uint256 jurisdiction_, 
        string memory poolEIN_, 
        string memory dateOfIncorporation, 
        string memory legalAddress, 
        string memory taxationStatus, 
        uint256 ballotQuorumThreshold_, 
        uint256 ballotDecisionThreshold_, 
        uint256 ballotLifespan_, 
        string memory trademark
    ) external initializer {
        service = IService(msg.sender);
        _transferOwnership(poolCreator_);
        _poolJurisdiction = jurisdiction_;
        _poolEIN = poolEIN_;
        _poolDateOfIncorporation = dateOfIncorporation;
        _poolLegalAddress = legalAddress;
        _poolTaxationStatus = taxationStatus;
        _poolTrademark = trademark;

        require(ballotQuorumThreshold_ <= 10000, "Invalid ballotQuorumThreshold");
        require(ballotDecisionThreshold_ <= 10000, "Invalid ballotDecisionThreshold");
        require(ballotLifespan_ > 0, "Invalid ballotLifespan");

        _ballotQuorumThreshold = ballotQuorumThreshold_;
        _ballotDecisionThreshold = ballotDecisionThreshold_;
        _ballotLifespan = ballotLifespan_;
    }

    function setToken(address token_) external onlyService {
        token = IGovernanceToken(token_);
    }

    function setTGE(address tge_) external onlyService {
        tge = ITGE(tge_);
    }

    function setRegisteredName(string memory registeredName) external onlyServiceOwner {
        require(bytes(_poolRegisteredName).length == 0, "Already set");
        require(bytes(registeredName).length != 0, "Can not be empty");
        _poolRegisteredName = registeredName;
    }

    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_, 
        uint256 ballotDecisionThreshold_, 
        uint256 ballotLifespan_
    ) external onlyPool { 
        require(ballotQuorumThreshold_ <= 10000, "Invalid ballotQuorumThreshold");
        require(ballotDecisionThreshold_ <= 10000, "Invalid ballotDecisionThreshold");
        require(ballotLifespan_ > 0, "Invalid ballotLifespan");

        _ballotQuorumThreshold = ballotQuorumThreshold_;
        _ballotDecisionThreshold = ballotDecisionThreshold_;
        _ballotLifespan = ballotLifespan_;
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
            _ballotLifespan,
            _ballotQuorumThreshold,
            _ballotDecisionThreshold,
            targets,
            values,
            calldatas,
            description
        );
    }

    function getTVL() public returns (uint256) {
        IQuoter quoter = service.uniswapQuoter();
        IWhitelistedTokens whitelistedTokens = service.whitelistedTokens();
        address[] memory tokenWhitelist = whitelistedTokens.tokenWhitelist(); // service.tokenWhitelist();
        uint256 tvl;
        for (uint256 i = 0; i < tokenWhitelist.length; i++) {
            if (tokenWhitelist[i] == address(0)) {
                tvl += address(this).balance;
            } else {
                uint256 balance = IERC20Upgradeable(tokenWhitelist[i])
                    .balanceOf(address(this));
                if (balance > 0) {
                    tvl += quoter.quoteExactInput(
                        whitelistedTokens.tokenSwapPath(tokenWhitelist[i]),
                        balance
                    );
                }
            }
        }
        return tvl;
    }

    // RECEIVE

    receive() external payable {
        // Supposed to be empty
    }

    function getPoolTrademark() external view returns (string memory) {
        return _poolTrademark;
    }

    // PUBLIC VIEW FUNCTIONS

    function getPoolRegisteredName() public view returns (string memory) {
        return _poolRegisteredName;
    }

    function getBallotQuorumThreshold() public view returns (uint256) {
        return _ballotQuorumThreshold;
    }

    function getBallotDecisionThreshold() public view returns (uint256) {
        return _ballotDecisionThreshold;
    }

    function getBallotLifespan() public view returns (uint256) {
        return _ballotLifespan;
    }

    function getPoolJurisdiction() public view returns (uint256) {
        return _poolJurisdiction;
    }

    function getPoolEIN() public view returns (string memory) {
        return _poolEIN;
    }

    function getPoolDateOfIncorporation() public view returns (string memory) {
        IMetadata metadata = service.metadata();
        return metadata.getQueueInfo(_poolMetadataIndex).dateOfIncorporation;
    }

    function getPoolLegalAddress() public view returns (string memory) {
        IMetadata metadata = service.metadata();
        return metadata.getQueueInfo(_poolMetadataIndex).legalAddress;
    }

    function getPoolTaxationStatus() public view returns (string memory) {
        IMetadata metadata = service.metadata();
        return metadata.getQueueInfo(_poolMetadataIndex).taxationStatus;
    }

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

    modifier onlyPool() {
        require(
            msg.sender == address(this), 
            "Not a pool"
        );
        _;
    }
}
