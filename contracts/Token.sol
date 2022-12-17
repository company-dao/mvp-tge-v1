// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IDispatcher.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Company (Pool) Token
contract Token is
    Initializable,
    OwnableUpgradeable,
    IToken,
    ERC20CappedUpgradeable
{
    /// @dev Service address
    IService public service;

    /// @dev Pool address
    address public pool;

    /// @dev Token type
    TokenType public tokenType;

    /// @dev Preference TGE for preference token, for Governance token - address(0)
    address public preferenceTGE;

    /// @dev Preference token description, allows up to 5000 characters, for others - ""
    string public description;

    /**
     * @dev Votes lockup structure
     * @param amount Amount
     * @param deadline Deadline
     */
    struct LockedBalance {
        uint256 amount;
        uint256 deadline;
    }

    /**
     * @dev Votes lockup for address
     */
    mapping(address => mapping(uint256 => LockedBalance))
        private _lockedInProposal;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // CONSTRUCTOR

    /**
     * @dev Constructor function, can only be called once
     * @param pool_ Pool
     * @param symbol_ Token symbol for GovernanceToken
     * @param cap_ Token cap
     * @param tokenType_ Token type
     * @param preferenceTGE_ Preference tge address for Preference token
     * @param description_ Token description for Preference token
     */
    function initialize(
        address pool_, 
        string memory symbol_, 
        uint256 cap_, 
        TokenType tokenType_, 
        address preferenceTGE_, 
        string memory description_
    )
        external
        override
        initializer
    {
        __ERC20Capped_init(cap_);
        __Ownable_init();

        if (tokenType_ == TokenType.Preference) {
            __ERC20_init(IPool(pool_).trademark(), string(abi.encodePacked("p", IPool(pool_).token().symbol())));
            preferenceTGE = preferenceTGE_;
            description = description_;
        } else {
            __ERC20_init(IPool(pool_).trademark(), symbol_);
        }

        tokenType = tokenType_;
        service = IService(msg.sender);
        pool = pool_;        
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev Mint token
     * @param to Recipient
     * @param amount Amount of tokens
     */
    function mint(address to, uint256 amount) external override onlyTGE {
        _mint(to, amount);
    }

    /**
     * @dev Burn token
     * @param from Target
     * @param amount Amount of tokens
     */
    function burn(address from, uint256 amount) external override whenPoolNotPaused {
        require(
            service.dispatcher().typeOf(msg.sender) ==
                IDispatcher.ContractType.TGE ||
            msg.sender == from,
            ExceptionsLibrary.INVALID_USER
        );
        require(amount <= minUnlockedBalanceOf(from), ExceptionsLibrary.LOW_UNLOCKED_BALANCE);
        _burn(from, amount);
    }

    /**
     * @dev Lock votes (tokens) as a result of voting for a proposal
     * @param account Token holder
     * @param amount Amount of tokens
     * @param deadline Lockup deadline
     * @param proposalId Proposal ID
     */
    function lock(
        address account,
        uint256 amount,
        uint256 deadline,
        uint256 proposalId
    ) external override onlyPool {
        _lockedInProposal[account][proposalId] = LockedBalance({
            amount: lockedBalanceOf(account, proposalId) + amount,
            deadline: deadline
        });
    }

    // VIEW FUNCTIONS

    /**
     * @dev Return amount of tokens that account owns, excluding tokens locked up as a result of voting for a proposalId
     * @param account Token holder
     * @param proposalId Proposal ID
     */
    function unlockedBalanceOf(address account, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return balanceOf(account) - lockedBalanceOf(account, proposalId);
    }

    /**
     * @dev Return amount of locked up tokens for a given account and proposal ID
     * @param account Token holder
     * @param proposalId Proposal ID
     */
    function lockedBalanceOf(address account, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        if (block.number >= _lockedInProposal[account][proposalId].deadline) {
            return 0;
        } else {
            return _lockedInProposal[account][proposalId].amount;
        }
    }

    /**
     * @dev Return LockedBalance structure for a given proposal ID and account
     * @param account Token holder
     * @param proposalId Proposal ID
     * @return LockedBalance
     */
    function getLockedInProposal(address account, uint256 proposalId)
        public
        view
        returns (LockedBalance memory)
    {
        return _lockedInProposal[account][proposalId];
    }

    /**
     * @dev Return decimals
     * @return Decimals
     */
    function decimals()
        public
        pure
        override(ERC20Upgradeable, IToken)
        returns (uint8)
    {
        return 18;
    }

    /**
     * @dev Return cap
     * @return Cap
     */
    function cap()
        public
        view
        override(IToken, ERC20CappedUpgradeable)
        returns (uint256)
    {
        return super.cap();
    }

    /**
     * @dev Return cap
     * @return Cap
     */
    function symbol()
        public
        view
        override(IToken, ERC20Upgradeable)
        returns (string memory)
    {
        return super.symbol();
    }

    /**
     * @dev Return least amount of unlocked tokens for any proposal that user might have voted for
     * @param user User address
     * @return Minimum unlocked balance
     */
    function minUnlockedBalanceOf(address user) public view returns (uint256) {
        uint256 min = balanceOf(user);
        uint256 maxId = IPool(pool).maxProposalId();
        for (uint256 i = 0; i <= maxId; i++) {
            uint256 current = unlockedBalanceOf(user, i);
            if (current < min) {
                min = current;
            }
        }
        return min;
    }

    function containsTGE(address wallet) public view returns (bool) {
        address[] memory tgeList = IPool(pool).getGovernanceTGEList();
        for (uint256 i = 0; i < tgeList.length; i++) {
            if (wallet == tgeList[i])
                return true;
        }
        return false;
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Transfer tokens from a given user.
     * Check to make sure that transfer amount is less or equal
     * to least amount of unlocked tokens for any proposal that user might have voted for.
     * @param from User address
     * @param to Recipient address
     * @param amount Amount of tokens
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenPoolNotPaused {
        if (tokenType == TokenType.Governance) {
            uint256 min = minUnlockedBalanceOf(from);
            require(amount <= min, ExceptionsLibrary.LOW_UNLOCKED_BALANCE);
        }

        if (tokenType == TokenType.Preference) {
            require(
                ITGE(preferenceTGE).transferUnlocked() &&
                    (
                        from == address(service) || to == address(service) || 
                        from == pool || to == pool || 
                        from == preferenceTGE || to == preferenceTGE ||
                        containsTGE(from) || containsTGE(to)
                    ),
                ExceptionsLibrary.INVALID_USER
            );
        }

        super._transfer(from, to, amount);
    }

    // MODIFIERS

    modifier onlyPool() {
        require(msg.sender == pool, ExceptionsLibrary.NOT_POOL);
        _;
    }

    modifier onlyTGE() {
        require(
            service.dispatcher().typeOf(msg.sender) ==
                IDispatcher.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }

    modifier whenPoolNotPaused() {
        require(!IPool(pool).paused(), ExceptionsLibrary.SERVICE_PAUSED);
        _;
    }

    function test83122() external pure returns (uint256) {
        return 3;
    }
}
