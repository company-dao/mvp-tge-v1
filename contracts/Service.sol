// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./interfaces/IService.sol";
import "./interfaces/IDirectory.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/IWhitelistedTokens.sol";

contract Service is IService, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Clones for address;

    IMetadata public metadata;

    // uint256 public constant ThresholdDecimals = 2;

    IDirectory public directory;

    IWhitelistedTokens public whitelistedTokens;

    address public proposalGateway;

    address public poolMaster;

    address public tokenMaster;

    address public tgeMaster;

    address public metadataMaster;

    uint256 public fee;

    uint256 public proposalQuorum;

    uint256 public proposalThreshold;

    uint256 private _ballotQuorumThreshold; 

    uint256 private _ballotDecisionThreshold; 

    uint256 private _ballotLifespan; 

    ISwapRouter public uniswapRouter;

    IQuoter public uniswapQuoter;

    EnumerableSet.AddressSet private _userWhitelist;

    // EnumerableSet.AddressSet private _tokenWhitelist;

    // mapping(address => bytes) public tokenSwapPath;

    // mapping(address => bytes) public tokenSwapReversePath;

    // EVENTS

    event UserWhitelistedSet(address account, bool whitelisted);

    event TokenWhitelistedSet(address token, bool whitelisted);

    event FeeSet(uint256 fee);

    event PoolCreated(address pool, address token, address tge);

    event SecondaryTGECreated(address pool, address tge);

    event GovernanceSettingsSet(uint256 quorumThreshold, uint256 decisionThreshold, uint256 lifespan);

    event QueueCreated(address queueContract);

    // CONSTRUCTOR

    constructor(
        IDirectory directory_,
        address poolMaster_,
        address proposalGateway_,
        address tokenMaster_,
        address tgeMaster_,
        address metadataMaster_,
        uint256 fee_,
        uint256[3] memory ballotParams,
        ISwapRouter uniswapRouter_,
        IQuoter uniswapQuoter_,
        IWhitelistedTokens whitelistedTokens_
    ) {
        directory = directory_;
        proposalGateway = proposalGateway_;
        poolMaster = poolMaster_;
        tokenMaster = tokenMaster_;
        tgeMaster = tgeMaster_;
        metadataMaster = metadataMaster_;
        fee = fee_;
        _ballotQuorumThreshold = ballotParams[0];
        _ballotDecisionThreshold = ballotParams[1];
        _ballotLifespan = ballotParams[2];
        uniswapRouter = uniswapRouter_;
        uniswapQuoter = uniswapQuoter_;
        whitelistedTokens = whitelistedTokens_;

        address metadataContract = metadataMaster.clone();
        metadata = IMetadata(metadataContract);
        metadata.initialize(msg.sender);

        emit QueueCreated(metadataContract);
        emit FeeSet(fee_);
        emit GovernanceSettingsSet(ballotParams[0], ballotParams[1], ballotParams[2]);
    }

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
    ) external payable onlyWhitelisted {
        require(
            whitelistedTokens.isTokenWhitelisted(tgeInfo.unitOfAccount) || tgeInfo.unitOfAccount == address(0), 
            "Invalid UnitOfAccount"
        );

        if (address(pool) == address(0)) { // TODO: save trademark
            require(msg.value == fee, "Incorrect fee passed");

            uint256 id = metadata.lockRecord(jurisdiction);
            require(id > 0, "Avaliable company not found");
            string[4] memory infoParams = metadata.getInfo(id);

            pool = IPool(poolMaster.clone());
            pool.initialize(
                msg.sender, 
                jurisdiction, 
                infoParams[0], 
                infoParams[1], 
                infoParams[2], 
                infoParams[3], 
                ballotQuorumThreshold_, 
                ballotDecisionThreshold_, 
                ballotLifespan_,
                trademark
            );
            metadata.setOwner(id, address(pool));

            directory.addContractRecord(
                address(pool),
                IDirectory.ContractType.Pool
            );
        } else {
            require(
                directory.typeOf(address(pool)) == IDirectory.ContractType.Pool,
                "Not a pool"
            );
            require(msg.sender == pool.owner(), "Sender is not pool owner");
            require(
                pool.tge().state() == ITGE.State.Failed,
                "Previous TGE not failed"
            );
        }

        address token = tokenMaster.clone();
        directory.addContractRecord(
            token,
            IDirectory.ContractType.GovernanceToken
        );
        address tge = tgeMaster.clone();
        directory.addContractRecord(tge, IDirectory.ContractType.TGE);

        if (address(pool) == address(0)) {
            IGovernanceToken(token).initialize(address(pool), tokenInfo); // TODO: set tokenName = from user TokenInfo if first tge not failed else = poolName
        } else {
            IGovernanceToken(token).initialize(
                address(pool), 
                IGovernanceToken.TokenInfo({
                    name: pool.getPoolTrademark(),
                    symbol: tokenInfo.symbol,
                    cap: tokenInfo.cap
                })
            );
        }
        pool.setToken(token);
        ITGE(tge).initialize(msg.sender, token, tgeInfo);
        pool.setTGE(tge);

        emit PoolCreated(address(pool), token, tge);
    }

    // PUBLIC INDIRECT FUNCTIONS (CALLED THROUGH POOL)

    function createSecondaryTGE(ITGE.TGEInfo memory tgeInfo)
        external
        override
        onlyPool
    {
        require(
            IPool(msg.sender).tge().state() != ITGE.State.Active,
            "Has active TGE"
        );
        require(
            whitelistedTokens.isTokenWhitelisted(tgeInfo.unitOfAccount) || tgeInfo.unitOfAccount == address(0), 
            "Invalid UnitOfAccount"
        );

        address tge = tgeMaster.clone();
        directory.addContractRecord(tge, IDirectory.ContractType.TGE);
        ITGE(tge).initialize(
            msg.sender,
            address(IPool(msg.sender).token()),
            tgeInfo
        );
        IPool(msg.sender).setTGE(tge);

        emit SecondaryTGECreated(msg.sender, tge);
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

    function setFee(uint256 fee_) external onlyOwner {
        fee = fee_;
        emit FeeSet(fee_);
    }

    function transferFunds(address to) external onlyOwner {
        payable(to).transfer(payable(address(this)).balance);
    }

    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_, 
        uint256 ballotDecisionThreshold_, 
        uint256 ballotLifespan_
    ) external onlyOwner {
        require(ballotQuorumThreshold_ <= 10000, "Invalid ballotQuorumThreshold");
        require(ballotDecisionThreshold_ <= 10000, "Invalid ballotDecisionThreshold");
        require(ballotLifespan_ > 0, "Invalid ballotLifespan");

        _ballotQuorumThreshold = ballotQuorumThreshold_;
        _ballotDecisionThreshold = ballotDecisionThreshold_;
        _ballotLifespan = ballotLifespan_;

        emit GovernanceSettingsSet(ballotQuorumThreshold_, ballotDecisionThreshold_, ballotLifespan_);
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

    function owner() public view override(IService, Ownable) returns (address) {
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
