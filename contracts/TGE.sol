// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./libraries/ExceptionsLibrary.sol";
// import "./libraries/Multiplication.sol";

contract TGE is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ITGE
{
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

    /// @dev unused, compatibility with proxy layout
    IService public service;

    bool public isProtocolTokenFeeClaimed;

    // EVENTS

    event Purchased(address buyer, uint256 amount);

    event ProtocolTokenFeeClaimed(address token, uint256 tokenFee);

    // CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner_,
        address token_,
        TGEInfo memory info
    ) public override initializer {
        __Ownable_init();

        uint256 remainingSupply = IGovernanceToken(token_).cap() -
            IGovernanceToken(token_).totalSupply();
        require(
            info.hardcap <= remainingSupply,
            ExceptionsLibrary.HARDCAP_OVERFLOW_REMAINING_SUPPLY
        );

        // require(
        //     info.softcap >= IGovernanceToken(token_).service().getMinSoftCap(),
        //     ExceptionsLibrary.INVALID_SOFTCAP
        // );

        require(
            info.hardcap >= IGovernanceToken(token_).service().getMinSoftCap(),
            ExceptionsLibrary.INVALID_HARDCAP
        );

        require(
            info.hardcap +
                IGovernanceToken(token_).service().getProtocolTokenFee(
                    info.hardcap
                ) <=
                remainingSupply,
            ExceptionsLibrary.HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY
        );
        require(
            info.minPurchase >= 1000 &&
            (
                info.price * info.minPurchase >= 10**18 ||
                info.price == 0
            ),
            ExceptionsLibrary.INVALID_VALUE
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

    // amount of tokens in wei (10**18 = 1 token)
    // price per governance token (unit of account with decimals)
    function purchase(uint256 amount)
        external
        payable
        onlyWhitelistedUser
        onlyState(State.Active)
        nonReentrant
    {
        if (_unitOfAccount == address(0)) {
            require(msg.value == (amount * price) / 10**18, ExceptionsLibrary.INCORRECT_ETH_PASSED);
        } else {
            IERC20Upgradeable(_unitOfAccount).safeTransferFrom(
                msg.sender,
                address(this),
                (amount * price) / 10**18
            );
        }

        require(
            amount >= minPurchase,
            ExceptionsLibrary.MIN_PURCHASE_UNDERFLOW
        );
        require(
            amount <= maxPurchaseOf(msg.sender),
            ExceptionsLibrary.MAX_PURCHASE_OVERFLOW
        );
        require(
            _totalPurchased + amount <= hardcap,
            ExceptionsLibrary.HARDCAP_OVERFLOW
        );

        _totalPurchased += amount;
        purchaseOf[msg.sender] += amount;
        uint256 lockedAmount = (amount * lockupPercent + 99) / 100;
        if (amount - lockedAmount > 0) {
            token.mint(msg.sender, amount - lockedAmount);
        }
        token.mint(address(this), lockedAmount);
        lockedBalanceOf[msg.sender] += lockedAmount;
        _totalLocked += lockedAmount;
        token.increaseTotalTGELockedTokens(lockedAmount);

        emit Purchased(msg.sender, amount);
    }

    function redeem() external override onlyState(State.Failed) nonReentrant {
        // User can't claim more than he bought in this event (in case somebody else has transferred him tokens)
        uint256 balance = token.minUnlockedBalanceOf(msg.sender);
        uint256 refundTokens = balance + lockedBalanceOf[msg.sender];
        if (refundTokens > balance) {
            lockedBalanceOf[msg.sender] -= (refundTokens - balance);
            _totalLocked -= (refundTokens - balance);
            token.decreaseTotalTGELockedTokens(lockedBalanceOf[msg.sender]);
            token.burn(address(this), refundTokens - balance);
            refundTokens = balance;
        }
        token.burn(msg.sender, refundTokens);
        uint256 refundValue = (refundTokens * price) / 10**18;

        if (_unitOfAccount == address(0)) {
            payable(msg.sender).transfer(refundValue);
        } else {
            IERC20Upgradeable(_unitOfAccount).transfer(msg.sender, refundValue);
        }
    }

    function claim() external {
        require(claimAvailable(), ExceptionsLibrary.CLAIM_NOT_AVAILABLE);
        require(
            lockedBalanceOf[msg.sender] > 0,
            ExceptionsLibrary.NO_LOCKED_BALANCE
        );

        uint256 balance = lockedBalanceOf[msg.sender];
        lockedBalanceOf[msg.sender] = 0;
        _totalLocked -= balance;
        token.decreaseTotalTGELockedTokens(balance);

        bool status = token.transfer(msg.sender, balance);
        require(status, ExceptionsLibrary.TRANSFER_FAILED);
    }

    function setLockupTVLReached() external {
        lockupTVLReached = true;
        require(
            IPool(token.pool()).getTVL() >= lockupTVL,
            ExceptionsLibrary.LOCKUP_TVL_NOT_REACHED
        );
    }

    // RESTRICTED FUNCTIONS
    function transferFunds() external onlyState(State.Successful) {
        claimProtocolTokenFee();
        transferFundsToGnosis();
    }

    /// @dev transfers TGE funds to Pool's Gnosis safe
    function transferFundsToGnosis() private {
        if (_unitOfAccount == address(0)) {
            payable(IPool(token.pool()).gnosisSafe()).sendValue(
                address(this).balance
            );

            return;
        }

        IERC20Upgradeable(_unitOfAccount).safeTransfer(
            IPool(token.pool()).gnosisSafe(),
            IERC20Upgradeable(_unitOfAccount).balanceOf(address(this))
        );
    }

    /// @dev sends protocol token fee in form of pool's governance tokens to protocol treasury
    function claimProtocolTokenFee() private onlyState(State.Successful) {
        if (isProtocolTokenFeeClaimed) {
            return;
        }

        isProtocolTokenFeeClaimed = true;

        token.mint(
            IGovernanceToken(token).service().protocolTreasury(),
            IGovernanceToken(token).service().getProtocolTokenFee(
                _totalPurchased
            )
        );

        emit ProtocolTokenFeeClaimed(
            address(token),
            IGovernanceToken(token).service().getProtocolTokenFee(
                _totalPurchased
            )
        );
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
        if (_totalPurchased == hardcap) {
            return State.Successful;
        }
        if (block.number < createdAt + duration) {
            return State.Active;
        } else if ((_totalPurchased >= softcap)) {
            return State.Successful;
        } else {
            return State.Failed;
        }
    }

    function claimAvailable() public view returns (bool) {
        return
            lockupTVLReached &&
            block.number >= createdAt + lockupDuration &&
            (state()) != State.Failed;
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
        return (_totalPurchased * price) / 10**18;
    }

    function getTotalLockedValue() public view returns (uint256) {
        return (_totalLocked * price) / 10**18;
    }

    // MODIFIER

    modifier onlyState(State state_) {
        require(state() == state_, ExceptionsLibrary.WRONG_STATE);
        _;
    }

    modifier onlyWhitelistedUser() {
        require(
            userWhitelist.length == 0 || isUserWhitelisted[msg.sender],
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    function testI3813() public pure returns (uint256) {
        return uint256(123);
    }
}
