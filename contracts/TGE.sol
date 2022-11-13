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

/// @title Token Generation Event
contract TGE is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ITGE
{
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev Pool's ERC20 token
     */
    IGovernanceToken public token;

    /**
     * @dev TGE metadata
     */
    string public metadataURI;

    /**
     * @dev TGE token price
     */
    uint256 public price;

    /**
     * @dev TGE hardcap
     */
    uint256 public hardcap;

    /**
     * @dev TGE softcap
     */
    uint256 public softcap;

    /**
     * @dev Minimal amount of tokens an address can purchase
     */
    uint256 public minPurchase;

    /**
     * @dev Maximum amount of tokens an address can purchase
     */
    uint256 public maxPurchase;

    /**
     * @dev Percentage of tokens from each purchase that goes to vesting
     */
    uint256 public lockupPercent;

    /// @dev lockup TVL value, if this value reached (via getTVL) users can claim their tokens
    uint256 public lockupTVL;

    /**
     * @dev Vesting duration, blocks.
     */
    uint256 public lockupDuration;

    /**
     * @dev TGE duration, blocks.
     */
    uint256 public duration;

    /**
     * @dev Addresses that are allowed to participate in TGE.
     * If list is empty, anyone can participate.
     */
    address[] public userWhitelist;

    /**
     * @dev Token used as currency to purchase pool's tokens during TGE
     */
    address private _unitOfAccount;

    /**
     * @dev Mapping of user's address to whitelist status
     */
    mapping(address => bool) public isUserWhitelisted;

    /**
     * @dev Block of TGE's creation
     */
    uint256 public createdAt;

    /**
     * @dev Mapping of an address to total amount of tokens purchased during TGE
     */
    mapping(address => uint256) public purchaseOf;

    /// @dev Is lockup TVL reached. Users can claim their tokens only if lockup TVL was reached.
    bool public lockupTVLReached;

    /// @dev Mapping of an address to total amount of tokens vesting
    mapping(address => uint256) public lockedBalanceOf;

    /// @dev Total amount of tokens purchased during TGE
    uint256 private _totalPurchased;

    /// @dev Total amount of tokens vesting
    uint256 private _totalLocked;

    /// @dev Protocol token fee is a percentage of tokens sold during TGE. Returns true if fee was claimed by the governing DAO.
    bool public isProtocolTokenFeeClaimed;

    // EVENTS

    /**
     * @dev Event emitted on token puchase.
     * @param buyer buyer
     * @param amount amount of tokens
     */
    event Purchased(address buyer, uint256 amount);

    /**
     * @dev Event emitted on claim of protocol token fee.
     * @param token token
     * @param tokenFee amount of tokens
     */
    event ProtocolTokenFeeClaimed(address token, uint256 tokenFee);

    // CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once
     * @param owner_ TGE's ower
     * @param token_ pool's token
     * @param info TGE parameters
     */
    function initialize(
        address owner_,
        address token_,
        TGEInfo calldata info
    ) public override initializer {
        __Ownable_init();

        uint256 remainingSupply = IGovernanceToken(token_).cap() -
            IGovernanceToken(token_).totalSupply();
        require(
            info.hardcap <= remainingSupply,
            ExceptionsLibrary.HARDCAP_OVERFLOW_REMAINING_SUPPLY
        );
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
                (info.price * info.minPurchase >= 10**18 || info.price == 0),
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

    /**
     * @dev Purchase pool's tokens during TGE
     * @param amount amount of tokens in wei (10**18 = 1 token)
     */
    function purchase(uint256 amount)
        external
        payable
        onlyWhitelistedUser
        onlyState(State.Active)
        nonReentrant
        whenServiceNotPaused
    {
        if (_unitOfAccount == address(0)) {
            require(
                msg.value == (amount * price) / 10**18,
                ExceptionsLibrary.INCORRECT_ETH_PASSED
            );
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

    /**
     * @dev Return purchased tokens and get back tokens paid
     */
    function redeem()
        external
        override
        onlyState(State.Failed)
        nonReentrant
        whenServiceNotPaused
    {
        // User can't claim more than he bought in this event (in case somebody else has transferred him tokens)
        require(
            purchaseOf[msg.sender] > 0,
            ExceptionsLibrary.ZERO_PURCHASE_AMOUNT
        );

        uint256 lockup = lockedBalanceOf[msg.sender];

        uint256 refundAmount = 0;

        if (lockup > 0) {
            lockedBalanceOf[msg.sender] = 0;
            purchaseOf[msg.sender] -= lockup;
            _totalLocked -= lockup;
            refundAmount += lockup;
            token.decreaseTotalTGELockedTokens(lockup);
            token.burn(address(this), lockup);
        }

        uint256 balanceToRedeem = MathUpgradeable.min(
            token.minUnlockedBalanceOf(msg.sender),
            purchaseOf[msg.sender]
        );
        if (balanceToRedeem > 0) {
            purchaseOf[msg.sender] -= balanceToRedeem;
            refundAmount += balanceToRedeem;
            token.burn(msg.sender, balanceToRedeem);
        }

        require(refundAmount > 0, ExceptionsLibrary.NOTHING_TO_REDEEM);
        uint256 refundValue = (refundAmount * price) / 10**18;

        if (_unitOfAccount == address(0)) {
            payable(msg.sender).transfer(refundValue);
        } else {
            IERC20Upgradeable(_unitOfAccount).transfer(msg.sender, refundValue);
        }
    }

    /**
     * @dev Claim vested tokens
     */
    function claim() external whenServiceNotPaused {
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

    function setLockupTVLReached() external whenServiceNotPaused onlyManager {
        require(!lockupTVLReached, ExceptionsLibrary.LOCKUP_TVL_REACHED);
        lockupTVLReached = true;
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev Transfer proceeds from TGE to pool's treasury. Claim protocol fee.
     */
    function transferFunds()
        external
        onlyState(State.Successful)
        whenServiceNotPaused
    {
        claimProtocolTokenFee();
        // transferFundsToGnosis();

        if (_unitOfAccount == address(0)) {
            payable(token.pool()).sendValue(address(this).balance);
        } else {
            IERC20Upgradeable(_unitOfAccount).safeTransfer(
                token.pool(),
                IERC20Upgradeable(_unitOfAccount).balanceOf(address(this))
            );
        }
    }

    /// @dev Transfers protocol token fee in form of pool's governance tokens to protocol treasury
    function claimProtocolTokenFee() private onlyState(State.Successful) {
        if (isProtocolTokenFeeClaimed) {
            return;
        }

        isProtocolTokenFeeClaimed = true;

        token.mint(
            token.service().protocolTreasury(),
            token.service().getProtocolTokenFee(
                _totalPurchased
            )
        );

        emit ProtocolTokenFeeClaimed(
            address(token),
            token.service().getProtocolTokenFee(
                _totalPurchased
            )
        );
    }

    // VIEW FUNCTIONS

    /**
     * @dev How many tokens an address can purchase.
     * @return Amount of tokens
     */
    function maxPurchaseOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return maxPurchase - purchaseOf[account];
    }

    /**
     * @dev Returns TGE's state.
     * @return State
     */
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

    /**
     * @dev Is claim avilable for vested tokens.
     * @return Is claim available
     */
    function claimAvailable() public view returns (bool) {
        return
            lockupTVLReached &&
            block.number >= createdAt + lockupDuration &&
            (state()) != State.Failed;
    }

    /**
     * @dev Get token used to purchase pool's tokens in TGE
     * @return Token address
     */
    function getUnitOfAccount() public view returns (address) {
        return _unitOfAccount;
    }

    /**
     * @dev Get total amount of tokens purchased during TGE.
     * @return Total amount of tokens.
     */
    function getTotalPurchased() public view returns (uint256) {
        return _totalPurchased;
    }

    /**
     * @dev Get total amount of tokens that are vesting.
     * @return Total vesting tokens.
     */
    function getTotalLocked() public view returns (uint256) {
        return _totalLocked;
    }

    /**
     * @dev Get total value of all purchased tokens
     * @return Total value
     */
    function getTotalPurchasedValue() public view returns (uint256) {
        return (_totalPurchased * price) / 10**18;
    }

    /**
     * @dev Get total value of all vesting tokens
     * @return Total value
     */
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

    modifier onlyManager() {
        require(
            msg.sender == token.service().owner() ||
                token.service().isManagerWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier whenServiceNotPaused() {
        require(!token.service().paused(), ExceptionsLibrary.SERVICE_PAUSED);
        _;
    }

    function test83212() external pure returns (uint256) {
        return 3;
    }
}
