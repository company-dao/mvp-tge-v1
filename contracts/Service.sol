// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
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
import "./interfaces/gnosis/IGnosisSafeProxyFactory.sol";
import "./interfaces/gnosis/IGnosisGovernance.sol";
import "./libraries/ExceptionsLibrary.sol";

contract Service is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    IService
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    IMetadata public metadata;

    IDirectory public directory;

    IWhitelistedTokens public whitelistedTokens;

    address public proposalGateway;

    address public poolBeacon;

    address public tokenBeacon;

    address public tgeBeacon;

    uint256 public fee;

    uint256 private _ballotQuorumThreshold;

    uint256 private _ballotDecisionThreshold;

    uint256 private _ballotLifespan;

    ISwapRouter public uniswapRouter;

    IQuoter public uniswapQuoter;

    EnumerableSetUpgradeable.AddressSet private _userWhitelist;

    /// @dev address that collects protocol token fees
    address public protocolTreasury;

    /// @dev protocol token fee percentage value with 4 decimals. Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000
    uint256 public protocolTokenFee;

    address public gnosisProxyFactory;
    address public gnosisSingleton;
    address public gnosisGovernanceBeacon;
    address public gnosisSetup;

    // EVENTS

    event UserWhitelistedSet(address account, bool whitelisted);

    event TokenWhitelistedSet(address token, bool whitelisted);

    event FeeSet(uint256 fee);

    event PoolCreated(address pool, address token, address tge);

    event SecondaryTGECreated(address pool, address tge);

    event GovernanceSettingsSet(
        uint256 quorumThreshold,
        uint256 decisionThreshold,
        uint256 lifespan
    );

    event ProtocolTreasuryChanged(address protocolTreasury);
    event ProtocolTokenFeeChanged(uint256 protocolTokenFee);

    event GnosisProxyFactoryChanged(address gnosisProxyFactory);
    event GnosisSingletonChanged(address gnosisSingleton);
    event GnosisGovernanceBeaconChanged(address gnosisGovernanceBeacon);

    // CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IDirectory directory_,
        address poolBeacon_,
        address proposalGateway_,
        address tokenBeacon_,
        address tgeBeacon_,
        IMetadata metadata_,
        uint256 fee_,
        uint256[3] memory ballotParams,
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
        uniswapRouter = uniswapRouter_;
        uniswapQuoter = uniswapQuoter_;
        whitelistedTokens = whitelistedTokens_;

        setProtocolTreasury(address(this));
        setProtocolTokenFee(_protocolTokenFee);

        emit FeeSet(fee_);
        emit GovernanceSettingsSet(
            ballotParams[0],
            ballotParams[1],
            ballotParams[2]
        );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // PUBLIC FUNCTIONS

    function createPool(
        IPool pool,
        IGovernanceToken.TokenInfo memory tokenInfo,
        ITGE.TGEInfo memory tgeInfo,
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256 jurisdiction,
        string memory trademark
    ) external payable onlyWhitelisted nonReentrant {
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
                metadataIndex,
                trademark
            );

            IGnosisGovernance gnosisGovernance = IGnosisGovernance(
                address(new BeaconProxy(gnosisGovernanceBeacon, ""))
            );
            pool.setGnosisGovernance(address(gnosisGovernance));

            gnosisGovernance.initialize(address(pool));

            address[] memory owners = new address[](1);
            owners[0] = msg.sender;
            pool.setGnosisSafe(
                address(_createPoolGnosisSafe(owners, pool.gnosisGovernance()))
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

    /**
     * @dev Creates Gnosis Safe
     * @param _owners owners
     * @param _module goernance module
     * @return proxy Gnosis safe proxy
     */
    function _createPoolGnosisSafe(address[] memory _owners, address _module)
        private
        returns (address proxy)
    {
        bytes memory moduleInitializer = abi.encodeWithSignature(
            "enableModule(address)",
            _module
        );

        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            _owners,
            _owners.length,
            gnosisSetup,
            moduleInitializer,
            address(0),
            address(0),
            0,
            address(0)
        );

        return
            IGnosisSafeProxyFactory(gnosisProxyFactory).createProxyWithNonce(
                gnosisSingleton,
                initializer,
                block.timestamp
            );
    }

    // PUBLIC INDIRECT FUNCTIONS (CALLED THROUGH POOL)

    function createSecondaryTGE(ITGE.TGEInfo memory tgeInfo)
        external
        override
        onlyPool
        nonReentrant
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

    function addProposal(uint256 proposalId) external onlyPool {
        directory.addProposalRecord(msg.sender, proposalId);
    }

    // RESTRICTED FUNCTIONS

    function addUserToWhitelist(address account) external onlyOwner {
        require(
            _userWhitelist.add(account),
            ExceptionsLibrary.ALREADY_WHITELISTED
        );
        emit UserWhitelistedSet(account, true);
    }

    function removeUserFromWhitelist(address account) external onlyOwner {
        require(
            _userWhitelist.remove(account),
            ExceptionsLibrary.ALREADY_NOT_WHITELISTED
        );
        emit UserWhitelistedSet(account, false);
    }

    function setPoolBeacon(address poolBeacon_) external onlyOwner {
        require(poolBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        poolBeacon = poolBeacon_;
    }

    function setTokenBeacon(address tokenBeacon_) external onlyOwner {
        require(tokenBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        tokenBeacon = tokenBeacon_;
    }

    function setTGEBeacon(address tgeBeacon_) external onlyOwner {
        require(tgeBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        tgeBeacon = tgeBeacon_;
    }

    function setFee(uint256 fee_) external onlyOwner {
        fee = fee_;
        emit FeeSet(fee_);
    }

    function transferCollectedFees(address to) external onlyOwner {
        require(to != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        payable(to).transfer(payable(address(this)).balance);
    }

    // function setProposalDirectoryMetadata(
    //     address proposalGateway_,
    //     address directory_,
    //     address metadata_,
    //     address whitelistedTokens_
    // ) external onlyOwner {
    //     require(proposalGateway_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
    //     require(address(directory_) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
    //     require(address(metadata_) != address(0), ExceptionsLibrary.ADDRESS_ZERO);

    //     proposalGateway = proposalGateway_;
    //     directory = IDirectory(directory_);
    //     metadata = IMetadata(metadata_);
    //     whitelistedTokens = IWhitelistedTokens(whitelistedTokens_);
    // }

    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_
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

        _ballotQuorumThreshold = ballotQuorumThreshold_;
        _ballotDecisionThreshold = ballotDecisionThreshold_;
        _ballotLifespan = ballotLifespan_;

        emit GovernanceSettingsSet(
            ballotQuorumThreshold_,
            ballotDecisionThreshold_,
            ballotLifespan_
        );
    }

    /**
     * @dev Sets protocol treasury address
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
     * @dev Sets protocol token fee
     * @param _protocolTokenFee protocol token fee percentage value with 4 decimals.
     * Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000.
     */
    function setProtocolTokenFee(uint256 _protocolTokenFee) public onlyOwner {
        require(_protocolTokenFee <= 1000000, ExceptionsLibrary.INVALID_VALUE);

        protocolTokenFee = _protocolTokenFee;
        emit ProtocolTokenFeeChanged(protocolTokenFee);
    }

    /**
     * @dev Sets Gnosis proxy factory
     * @param _gnosisProxyFactory Gnosis proxy factory address
     */
    function setGnosisProxyFactory(address _gnosisProxyFactory)
        public
        onlyOwner
    {
        require(
            _gnosisProxyFactory != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        gnosisProxyFactory = _gnosisProxyFactory;
        emit GnosisProxyFactoryChanged(gnosisProxyFactory);
    }

    /**
     * @dev Sets Gnosis singleton
     * @param _gnosisSingleton Gnosis singleton address
     */
    function setGnosisSingleton(address _gnosisSingleton) public onlyOwner {
        require(_gnosisSingleton != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        gnosisSingleton = _gnosisSingleton;
        emit GnosisSingletonChanged(gnosisSingleton);
    }

    /**
     * @dev Sets Gnosis governance module beacon
     * @param _gnosisGovernanceBeacon Gnosis governance module beacon address
     */
    function setGnosisGovernanceBeacon(address _gnosisGovernanceBeacon)
        public
        onlyOwner
    {
        require(
            _gnosisGovernanceBeacon != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        gnosisGovernanceBeacon = _gnosisGovernanceBeacon;
        emit GnosisGovernanceBeaconChanged(gnosisGovernanceBeacon);
    }

    /**
     * @dev Sets Gnosis setup address
     * @param _gnosisSetup Gnosis setup address
     */
    function setGnosisSetup(address _gnosisSetup) public onlyOwner {
        require(_gnosisSetup != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        gnosisSetup = _gnosisSetup;
    }

    // VIEW FUNCTIONS

    function isUserWhitelisted(address account) public view returns (bool) {
        return _userWhitelist.contains(account);
    }

    function userWhitelist() external view returns (address[] memory) {
        return _userWhitelist.values();
    }

    function userWhitelistLength() external view returns (uint256) {
        return _userWhitelist.length();
    }

    function userWhitelistAt(uint256 index) external view returns (address) {
        return _userWhitelist.at(index);
    }

    function tokenWhitelist() external view returns (address[] memory) {
        return whitelistedTokens.tokenWhitelist();
    }

    function owner()
        public
        view
        override(IService, OwnableUpgradeable)
        returns (address)
    {
        // Ownable
        return super.owner();
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

    /**
     * @dev calculates minimum soft cap for token fee mechanism to work
     * @return softCap minimum soft cap
     */
    function getMinSoftCap() public view returns (uint256) {
        return 1000000 / protocolTokenFee;
    }

    /**
     * @dev calculates protocol token fee for given token amount
     * @param amount token amount
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
     * @dev Returns max hard cap accounting for protocol token fee
     * @param _pool pool to calculate hard cap against
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

    modifier onlyPool() {
        require(
            directory.typeOf(msg.sender) == IDirectory.ContractType.Pool,
            ExceptionsLibrary.NOT_POOL
        );
        _;
    }

    function testI3813() public pure returns (uint256) {
        return uint256(123);
    }
}
