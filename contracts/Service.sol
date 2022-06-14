// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";

contract Service is IService, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Clones for address;

    address public poolMaster;

    address public tokenMaster;

    address public tgeMaster;

    uint256 public fee;

    EnumerableSet.AddressSet private _whitelist;

    // EVENTS

    event WhitelistedSet(address account, bool whitelisted);

    event FeeSet(uint256 fee);

    event PoolCreated(address pool, address token, address tge);

    event SecondaryTGECreated(address pool, address tge);

    // CONSTRUCTOR

    constructor(
        address poolMaster_,
        address tokenMaster_,
        address tgeMaster_,
        uint256 fee_
    ) {
        poolMaster = poolMaster_;
        tokenMaster = tokenMaster_;
        tgeMaster = tgeMaster_;
        fee = fee_;
        emit FeeSet(fee_);
    }

    // PUBLIC FUNCTIONS

    function createPool(
        IPool pool,
        IGovernanceToken.TokenInfo memory tokenInfo,
        ITGE.TGEInfo memory tgeInfo
    ) external payable onlyWhitelisted {
        require(msg.value == fee, "Incorrect fee passed");

        if (address(pool) == address(0)) {
            pool = IPool(poolMaster.clone());
            pool.initialize(msg.sender);
            // TODO: add to ServiceDirectory
        } else {
            // TODO: check if is actual pool via ServiceDirectory
            require(msg.sender == pool.owner(), "Sender is not pool owner");
            require(
                pool.tge().state() == ITGE.State.Failed,
                "Previous TGE not failed"
            );
        }

        address token = tokenMaster.clone();
        // TODO: add to ServiceDirectory
        address tge = tgeMaster.clone();
        // TODO: add to ServiceDirectory

        IGovernanceToken(token).initialize(address(pool), tokenInfo);
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
        address tge = tgeMaster.clone();
        ITGE(tge).initialize(
            msg.sender,
            address(IPool(msg.sender).token()),
            tgeInfo
        );

        emit SecondaryTGECreated(msg.sender, tge);
    }

    function addProposal(uint256 proposalId) external {
        // TODO: add proposal to service directory
    }

    // RESTRICTED FUNCTIONS

    function addToWhitelist(address account) external onlyOwner {
        require(_whitelist.add(account), "Already whitelisted");
        emit WhitelistedSet(account, true);
    }

    function removeFromWhitelist(address account) external onlyOwner {
        require(_whitelist.remove(account), "Already not whitelisted");
        emit WhitelistedSet(account, false);
    }

    function setFee(uint256 fee_) external onlyOwner {
        fee = fee_;
        emit FeeSet(fee_);
    }

    function transferFunds(address to) external onlyOwner {
        payable(to).transfer(payable(address(this)).balance);
    }

    // VIEW FUNCTIONS

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist.contains(account);
    }

    function whitelist() external view returns (address[] memory) {
        return _whitelist.values();
    }

    function whitelistLength() external view returns (uint256) {
        return _whitelist.length();
    }

    function whitelistAt(uint256 index) external view returns (address) {
        return _whitelist.at(index);
    }

    // MODIFIERS

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "Not whitelisted");
        _;
    }

    modifier onlyPool() {
        // TODO: check that is actually pool via ServiceDirectory
        _;
    }
}
