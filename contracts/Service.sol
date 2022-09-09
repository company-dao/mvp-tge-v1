// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

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

  uint256 public constant ThresholdDecimals = 2;

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

  // EnumerableSet.AddressSet private _userWhitelist;

  EnumerableSetUpgradeable.AddressSet private _userWhitelist;

  // EnumerableSet.AddressSet private _tokenWhitelist;

  // mapping(address => bytes) public tokenSwapPath;

  // mapping(address => bytes) public tokenSwapReversePath;

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
    IWhitelistedTokens whitelistedTokens_
  ) public initializer {
    require(address(directory_) != address(0), "Invalid Directory address");
    require(poolBeacon_ != address(0), "Invalid Pool Beacon address");
    require(proposalGateway_ != address(0), "Invalid ProposalGateway address");
    require(tokenBeacon_ != address(0), "Invalid Token Beacon address");
    require(tgeBeacon_ != address(0), "Invalid TGE Beacon address");
    require(address(metadata_) != address(0), "Invalid Metadata address");
    require(address(uniswapRouter_) != address(0), "Invalid UniswapRouter address");
    require(address(uniswapQuoter_) != address(0), "Invalid UniswapQuoter address");
    require(address(whitelistedTokens_) != address(0), "Invalid WhitelistedTokens address");

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
      "Contract does not support valid payment"
    );
    // require(
    //     whitelistedTokens.isTokenWhitelisted(tgeInfo.unitOfAccount) || tgeInfo.unitOfAccount == address(0),
    //     "Invalid UnitOfAccount"
    // );

    if (address(pool) == address(0)) {
      require(msg.value == fee, "Incorrect fee passed");

      uint256 id = metadata.lockRecord(jurisdiction);
      require(id > 0, "Avaliable company not found");
      string[5] memory infoParams = metadata.getInfo(id);

      // pool = IPool(poolMaster.clone());
      pool = IPool(address(new BeaconProxy(poolBeacon, "")));
      pool.initialize(
        msg.sender,
        jurisdiction,
        infoParams[0],
        infoParams[1],
        infoParams[2],
        infoParams[3],
        infoParams[4],
        ballotQuorumThreshold_,
        ballotDecisionThreshold_,
        ballotLifespan_,
        trademark
      );
      metadata.setOwner(id, address(pool));

      directory.addContractRecord(address(pool), IDirectory.ContractType.Pool);
    } else {
      require(
        directory.typeOf(address(pool)) == IDirectory.ContractType.Pool,
        "Not a pool"
      );
      require(msg.sender == pool.owner(), "Sender is not pool owner");
      require(
        pool.isDAO() == false,
        // pool.tge().state() == ITGE.State.Failed,
        "Previous TGE not failed"
      );
    }

    // address token = tokenMaster.clone();
    IGovernanceToken token = IGovernanceToken(
      address(new BeaconProxy(tokenBeacon, ""))
    );
    directory.addContractRecord(
      address(token),
      IDirectory.ContractType.GovernanceToken
    );
    // address tge = tgeMaster.clone();
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

    emit PoolCreated(address(pool), address(token), address(tge));
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
      "Has active TGE"
    );
    require(
        tgeInfo.unitOfAccount == address(0) ||
        tgeInfo.unitOfAccount.isContract(),
      "Contract does not support valid payment"
    );
    // require(
    //     whitelistedTokens.isTokenWhitelisted(tgeInfo.unitOfAccount) || tgeInfo.unitOfAccount == address(0),
    //     "Invalid UnitOfAccount"
    // );

    // address tge = tgeMaster.clone();
    ITGE tge = ITGE(address(new BeaconProxy(tgeBeacon, "")));
    directory.addContractRecord(address(tge), IDirectory.ContractType.TGE);
    tge.initialize(msg.sender, address(IPool(msg.sender).token()), tgeInfo);
    IPool(msg.sender).setTGE(address(tge));

    emit SecondaryTGECreated(msg.sender, address(tge));
  }

  function addProposal(uint256 proposalId) external onlyPool {
    directory.addProposalRecord(msg.sender, proposalId);
  }

  // RESTRICTED FUNCTIONS

  function addUserToWhitelist(address account) external onlyOwner {
    require(_userWhitelist.add(account), "Already whitelisted");
    emit UserWhitelistedSet(account, true);
  }

  function removeUserFromWhitelist(address account) external onlyOwner {
    require(_userWhitelist.remove(account), "Already not whitelisted");
    emit UserWhitelistedSet(account, false);
  }

  // function addTokensToWhitelist(
  //     address[] memory tokens,
  //     bytes[] memory swapPaths,
  //     bytes[] memory swapReversePaths
  // ) external onlyOwner {
  //     for (uint256 i = 0; i < tokens.length; i++) {
  //         require(_tokenWhitelist.add(tokens[i]), "Already whitelisted");
  //         tokenSwapPath[tokens[i]] = swapPaths[i];
  //         tokenSwapReversePath[tokens[i]] = swapReversePaths[i];
  //         emit TokenWhitelistedSet(tokens[i], true);
  //     }
  // }

  // function removeTokensFromWhitelist(address[] memory tokens)
  //     external
  //     onlyOwner
  // {
  //     for (uint256 i = 0; i < tokens.length; i++) {
  //         require(
  //             _tokenWhitelist.remove(tokens[i]),
  //             "Already not whitelisted"
  //         );
  //         emit TokenWhitelistedSet(tokens[i], false);
  //     }
  // }

  function setPoolBeacon(address poolBeacon_) external onlyOwner {
    require(poolBeacon_ != address(0), "Invalid address");
    poolBeacon = poolBeacon_;
  }

  function setTokenBeacon(address tokenBeacon_) external onlyOwner {
    require(tokenBeacon_ != address(0), "Invalid address");
    tokenBeacon = tokenBeacon_;
  }

  function setTGEBeacon(address tgeBeacon_) external onlyOwner {
    require(tgeBeacon_ != address(0), "Invalid address");
    tgeBeacon = tgeBeacon_;
  }

  function setFee(uint256 fee_) external onlyOwner {
    fee = fee_;
    emit FeeSet(fee_);
  }

  function transferFunds(address to) external onlyOwner {
    require(to != address(0), "Can not transfer to zero address");

    payable(to).transfer(payable(address(this)).balance);
  }

  function setGovernanceSettings(
    uint256 ballotQuorumThreshold_,
    uint256 ballotDecisionThreshold_,
    uint256 ballotLifespan_
  ) external onlyOwner {
    require(ballotQuorumThreshold_ <= 10000, "Invalid ballotQuorumThreshold");
    require(
      ballotDecisionThreshold_ <= 10000,
      "Invalid ballotDecisionThreshold"
    );
    require(ballotLifespan_ > 0, "Invalid ballotLifespan");

    _ballotQuorumThreshold = ballotQuorumThreshold_;
    _ballotDecisionThreshold = ballotDecisionThreshold_;
    _ballotLifespan = ballotLifespan_;

    emit GovernanceSettingsSet(
      ballotQuorumThreshold_,
      ballotDecisionThreshold_,
      ballotLifespan_
    );
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

  // function tokenWhitelist()
  //     external
  //     view
  //     override
  //     returns (address[] memory)
  // {
  //     return _tokenWhitelist.values();
  // }

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

  // MODIFIERS

  modifier onlyWhitelisted() {
    require(isUserWhitelisted(msg.sender), "Not whitelisted");
    _;
  }

  modifier onlyPool() {
    require(
      directory.typeOf(msg.sender) == IDirectory.ContractType.Pool,
      "Not a pool"
    );
    _;
  }
}
