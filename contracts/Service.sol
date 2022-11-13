// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./interfaces/IService.sol";
import "./interfaces/IDirectory.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/IWhitelistedTokens.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Protocol entry point
contract Service is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IService
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    /// @dev Metadata address
    IMetadata public metadata;

    /// @dev Directory address
    IDirectory public directory;

    /// @dev WhitelistedTokens address
    IWhitelistedTokens public whitelistedTokens;

    /// @dev ProposalGateway address
    address public proposalGateway;

    /// @dev Pool beacon
    address public poolBeacon;

    /// @dev Token beacon
    address public tokenBeacon;

    /// @dev TGE beacon
    address public tgeBeacon;

    /// @dev Protocol createPool fee
    uint256 public fee;

    /// @dev Minimum amount of votes that ballot must receive
    uint256 private _ballotQuorumThreshold;

    /// @dev Minimum amount of votes that ballot's choice must receive in order to pass
    uint256 private _ballotDecisionThreshold;

    /// @dev Ballot voting duration, blocks
    uint256 private _ballotLifespan;

    /// @dev UniswapRouter contract address
    ISwapRouter public uniswapRouter;

    /// @dev UniswapQuoter contract address
    IQuoter public uniswapQuoter;

    /**
     * @dev Addresses that are allowed to participate in TGE.
     * If list is empty, anyone can participate.
     */
    EnumerableSetUpgradeable.AddressSet private _userWhitelist;

    /// @dev address that collects protocol token fees
    address public protocolTreasury;

    /// @dev protocol token fee percentage value with 4 decimals. Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000
    uint256 public protocolTokenFee;

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

    /// @dev USDT contract address. Used to estimate proposal value.
    address public usdt;

    /// @dev WETH contract address. Used to estimate proposal value.
    address public weth;

    /// @dev List of managers
    EnumerableSetUpgradeable.AddressSet private _managerWhitelist;

    // EVENTS

    /**
     * @dev Event emitted on change in user's whitelist status.
     * @param account User's account
     * @param whitelisted Is whitelisted
     */
    event UserWhitelistedSet(address account, bool whitelisted);

    /**
     * @dev Event emitted on change in tokens's whitelist status.
     * @param token Token address
     * @param whitelisted Is whitelisted
     */
    event TokenWhitelistedSet(address token, bool whitelisted);

    /**
     * @dev Event emitted on fee change.
     * @param fee Fee
     */
    event FeeSet(uint256 fee);

    /**
     * @dev Event emitted on pool creation.
     * @param pool Pool address
     * @param token Pool token address
     * @param tge Pool primary TGE address
     */
    event PoolCreated(address pool, address token, address tge);

    /**
     * @dev Event emitted on creation of secondary TGE.
     * @param pool Pool address
     * @param tge Secondary TGE address
     */
    event SecondaryTGECreated(address pool, address tge);

    /**
     * @dev Event emitted on change in Service governance settings.
     * @param quorumThreshold quorumThreshold
     * @param decisionThreshold decisionThreshold
     * @param lifespan lifespan
     * @param ballotExecDelay ballotExecDelay
     */
    event GovernanceSettingsSet(
        uint256 quorumThreshold,
        uint256 decisionThreshold,
        uint256 lifespan,
        uint256[10] ballotExecDelay
    );

    /**
     * @dev Event emitted on protocol treasury change.
     * @param protocolTreasury Proocol treasury address
     */
    event ProtocolTreasuryChanged(address protocolTreasury);

    /**
     * @dev Event emitted on protocol token fee change.
     * @param protocolTokenFee Protocol token fee
     */
    event ProtocolTokenFeeChanged(uint256 protocolTokenFee);

    // CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once
     * @param directory_ Directory address
     * @param poolBeacon_ Pool beacon
     * @param proposalGateway_ ProposalGateway address
     * @param tokenBeacon_ Governance token beacon
     * @param tgeBeacon_ TGE beacon
     * @param metadata_ Metadata address
     * @param fee_ createPool protocol fee
     * @param ballotParams [ballotQuorumThreshold, ballotLifespan, ballotDecisionThreshold, ...ballotExecDelay]
     * @param uniswapRouter_ UniswapRouter address
     * @param uniswapQuoter_ UniswapQuoter address
     * @param whitelistedTokens_ WhitelistedTokens address
     * @param _protocolTokenFee Protocol token fee
     */
    function initialize(
        IDirectory directory_,
        address poolBeacon_,
        address proposalGateway_,
        address tokenBeacon_,
        address tgeBeacon_,
        IMetadata metadata_,
        uint256 fee_,
        uint256[13] calldata ballotParams,
        ISwapRouter uniswapRouter_,
        IQuoter uniswapQuoter_,
        IWhitelistedTokens whitelistedTokens_,
        uint256 _protocolTokenFee
    ) public initializer {
        require(
            address(directory_) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );
        require(poolBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(proposalGateway_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(tokenBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(tgeBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(
            address(metadata_) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );
        require(
            address(uniswapRouter_) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );
        require(
            address(uniswapQuoter_) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );
        require(
            address(whitelistedTokens_) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        __Ownable_init();
        __UUPSUpgradeable_init();

        directory = directory_;
        proposalGateway = proposalGateway_;
        poolBeacon = poolBeacon_;
        tokenBeacon = tokenBeacon_;
        tgeBeacon = tgeBeacon_;
        metadata = metadata_;
        fee = fee_;
        _ballotQuorumThreshold = ballotParams[0];
        _ballotDecisionThreshold = ballotParams[1];
        _ballotLifespan = ballotParams[2];

        ballotExecDelay = [
            ballotParams[3],
            ballotParams[4],
            ballotParams[5],
            ballotParams[6],
            ballotParams[7],
            ballotParams[8],
            ballotParams[9],
            ballotParams[10],
            ballotParams[11],
            ballotParams[12]
        ];

        uniswapRouter = uniswapRouter_;
        uniswapQuoter = uniswapQuoter_;
        whitelistedTokens = whitelistedTokens_;

        setProtocolTreasury(address(this));
        setProtocolTokenFee(_protocolTokenFee);

        emit FeeSet(fee_);
        emit GovernanceSettingsSet(
            ballotParams[0],
            ballotParams[1],
            ballotParams[2],
            ballotExecDelay
        );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // PUBLIC FUNCTIONS

    /**
     * @dev Create pool
     * @param pool Pool address. If not address(0) - creates new token and new primary TGE for an existing pool.
     * @param tokenInfo Pool token parameters
     * @param tgeInfo Pool TGE parameters
     * @param ballotQuorumThreshold_ Ballot quorum threshold
     * @param ballotDecisionThreshold_ Ballot decision threshold
     * @param ballotLifespan_ Ballot lifespan, blocks.
     * @param jurisdiction Pool jurisdiction
     * @param ballotExecDelay_ Ballot execution delay parameters
     * @param trademark Pool trademark
     */
    function createPool(
        IPool pool,
        IGovernanceToken.TokenInfo memory tokenInfo,
        ITGE.TGEInfo memory tgeInfo,
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256 jurisdiction,
        uint256[10] memory ballotExecDelay_,
        string memory trademark
    ) external payable onlyWhitelisted nonReentrant whenNotPaused {
        require(
            tgeInfo.unitOfAccount == address(0) ||
                tgeInfo.unitOfAccount.isContract(),
            ExceptionsLibrary.INVALID_TOKEN
        );

        require(
            tokenInfo.cap >= 1 * 10**18, // 1 * 10**IGovernanceToken(tokenBeacon).decimals(),
            ExceptionsLibrary.INVALID_CAP
        );
        tokenInfo.cap += getProtocolTokenFee(tokenInfo.cap);

        if (address(pool) == address(0)) {
            require(msg.value == fee, ExceptionsLibrary.INCORRECT_ETH_PASSED);

            uint256 metadataIndex = metadata.lockRecord(jurisdiction);

            require(metadataIndex > 0, ExceptionsLibrary.NO_COMPANY);
            IMetadata.QueueInfo memory queueInfo = metadata.getQueueInfo(
                metadataIndex
            );

            pool = IPool(address(new BeaconProxy(poolBeacon, "")));
            pool.initialize(
                msg.sender,
                jurisdiction,
                queueInfo.EIN,
                queueInfo.dateOfIncorporation,
                queueInfo.entityType,
                ballotQuorumThreshold_,
                ballotDecisionThreshold_,
                ballotLifespan_,
                ballotExecDelay_,
                metadataIndex,
                trademark
            );

            metadata.setOwner(metadataIndex, address(pool));

            directory.addContractRecord(
                address(pool),
                IDirectory.ContractType.Pool
            );
        } else {
            require(
                directory.typeOf(address(pool)) == IDirectory.ContractType.Pool,
                ExceptionsLibrary.NOT_POOL
            );
            require(
                msg.sender == pool.owner(),
                ExceptionsLibrary.NOT_POOL_OWNER
            );
            require(pool.isDAO() == false, ExceptionsLibrary.IS_DAO);
        }

        IGovernanceToken token = IGovernanceToken(
            address(new BeaconProxy(tokenBeacon, ""))
        );
        directory.addContractRecord(
            address(token),
            IDirectory.ContractType.GovernanceToken
        );

        ITGE tge = ITGE(address(new BeaconProxy(tgeBeacon, "")));
        directory.addContractRecord(address(tge), IDirectory.ContractType.TGE);
        directory.addEventRecord(
            address(pool),
            IDirectory.EventType.TGE,
            0,
            ""
        );

        if (address(pool) == address(0)) {
            token.initialize(address(pool), tokenInfo);
        } else {
            token.initialize(
                address(pool),
                IGovernanceToken.TokenInfo({
                    name: pool.getPoolTrademark(),
                    symbol: tokenInfo.symbol,
                    cap: tokenInfo.cap
                })
            );
        }
        pool.setToken(address(token));

        tge.initialize(msg.sender, address(token), tgeInfo);
        pool.setTGE(address(tge));
        pool.setPrimaryTGE(address(tge));
        pool.addTGE(address(tge));

        emit PoolCreated(address(pool), address(token), address(tge));
    }

    // PUBLIC INDIRECT FUNCTIONS (CALLED THROUGH POOL)

    /**
     * @dev Create secondary TGE
     * @param tgeInfo TGE parameters
     */
    function createSecondaryTGE(ITGE.TGEInfo calldata tgeInfo)
        external
        override
        onlyPool
        nonReentrant
        whenNotPaused
    {
        require(
            IPool(msg.sender).tge().state() != ITGE.State.Active,
            ExceptionsLibrary.ACTIVE_TGE_EXISTS
        );
        require(
            tgeInfo.unitOfAccount == address(0) ||
                tgeInfo.unitOfAccount.isContract(),
            ExceptionsLibrary.INVALID_TOKEN
        );

        ITGE tge = ITGE(address(new BeaconProxy(tgeBeacon, "")));
        directory.addContractRecord(address(tge), IDirectory.ContractType.TGE);
        tge.initialize(msg.sender, address(IPool(msg.sender).token()), tgeInfo);
        IPool(msg.sender).setTGE(address(tge));
        IPool(msg.sender).addTGE(address(tge));

        emit SecondaryTGECreated(msg.sender, address(tge));
    }

    /**
     * @dev Add proposal to directory
     * @param proposalId Proposal ID
     */
    function addProposal(uint256 proposalId) external onlyPool whenNotPaused {
        directory.addProposalRecord(msg.sender, proposalId);
    }

    /**
     * @dev Add event to directory
     * @param eventType Event type
     * @param proposalId Proposal ID
     * @param description Description
     */
    function addEvent(
        IDirectory.EventType eventType,
        uint256 proposalId,
        string calldata description
    ) external onlyPool whenNotPaused {
        directory.addEventRecord(
            msg.sender,
            eventType,
            proposalId,
            description
        );
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev Add user to whitelist
     * @param account User address
     */
    function addUserToWhitelist(address account) external onlyManager {
        require(
            _userWhitelist.add(account),
            ExceptionsLibrary.ALREADY_WHITELISTED
        );
        emit UserWhitelistedSet(account, true);
    }

    /**
     * @dev Remove user from whitelist
     * @param account User address
     */
    function removeUserFromWhitelist(address account) external onlyManager {
        require(
            _userWhitelist.remove(account),
            ExceptionsLibrary.ALREADY_NOT_WHITELISTED
        );
        emit UserWhitelistedSet(account, false);
    }

    /**
     * @dev Add manager to whitelist
     * @param account Manager address
     */
    function addManagerToWhitelist(address account) external onlyOwner {
        require(
            _managerWhitelist.add(account),
            ExceptionsLibrary.ALREADY_WHITELISTED
        );
    }

    /**
     * @dev Remove manager from whitelist
     * @param account Manager address
     */
    function removeManagerFromWhitelist(address account) external onlyOwner {
        require(
            _managerWhitelist.remove(account),
            ExceptionsLibrary.ALREADY_NOT_WHITELISTED
        );
    }

    /**
     * @dev Set createPool protocol fee
     * @param fee_ Fee
     */
    function setFee(uint256 fee_) external onlyManager {
        fee = fee_;
        emit FeeSet(fee_);
    }

    /**
     * @dev Transfer collected createPool protocol fees
     * @param to Transfer recipient
     */
    function transferCollectedFees(address to) external onlyOwner {
        require(to != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        payable(to).transfer(payable(address(this)).balance);
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
    ) external onlyOwner {
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

        emit GovernanceSettingsSet(
            ballotQuorumThreshold_,
            ballotDecisionThreshold_,
            ballotLifespan_,
            ballotExecDelay
        );
    }

    /**
     * @dev Set protocol treasury address
     * @param _protocolTreasury Protocol treasury address
     */
    function setProtocolTreasury(address _protocolTreasury) public onlyOwner {
        require(
            _protocolTreasury != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        protocolTreasury = _protocolTreasury;
        emit ProtocolTreasuryChanged(protocolTreasury);
    }

    /**
     * @dev Set protocol token fee
     * @param _protocolTokenFee protocol token fee percentage value with 4 decimals.
     * Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000.
     */
    function setProtocolTokenFee(uint256 _protocolTokenFee) public onlyOwner {
        require(_protocolTokenFee <= 1000000, ExceptionsLibrary.INVALID_VALUE);

        protocolTokenFee = _protocolTokenFee;
        emit ProtocolTokenFeeChanged(protocolTokenFee);
    }

    /**
     * @dev Cancel pool's ballot
     * @param _pool pool
     * @param proposalId proposalId
     */
    function cancelBallot(address _pool, uint256 proposalId) public onlyOwner {
        IPool(_pool).serviceCancelBallot(proposalId);
    }

    /**
     * @dev Pause entire protocol
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause entire protocol
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Set USDT token address
     * @param usdt_ Token address
     */
    function setUsdt(address usdt_) external onlyOwner {
        usdt = usdt_;
    }

    /**
     * @dev Set WETH token address
     * @param weth_ Token address
     */
    function setWeth(address weth_) external onlyOwner {
        weth = weth_;
    }

    // VIEW FUNCTIONS

    /**
     * @dev Return manager's whitelist status
     * @param account Manager's address
     * @return Whitelist status
     */
    function isManagerWhitelisted(address account)
        public
        view
        override
        returns (bool)
    {
        return _managerWhitelist.contains(account);
    }

    /**
     * @dev Return user's whitelist status
     * @param account User's address
     * @return Whitelist status
     */
    function isUserWhitelisted(address account) public view returns (bool) {
        return _userWhitelist.contains(account);
    }

    /**
     * @dev Return all whitelisted users
     * @return Whitelisted addresses
     */
    function userWhitelist() external view returns (address[] memory) {
        return _userWhitelist.values();
    }

    /**
     * @dev Return number of whitelisted users
     * @return Number of whitelisted users
     */
    function userWhitelistLength() external view returns (uint256) {
        return _userWhitelist.length();
    }

    /**
     * @dev Return whitelisted user at particular index
     * @param index Whitelist index
     * @return Whitelisted user's address
     */
    function userWhitelistAt(uint256 index) external view returns (address) {
        return _userWhitelist.at(index);
    }

    /**
     * @dev Return all whitelisted tokens
     * @return Whitelisted tokens
     */
    function tokenWhitelist() external view returns (address[] memory) {
        return whitelistedTokens.tokenWhitelist();
    }

    /**
     * @dev Return Service owner
     * @return Service owner's address
     */
    function owner()
        public
        view
        override(IService, OwnableUpgradeable)
        returns (address)
    {
        // Ownable
        return super.owner();
    }

    /**
     * @dev Return protocol paused status
     * @return Is protocol paused
     */
    function paused()
        public
        view
        override(IService, PausableUpgradeable)
        returns (bool)
    {
        // Pausable
        return super.paused();
    }

    /**
     * @dev Return Service ballot quorum threshold
     * @return Ballot quorum threshold
     */
    function getBallotQuorumThreshold() public view returns (uint256) {
        return _ballotQuorumThreshold;
    }

    /**
     * @dev Return Service ballot decision threshold
     * @return Ballot decision threshold
     */
    function getBallotDecisionThreshold() public view returns (uint256) {
        return _ballotDecisionThreshold;
    }

    /**
     * @dev Return Service ballot lifespan
     * @return Ballot lifespan
     */
    function getBallotLifespan() public view returns (uint256) {
        return _ballotLifespan;
    }

    /**
     * @dev Calculate minimum soft cap for token fee mechanism to work
     * @return softCap minimum soft cap
     */
    function getMinSoftCap() public view returns (uint256) {
        return 1000000 / protocolTokenFee;
    }

    /**
     * @dev calculates protocol token fee for given token amount
     * @param amount Token amount
     * @return tokenFee
     */
    function getProtocolTokenFee(uint256 amount) public view returns (uint256) {
        require(amount >= getMinSoftCap(), ExceptionsLibrary.INVALID_VALUE);

        uint256 mul = 1;
        if (amount > 100000000000000000000) {
            mul = 1000000000000;
            amount = amount / mul;
        }

        return
            ((((protocolTokenFee * 1000000) / 1000000) * amount) / 1000000) *
            mul;
    }

    /**
     * @dev Return max hard cap accounting for protocol token fee
     * @param _pool pool to calculate hard cap against
     * @return Maximum hard cap
     */
    function getMaxHardCap(address _pool) public view returns (uint256) {
        if (
            directory.typeOf(_pool) == IDirectory.ContractType.Pool &&
            IPool(_pool).isDAO()
        ) {
            return
                IPool(_pool).token().cap() -
                getProtocolTokenFee(IPool(_pool).token().cap());
        }

        return type(uint256).max - getProtocolTokenFee(type(uint256).max);
    }

    // MODIFIERS

    modifier onlyWhitelisted() {
        require(
            isUserWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier onlyManager() {
        require(
            msg.sender == owner() || isManagerWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier onlyPool() {
        require(
            directory.typeOf(msg.sender) == IDirectory.ContractType.Pool,
            ExceptionsLibrary.NOT_POOL
        );
        _;
    }

    function test83122() external pure returns (uint256) {
        return 3;
    }
}
