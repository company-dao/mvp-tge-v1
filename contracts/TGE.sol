// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";

contract TGE is ITGE, OwnableUpgradeable {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

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

    address[] public userWhitelist;

    address public unitOfAccount;

    mapping(address => bool) public isUserWhitelisted;

    mapping(address => bool) public isTokenWhitelisted;

    uint256 public createdAt;

    uint256 public totalPurchases;

    mapping(address => uint256) public purchaseOf;

    bool public lockupTVLReached;

    mapping(address => uint256) public lockedBalanceOf;

    uint256 public totalPurchased;

    uint256 public totalLocked;

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
        lockupTVL = info.lockupTVL;
        lockupTVLReached = (lockupTVL == 0);
        lockupDuration = info.lockupDuration;
        duration = info.duration;
        unitOfAccount = info.unitOfAccount;

        for (uint256 i = 0; i < info.userWhitelist.length; i++) {
            userWhitelist.push(info.userWhitelist[i]);
            isUserWhitelisted[info.userWhitelist[i]] = true;
        }

        createdAt = block.number;
    }

    // PUBLIC FUNCTIONS

    function purchase(uint256 amount)
        external
        payable
        onlyWhitelistedUser
        onlyState(State.Active)
    {
        if (unitOfAccount == address(0)) {
            require(msg.value == amount * price, "Invalid ETH value passed");
        } else {
            IERC20Upgradeable(unitOfAccount).safeTransferFrom(
                msg.sender,
                address(this),
                amount * price
            );
        }

        require(amount >= minPurchase, "Amount less than min purchase");
        require(amount <= maxPurchaseOf(msg.sender), "Overflows max purchase");
        require(totalPurchases + amount <= hardcap, "Overflows hardcap");

        totalPurchases += amount;
        purchaseOf[msg.sender] += amount;
        uint256 lockedAmount = (amount * lockupPercent + 99) / 100;
        if (amount - lockedAmount > 0) {
            token.mint(msg.sender, amount - lockedAmount);
        }
        token.mint(address(this), lockedAmount);
        lockedBalanceOf[msg.sender] += lockedAmount;
    }

    function claimBack() external override onlyState(State.Failed) {
        // User can't claim more than he bought in this event (in case somebody else has transferred him tokens)
        uint256 balance = token.balanceOf(msg.sender);
        uint256 refundTokens = balance + lockedBalanceOf[msg.sender];
        if (refundTokens > balance) {
            lockedBalanceOf[msg.sender] -= (refundTokens - balance);
            token.burn(address(this), refundTokens - balance);
            refundTokens = balance;
        }
        token.burn(msg.sender, refundTokens);
        uint256 refundValue = refundTokens * price;

        if (unitOfAccount == address(0)) {
            payable(msg.sender).transfer(refundValue);
        } else {
            IERC20Upgradeable(unitOfAccount).transfer(
                msg.sender,
                refundValue
            );
        }
    }

    function unlock() external {
        require(unlockAvailable(), "Unlock not yet available");
        require(lockedBalanceOf[msg.sender] > 0, "No locked balance");

        uint256 balance = lockedBalanceOf[msg.sender];
        lockedBalanceOf[msg.sender] = 0;
        token.transfer(msg.sender, balance);
    }

    function setLockupTVLReached() external {
        require(IPool(token.pool()).getTVL() >= lockupTVL, "Lockup TVL not yet reached");
        lockupTVLReached = true;
    }

    // RESTRICTED FUNCTIONS
    function transferFunds()
        external
        onlyState(State.Successful)
    {
        if (unitOfAccount == address(0)) {
            payable(token.pool()).sendValue(address(this).balance);
        } else {
            IERC20Upgradeable(unitOfAccount).safeTransfer(
                token.pool(),
                IERC20Upgradeable(unitOfAccount).balanceOf(address(this))
            );
        }
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

    function unlockAvailable() public view returns (bool) {
        return lockupTVLReached && block.number >= createdAt + lockupDuration && (state()) != State.Failed;
    }

    // MODIFIER

    modifier onlyState(State state_) {
        require(state() == state_, "TGE in wrong state");
        _;
    }

    modifier onlyWhitelistedUser() {
        require(
            userWhitelist.length == 0 || isUserWhitelisted[msg.sender],
            "Not whitelisted"
        );
        _;
    }
}
