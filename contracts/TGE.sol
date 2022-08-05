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

    address private _unitOfAccount;

    mapping(address => bool) public isUserWhitelisted;

    mapping(address => bool) public isTokenWhitelisted;

    uint256 public createdAt;

    mapping(address => uint256) public purchaseOf;

    bool public lockupTVLReached;

    mapping(address => uint256) public lockedBalanceOf;

    uint256 private _totalPurchased;

    uint256 private _totalLocked;

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
        _unitOfAccount = info.unitOfAccount;

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
        if (_unitOfAccount == address(0)) {
            require(msg.value == amount * price, "Invalid ETH value passed");
        } else {
            IERC20Upgradeable(_unitOfAccount).safeTransferFrom(
                msg.sender,
                address(this),
                amount * price
            );
        }

        require(amount >= minPurchase, "Amount less than min purchase");
        require(amount <= maxPurchaseOf(msg.sender), "Overflows max purchase");
        require(_totalPurchased + amount <= hardcap, "Overflows hardcap");

        _totalPurchased += amount;
        purchaseOf[msg.sender] += amount;
        uint256 lockedAmount = (amount * lockupPercent + 99) / 100;
        if (amount - lockedAmount > 0) {
            token.mint(msg.sender, amount - lockedAmount);
        }
        token.mint(address(this), lockedAmount);
        lockedBalanceOf[msg.sender] += lockedAmount;
        _totalLocked += lockedAmount;
    }

    function redeem() external override onlyState(State.Failed) {
        // User can't claim more than he bought in this event (in case somebody else has transferred him tokens)
        uint256 balance = token.balanceOf(msg.sender);
        uint256 refundTokens = balance + lockedBalanceOf[msg.sender];
        if (refundTokens > balance) {
            lockedBalanceOf[msg.sender] -= (refundTokens - balance);
            _totalLocked -= (refundTokens - balance);
            token.burn(address(this), refundTokens - balance);
            refundTokens = balance;
        }
        token.burn(msg.sender, refundTokens);
        uint256 refundValue = refundTokens * price;

        if (_unitOfAccount == address(0)) {
            payable(msg.sender).transfer(refundValue);
        } else {
            IERC20Upgradeable(_unitOfAccount).transfer(
                msg.sender,
                refundValue
            );
        }
    }

    function claim() external {
        require(claimAvailable(), "claim not yet available");
        require(lockedBalanceOf[msg.sender] > 0, "No locked balance");

        uint256 balance = lockedBalanceOf[msg.sender];
        lockedBalanceOf[msg.sender] = 0;
        _totalLocked -= balance;
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
        if (_unitOfAccount == address(0)) {
            payable(token.pool()).sendValue(address(this).balance);
        } else {
            IERC20Upgradeable(_unitOfAccount).safeTransfer(
                token.pool(),
                IERC20Upgradeable(_unitOfAccount).balanceOf(address(this))
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
        } else if (_totalPurchased >= softcap) {
            return State.Successful;
        } else {
            return State.Failed;
        }
    }

    function claimAvailable() public view returns (bool) {
        return lockupTVLReached && block.number >= createdAt + lockupDuration && (state()) != State.Failed;
    }

    function getUnitOfAccount() public view returns (address) {
        return _unitOfAccount;
    }

    function getTotalPurchased() public view returns (uint256) {
        return _totalPurchased;
    }

    function getTotalLocked() public view returns (uint256) {
        return _totalLocked;
    }

    function getTotalPurchasedValue() public view returns (uint256) {
        return _totalPurchased * price;
    }

    function getTotalLockedValue() public view returns (uint256) {
        return _totalLocked * price;
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
