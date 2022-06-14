// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";

contract TGE is ITGE, OwnableUpgradeable {
    IGovernanceToken public token;

    string public metadataURI;

    uint256 public price;

    uint256 public hardcap;

    uint256 public softcap;

    uint256 public minPurchase;

    uint256 public maxPurchase;

    uint256 public lockupPercent;

    uint256 public lockupTVL;

    uint256 public lockupDuration;

    uint256 public duration;

    uint256 public createdAt;

    uint256 public totalPurchases;

    mapping(address => uint256) public purchaseOf;

    // CONSTRUCTOR

    function initialize(
        address owner_,
        address token_,
        TGEInfo memory info
    ) external override initializer {
        require(
            info.hardcap <= IGovernanceToken(token_).cap(),
            "Hardcap higher than cap"
        );

        _transferOwnership(owner_);

        token = IGovernanceToken(token_);
        metadataURI = info.metadataURI;
        price = info.price;
        hardcap = info.hardcap;
        softcap = info.softcap;
        minPurchase = info.minPurchase;
        maxPurchase = info.maxPurchase;
        lockupPercent = info.lockupPercent;
        lockupTVL = info.lockupTVL;
        lockupDuration = info.lockupDuration;
        duration = info.duration;
        createdAt = block.timestamp;
    }

    // PUBLIC FUNCTIONS

    function purchase(uint256 amount)
        external
        payable
        override
        onlyState(State.Active)
    {
        require(amount >= minPurchase, "Amount less than min purchase");
        require(msg.value == amount * price, "Invalid ETH value passed");
        require(amount <= maxPurchaseOf(msg.sender), "Overflows max purchase");
        require(totalPurchases + amount <= hardcap, "Overflows hardcap");

        totalPurchases += amount;
        purchaseOf[msg.sender] += amount;
        token.mint(msg.sender, amount, (amount * lockupPercent) / 100);
    }

    function claimBack() external override onlyState(State.Failed) {
        uint256 refundValue = token.balanceOf(msg.sender) * price;
        token.burn(msg.sender);
        payable(msg.sender).transfer(refundValue);
    }

    // RESTRICTED FUNCTIONS

    function transferFunds(address to)
        external
        override
        onlyOwner
        onlyState(State.Successful)
    {
        payable(to).transfer(payable(address(this)).balance);
    }

    // VIEW FUNCTIONS

    function maxPurchaseOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return maxPurchase - purchaseOf[account];
    }

    function state() public view override returns (State) {
        if (block.timestamp < createdAt + duration) {
            return State.Active;
        } else if (totalPurchases >= softcap) {
            return State.Successful;
        } else {
            return State.Failed;
        }
    }

    function unlockAvailable() external view returns (bool) {
        return
            totalPurchases * price >= lockupTVL &&
            block.timestamp >= createdAt + lockupDuration;
    }

    // MODIFIER

    modifier onlyState(State state_) {
        require(state() == state_, "TGE in wrong state");
        _;
    }
}
