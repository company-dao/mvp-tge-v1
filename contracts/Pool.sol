// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./components/Governor.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IWhitelistedTokens.sol";
import "./interfaces/IMetadata.sol";
import "./libraries/ExceptionsLibrary.sol";

contract Pool is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IPool,
    Governor
{
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

    uint256 private _poolEntityType;

    string private _poolDateOfIncorporation;

    address public primaryTGE;

    address[] private _tgeList;

  // INITIALIZER AND CONFIGURATOR

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address poolCreator_,
    uint256 jurisdiction_,
    string memory poolEIN_,
    string memory dateOfIncorporation,
    uint256 poolEntityType_,
    uint256 ballotQuorumThreshold_,
    uint256 ballotDecisionThreshold_,
    uint256 ballotLifespan_,
    uint256 metadataIndex,
    string memory trademark
  ) public initializer {
    require(poolCreator_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
    
    __Ownable_init();

    service = IService(msg.sender);
    _transferOwnership(poolCreator_);
    _poolJurisdiction = jurisdiction_;
    _poolEIN = poolEIN_;
    _poolDateOfIncorporation = dateOfIncorporation;
    _poolEntityType = poolEntityType_;
    _poolTrademark = trademark;
    _poolMetadataIndex = metadataIndex;

    require(ballotQuorumThreshold_ <= 10000, ExceptionsLibrary.INVALID_VALUE);
    require(
      ballotDecisionThreshold_ <= 10000,
      ExceptionsLibrary.INVALID_VALUE
    );
    require(ballotLifespan_ > 0, ExceptionsLibrary.INVALID_VALUE);

    _ballotQuorumThreshold = ballotQuorumThreshold_;
    _ballotDecisionThreshold = ballotDecisionThreshold_;
    _ballotLifespan = ballotLifespan_;
  }

  function setToken(address token_) external onlyService {
    require(token_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

    token = IGovernanceToken(token_);
  }

  function setTGE(address tge_) external onlyService {
    require(tge_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

    tge = ITGE(tge_);
  }

  function setPrimaryTGE(address tge_) external onlyService {
    require(tge_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

    primaryTGE = tge_;
  }

  function setRegisteredName(string memory registeredName)
    external
    onlyServiceOwner
  {
    require(bytes(_poolRegisteredName).length == 0, ExceptionsLibrary.ALREADY_SET);
    require(bytes(registeredName).length != 0, ExceptionsLibrary.VALUE_ZERO);
    _poolRegisteredName = registeredName;
  }

  function setGovernanceSettings(
    uint256 ballotQuorumThreshold_,
    uint256 ballotDecisionThreshold_,
    uint256 ballotLifespan_
  ) external onlyPool {
    require(ballotQuorumThreshold_ <= 10000, ExceptionsLibrary.INVALID_VALUE);
    require(
      ballotDecisionThreshold_ <= 10000,
      ExceptionsLibrary.INVALID_VALUE
    );
    require(ballotLifespan_ > 0, ExceptionsLibrary.INVALID_VALUE);

    _ballotQuorumThreshold = ballotQuorumThreshold_;
    _ballotDecisionThreshold = ballotDecisionThreshold_;
    _ballotLifespan = ballotLifespan_;
  }

  // PUBLIC FUNCTIONS

  function castVote(
    uint256 proposalId,
    uint256 votes,
    bool support
  ) external nonReentrant {
    if (votes == type(uint256).max) {
      votes = token.unlockedBalanceOf(msg.sender, proposalId);
    } else {
      require(
        votes <= token.unlockedBalanceOf(msg.sender, proposalId),
        ExceptionsLibrary.LOW_UNLOCKED_BALANCE
      );
    }
    require(votes > 0, ExceptionsLibrary.VALUE_ZERO);
    // TODO: do not let to change votes (if have forVotes dont let vote against)
    // if (support) {
    //     proposals[proposalId].againstVotes
    // }
    _castVote(proposalId, votes, support);
    token.lock(msg.sender, votes, support, getProposal(proposalId).endBlock, proposalId);
  }

  function proposeSingleAction(
    address target,
    uint256 value,
    bytes memory cd,
    string memory description
  ) external onlyProposalGateway returns (uint256 proposalId) {
    proposalId = _propose(
      _ballotLifespan,
      _ballotQuorumThreshold,
      _ballotDecisionThreshold,
      target,
      value,
      cd,
      description
    );
  }

  function addTGE(address tge_) external onlyService {
    _tgeList.push(tge_);
  }

  function getTVL() public returns (uint256) {
      IQuoter quoter = service.uniswapQuoter();
      IWhitelistedTokens whitelistedTokens = service.whitelistedTokens();
      address[] memory tokenWhitelist = whitelistedTokens.tokenWhitelist(); // service.tokenWhitelist();
      uint256 tvl = 0;

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

  // PUBLIC VIEW FUNCTIONS

  function getPoolTrademark() external view returns (string memory) {
    return _poolTrademark;
  }

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
    return _poolDateOfIncorporation;
    // IMetadata metadata = service.metadata();
    // return metadata.getQueueInfo(_poolMetadataIndex).dateOfIncorporation;
  }

  function getPoolEntityType() public view returns (uint256) {
    return _poolEntityType;
  }

  function getPoolMetadataIndex() public view returns (uint256) {
    return _poolMetadataIndex;
  }

  function maxProposalId() public view returns (uint256) {
    return lastProposalId;
  }

  function isDAO() public view returns (bool) {
    return (ITGE(primaryTGE).state() == ITGE.State.Successful);
  }

  function getTGEList() public view returns (address[] memory) {
    return _tgeList;
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

  /**
    * @dev Returns token total supply
    */
  function _getTotalSupply() internal view override returns (uint256) {
      return token.totalSupply();
  }

  /**
    * @dev Returns amount of tokens currently locked in TGE vesting contract(s)
    */
  function _getTotalTGELockedTokens()
      internal
      view
      override
      returns (uint256)
  {
      return token.totalTGELockedTokens();
  }

  // MODIFIER

  modifier onlyService() {
    require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
    _;
  }

  modifier onlyServiceOwner() {
    require(msg.sender == service.owner(), ExceptionsLibrary.NOT_SERVICE_OWNER);
    _;
  }

  modifier onlyProposalGateway() {
    require(msg.sender == service.proposalGateway(), ExceptionsLibrary.NOT_PROPOSAL_GATEWAY);
    _;
  }

  modifier onlyPool() {
    require(msg.sender == address(this), ExceptionsLibrary.NOT_POOL);
    _;
  }

  function test123() external view {}
}
