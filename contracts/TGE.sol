// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
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
        uint256 remainingSupply = IGovernanceToken(token_).cap() -
            IGovernanceToken(token_).totalSupply();
        require(
            info.hardcap <= remainingSupply,
            "Hardcap higher than remaining supply"
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
        duration = info.duration;
        createdAt = block.number;
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
        token.mint(
            msg.sender,
            amount,
            (amount * lockupPercent + 99) / 100,
            createdAt + duration
        );
    }

    function claimBack() external override onlyState(State.Failed) {
        // User can't claim more than he bought in this event (in case somebody else has transferred him tokens)
        uint256 refundTokens = MathUpgradeable.min(
            token.unlockedBalanceOf(msg.sender),
            purchaseOf[msg.sender]
        );
        purchaseOf[msg.sender] -= refundTokens;
        token.burn(msg.sender, refundTokens);
        uint256 refundValue = refundTokens * price;
        payable(msg.sender).transfer(refundValue);
    }

    // RESTRICTED FUNCTIONS

    function transferFunds() external override onlyState(State.Successful) {
        (bool success, ) = token.pool().call{
            value: payable(address(this)).balance
        }("");
        require(success, "Transfer failed");
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
        if (block.number < createdAt + duration) {
            return State.Active;
        } else if (totalPurchases >= softcap) {
            return State.Successful;
        } else {
            return State.Failed;
        }
    }

    // MODIFIER

    modifier onlyState(State state_) {
        require(state() == state_, "TGE in wrong state");
        _;
    }
}
