// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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
import "./interfaces/IProposalGateway.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Company Entry Point
contract Pool is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IPool,
    Governor
{
    /// @dev Service address
    IService public service;

    /// @dev Pool token address
    IGovernanceToken public token;

    /// @dev Last TGE address
    ITGE public tge;

    /// @dev Minimum amount of votes that ballot must receive
    uint256 private _ballotQuorumThreshold;

    /// @dev Minimum amount of votes that ballot's choice must receive in order to pass
    uint256 private _ballotDecisionThreshold;

    /// @dev Ballot voting duration, blocks
    uint256 private _ballotLifespan;

    /// @dev Pool name
    string private _poolRegisteredName;

    /// @dev Pool trademark
    string private _poolTrademark;

    /// @dev Pool jurisdiction
    uint256 private _poolJurisdiction;

    /// @dev Pool EIN
    string private _poolEIN;

    /// @dev Metadata pool record index
    uint256 private _poolMetadataIndex;

    /// @dev Pool entity type
    uint256 private _poolEntityType;

    /// @dev Pool date of incorporatio
    string private _poolDateOfIncorporation;

    /// @dev Pool's first TGE
    address public primaryTGE;

    /// @dev List of all pool's TGEs
    address[] private _tgeList;

    /**
     * @dev block delay for executeBallot
     * [0] - ballot value in USDT after which delay kicks in
     * [1] - base delay applied to all ballots to mitigate FlashLoan attacks.
     * [2] - delay for TransferETH proposals
     * [3] - delay for TransferERC20 proposals
     * [4] - delay for TGE proposals
     * [5] - delay for GovernanceSettings proposals
     */
    uint256[10] public ballotExecDelay;

    // INITIALIZER AND CONFIGURATOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Create TransferETH proposal
     * @param poolCreator_ Pool owner
     * @param jurisdiction_ Jurisdiction
     * @param poolEIN_ EIN
     * @param dateOfIncorporation Date of incorporation
     * @param poolEntityType_ Entity type
     * @param ballotQuorumThreshold_ Ballot quorum threshold
     * @param ballotDecisionThreshold_ Ballot decision threshold
     * @param ballotLifespan_ Ballot lifespan
     * @param ballotExecDelay_ Ballot execution delay parameters
     * @param metadataIndex Metadata index
     * @param trademark Trademark
     */
    function initialize(
        address poolCreator_,
        uint256 jurisdiction_,
        string memory poolEIN_,
        string memory dateOfIncorporation,
        uint256 poolEntityType_,
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] memory ballotExecDelay_,
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

        require(
            ballotQuorumThreshold_ <= 10000,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(
            ballotDecisionThreshold_ <= 10000,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(ballotLifespan_ > 0, ExceptionsLibrary.INVALID_VALUE);

        _ballotQuorumThreshold = ballotQuorumThreshold_;
        _ballotDecisionThreshold = ballotDecisionThreshold_;
        _ballotLifespan = ballotLifespan_;
        ballotExecDelay = ballotExecDelay_;
    }

    /**
     * @dev Set pool governance token
     * @param token_ Token address
     */
    function setToken(address token_) external onlyService {
        require(token_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        token = IGovernanceToken(token_);
    }

    /**
     * @dev Set pool TGE
     * @param tge_ TGE address
     */
    function setTGE(address tge_) external onlyService {
        require(tge_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        tge = ITGE(tge_);
    }

    /**
     * @dev Set pool primary TGE
     * @param tge_ TGE address
     */
    function setPrimaryTGE(address tge_) external onlyService {
        require(tge_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        primaryTGE = tge_;
    }

    /**
     * @dev Set pool registered name
     * @param registeredName Registered name
     */
    function setRegisteredName(string memory registeredName)
        external
        onlyServiceOwner
    {
        require(
            bytes(_poolRegisteredName).length == 0,
            ExceptionsLibrary.ALREADY_SET
        );
        require(
            bytes(registeredName).length != 0,
            ExceptionsLibrary.VALUE_ZERO
        );
        _poolRegisteredName = registeredName;
    }

    /**
     * @dev Set Service governance settings
     * @param ballotQuorumThreshold_ Ballot quorum theshold
     * @param ballotDecisionThreshold_ Ballot decision threshold
     * @param ballotLifespan_ Ballot lifespan
     * @param ballotExecDelay_ Ballot execution delay parameters
     */
    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] calldata ballotExecDelay_
    ) external onlyPool whenServiceNotPaused {
        require(
            ballotQuorumThreshold_ <= 10000,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(
            ballotDecisionThreshold_ <= 10000,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(ballotLifespan_ > 0, ExceptionsLibrary.INVALID_VALUE);

        // zero value allows FlashLoan attacks against executeBallot
        require(
            ballotExecDelay_[1] > 0 && ballotExecDelay_[1] < 20,
            ExceptionsLibrary.INVALID_VALUE
        );

        _ballotQuorumThreshold = ballotQuorumThreshold_;
        _ballotDecisionThreshold = ballotDecisionThreshold_;
        _ballotLifespan = ballotLifespan_;
        ballotExecDelay = ballotExecDelay_;
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Cast ballot vote
     * @param proposalId Pool proposal ID
     * @param votes Amount of tokens
     * @param support Against or for
     */
    function castVote(
        uint256 proposalId,
        uint256 votes,
        bool support
    ) external nonReentrant whenServiceNotPaused {
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
        token.lock(
            msg.sender,
            votes,
            support,
            getProposal(proposalId).endBlock,
            proposalId
        );
    }

    /**
     * @dev Create pool propsal
     * @param target Proposal transaction recipient
     * @param value Amount of ETH token
     * @param cd Calldata to pass on in .call() to transaction recipient
     * @param description Proposal description
     * @param proposalType Type
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal ID
     */
    function proposeSingleAction(
        address target,
        uint256 value,
        bytes memory cd,
        string memory description,
        IProposalGateway.ProposalType proposalType,
        string memory metaHash
    )
        external
        onlyProposalGateway
        whenServiceNotPaused
        returns (uint256 proposalId)
    {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory values = new uint256[](1);
        values[0] = value;

        proposalId = _propose(
            _ballotLifespan,
            _ballotQuorumThreshold,
            _ballotDecisionThreshold,
            targets,
            values,
            cd,
            description,
            _getTotalSupply() -
                _getTotalTGELockedTokens() -
                token.balanceOf(service.protocolTreasury()),
            service.ballotExecDelay(1),
            proposalType,
            metaHash,
            address(0)
        );
    }

    /**
     * @dev Create pool propsal
     * @param targets Proposal transaction recipients
     * @param values Amounts of ETH token
     * @param description Proposal description
     * @param proposalType Type
     * @param metaHash Hash value of proposal metadata
     * @param token_ token for payment proposal
     * @return proposalId Created proposal ID
     */
    function proposeTransfer(
        address[] memory targets,
        uint256[] memory values,
        string memory description,
        IProposalGateway.ProposalType proposalType,
        string memory metaHash,
        address token_
    )
        external
        onlyProposalGateway
        whenServiceNotPaused
        returns (uint256 proposalId)
    {
        proposalId = _propose(
            _ballotLifespan,
            _ballotQuorumThreshold,
            _ballotDecisionThreshold,
            targets,
            values,
            "",
            description,
            _getTotalSupply() -
                _getTotalTGELockedTokens() -
                token.balanceOf(service.protocolTreasury()),
            service.ballotExecDelay(1),
            proposalType,
            metaHash,
            token_
        );
    }

    /**
     * @dev Add TGE to TGE archive list
     * @param tge_ TGE address
     */
    function addTGE(address tge_) external onlyService {
        _tgeList.push(tge_);
    }

    /**
     * @dev Calculate pool TVL
     * @return Pool TVL
     */
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

    /**
     * @dev Execute proposal
     * @param proposalId Proposal ID
     */
    function executeBallot(uint256 proposalId) external whenServiceNotPaused {
        _executeBallot(proposalId, service, IPool(address(this)));
    }

    /**
     * @dev Cancel proposal, callable only by Service
     * @param proposalId Proposal ID
     */
    function serviceCancelBallot(uint256 proposalId) external onlyService {
        _cancelBallot(proposalId);
    }

    // RECEIVE

    receive() external payable {
        // Supposed to be empty
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Return pool trademark
     * @return Trademark
     */
    function getPoolTrademark() external view returns (string memory) {
        return _poolTrademark;
    }

    /**
     * @dev Return pool registered name
     * @return Registered name
     */
    function getPoolRegisteredName() public view returns (string memory) {
        return _poolRegisteredName;
    }

    /**
     * @dev Return pool proposal quorum threshold
     * @return Ballot quorum threshold
     */
    function getBallotQuorumThreshold() public view returns (uint256) {
        return _ballotQuorumThreshold;
    }

    /**
     * @dev Return proposal decision threshold
     * @return Ballot decision threshold
     */
    function getBallotDecisionThreshold() public view returns (uint256) {
        return _ballotDecisionThreshold;
    }

    /**
     * @dev Return proposal lifespan
     * @return Proposal lifespan
     */
    function getBallotLifespan() public view returns (uint256) {
        return _ballotLifespan;
    }

    /**
     * @dev Return pool jurisdiction
     * @return Jurisdiction
     */
    function getPoolJurisdiction() public view returns (uint256) {
        return _poolJurisdiction;
    }

    /**
     * @dev Return pool EIN
     * @return EIN
     */
    function getPoolEIN() public view returns (string memory) {
        return _poolEIN;
    }

    /**
     * @dev Return pool data of incorporation
     * @return Date of incorporation
     */
    function getPoolDateOfIncorporation() public view returns (string memory) {
        return _poolDateOfIncorporation;
    }

    /**
     * @dev Return pool entity type
     * @return Entity type
     */
    function getPoolEntityType() public view returns (uint256) {
        return _poolEntityType;
    }

    /**
     * @dev Return pool metadata index
     * @return Metadata index
     */
    function getPoolMetadataIndex() public view returns (uint256) {
        return _poolMetadataIndex;
    }

    /**
     * @dev Return maximum proposal ID
     * @return Maximum proposal ID
     */
    function maxProposalId() public view returns (uint256) {
        return lastProposalId;
    }

    /**
     * @dev Return if pool had a successful TGE
     * @return Is any TGE successful
     */
    function isDAO() public view returns (bool) {
        return (ITGE(primaryTGE).state() == ITGE.State.Successful);
    }

    /**
     * @dev Return list of pool's TGEs
     * @return TGE list
     */
    function getTGEList() public view returns (address[] memory) {
        return _tgeList;
    }

    /**
     * @dev Return pool owner
     * @return Owner address
     */
    function owner()
        public
        view
        override(IPool, OwnableUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    /**
     * @dev Return type of proposal
     * @param proposalId Proposal ID
     * @return Proposal type
     */
    function getProposalType(uint256 proposalId)
        public
        view
        returns (IProposalGateway.ProposalType)
    {
        return _getProposalType(proposalId);
    }

    // INTERNAL FUNCTIONS

    function _afterProposalCreated(uint256 proposalId) internal override {
        service.addProposal(proposalId);
    }

    /**
     * @dev Return token total supply
     * @return Total pool token supply
     */
    function _getTotalSupply() internal view override returns (uint256) {
        return token.totalSupply();
    }

    /**
     * @dev Return amount of tokens currently locked in TGE vesting contract(s)
     * @return Total pool vesting tokens
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
        require(
            msg.sender == service.owner(),
            ExceptionsLibrary.NOT_SERVICE_OWNER
        );
        _;
    }

    modifier onlyProposalGateway() {
        require(
            msg.sender == service.proposalGateway(),
            ExceptionsLibrary.NOT_PROPOSAL_GATEWAY
        );
        _;
    }

    modifier onlyPool() {
        require(msg.sender == address(this), ExceptionsLibrary.NOT_POOL);
        _;
    }

    modifier whenServiceNotPaused() {
        require(!service.paused(), ExceptionsLibrary.SERVICE_PAUSED);
        _;
    }

    function test83212() external pure returns (uint256) {
        return 3;
    }
}
