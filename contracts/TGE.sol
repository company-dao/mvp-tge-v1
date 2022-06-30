// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IService.sol";

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

    address[] public whitelist;

    mapping(address => bool) public isWhitelisted;

    uint256 public createdAt;

    uint256 public totalPurchases;

    mapping(address => uint256) public purchaseOf;

    bool public lockupTVLReached;

    mapping(address => uint256) public lockedBalanceOf;

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

        for (uint256 i = 0; i < info.whitelist.length; i++) {
            whitelist.push(info.whitelist[i]);
            isWhitelisted[info.whitelist[i]] = true;
        }
        if (info.whitelist.length == 0) {
            isWhitelisted[address(0)] = true;
        }

        createdAt = block.number;
    }

    // PUBLIC FUNCTIONS

    function purchase(address currency, uint256 amount)
        external
        payable
        onlyWhitelisted
        onlyState(State.Active)
    {
        IService service = token.service();
        require(service.isTokenWhitelisted(currency), "Token not whitelisted");
        if (currency == address(0)) {
            require(msg.value == amount * price, "Invalid ETH value passed");
        } else {
            uint256 amountIn = service.uniswapQuoter().quoteExactOutput(
                service.tokenSwapReversePath(currency),
                amount * price
            );
            IERC20Upgradeable(currency).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
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
        uint256 refundTokens = MathUpgradeable.min(
            balance + lockedBalanceOf[msg.sender],
            purchaseOf[msg.sender]
        );
        purchaseOf[msg.sender] -= refundTokens;
        if (refundTokens > balance) {
            lockedBalanceOf[msg.sender] -= (refundTokens - balance);
            token.burn(address(this), refundTokens - balance);
            refundTokens = balance;
        }
        token.burn(msg.sender, refundTokens);
        uint256 refundValue = refundTokens * price;
        payable(msg.sender).transfer(refundValue);
    }

    function unlock() external {
        require(unlockAvailable(), "Unlock not yet available");
        require(lockedBalanceOf[msg.sender] > 0, "No locked balance");

        uint256 balance = lockedBalanceOf[msg.sender];
        lockedBalanceOf[msg.sender] = 0;
        token.transfer(msg.sender, balance);
    }

    function setLockupTVLReached() external {
        require(getTVL() >= lockupTVL, "Lockup TVL not yet reached");
        lockupTVLReached = true;
    }

    // RESTRICTED FUNCTIONS

    function transferFunds(address currency)
        external
        onlyState(State.Successful)
    {
        if (currency == address(0)) {
            payable(token.pool()).sendValue(address(this).balance);
        } else {
            require(
                currency != address(token),
                "Impossible to transfer TGE token"
            );
            IERC20Upgradeable(currency).safeTransfer(
                token.pool(),
                IERC20Upgradeable(currency).balanceOf(address(this))
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
        return lockupTVLReached && block.number >= createdAt + lockupDuration;
    }

    function getTVL() public returns (uint256) {
        IService service = token.service();
        IQuoter quoter = service.uniswapQuoter();
        address[] memory tokenWhitelist = service.tokenWhitelist();
        uint256 tvl;
        for (uint256 i = 0; i < tokenWhitelist.length; i++) {
            if (tokenWhitelist[i] == address(0)) {
                tvl += address(this).balance;
            } else {
                uint256 balance = IERC20Upgradeable(tokenWhitelist[i])
                    .balanceOf(address(this));
                if (balance > 0) {
                    tvl += quoter.quoteExactInput(
                        service.tokenSwapPath(tokenWhitelist[i]),
                        balance
                    );
                }
            }
        }
        return totalPurchases * price;
    }

    // MODIFIER

    modifier onlyState(State state_) {
        require(state() == state_, "TGE in wrong state");
        _;
    }

    modifier onlyWhitelisted() {
        require(
            isWhitelisted[address(0)] || isWhitelisted[msg.sender],
            "Not whitelisted"
        );
        _;
    }
}
