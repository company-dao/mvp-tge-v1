// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";

contract Service is Ownable {
    using Clones for address;

    address public tokenMaster;

    address public tgeMaster;

    uint256 public fee;

    mapping(address => bool) public isWhitelisted;

    // EVENTS

    event WhitelistedSet(address account, bool whitelisted);

    event FeeSet(uint256 fee);

    event TGECreated(address token, address tge);

    // CONSTRUCTOR

    constructor(
        address tokenMaster_,
        address tgeMaster_,
        uint256 fee_
    ) {
        tokenMaster = tokenMaster_;
        tgeMaster = tgeMaster_;
        fee = fee_;
        emit FeeSet(fee_);
    }

    // PUBLIC FUNCTIONS

    function createTGE(
        string memory name,
        string memory symbol,
        uint256 cap,
        ITGE.TGEInfo memory tgeInfo
    ) external payable onlyWhitelisted {
        require(msg.value == fee, "Incorrect fee passed");

        address token = tokenMaster.clone();
        address tge = tgeMaster.clone();

        IGovernanceToken(token).initialize(name, symbol, cap, tge);
        ITGE(tge).initialize(token, tgeInfo);

        emit TGECreated(token, tge);
    }

    // RESTRICTED FUNCTIONS

    function setWhitelisted(address account, bool whitelisted)
        external
        onlyOwner
    {
        require(isWhitelisted[account] != whitelisted, "Already in that state");
        isWhitelisted[account] = whitelisted;
        emit WhitelistedSet(account, whitelisted);
    }

    function setFee(uint256 fee_) external onlyOwner {
        fee = fee_;
        emit FeeSet(fee_);
    }

    function transferFunds(address to) external onlyOwner {
        payable(to).transfer(payable(address(this)).balance);
    }

    // MODIFIERS

    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "Not whitelisted");
        _;
    }
}
