// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IPool.sol";
import "./libraries/ExceptionsLibrary.sol";

contract GovernanceToken is
    Initializable,
    OwnableUpgradeable,
    IGovernanceToken,
    ERC20VotesUpgradeable,
    ERC20CappedUpgradeable
{
    IService public service;

    address public pool;

    struct LockedBalance {
        uint256 amount;
        uint256 deadline;
        uint256 forVotes;
        uint256 againstVotes;
    }

    mapping(address => mapping(uint256 => LockedBalance))
        private _lockedInProposal;

    // mapping(address => mapping(address => uint256)) private _delegated;

    /// @dev Amount of tokens that were minted but currently locked in TGE vesting contract(s)
    uint256 public totalTGELockedTokens;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // CONSTRUCTOR

    function initialize(address pool_, TokenInfo memory info)
        public
        override
        initializer
    {
        __ERC20_init(info.name, info.symbol);
        __ERC20Capped_init(info.cap);
        __Ownable_init();

        service = IService(msg.sender);
        pool = pool_;
        totalTGELockedTokens = 0;
    }

    // RESTRICTED FUNCTIONS

    function mint(address to, uint256 amount) external override onlyTGE {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external override onlyTGE {
        _burn(from, amount);
    }

    function lock(
        address account,
        uint256 amount,
        bool support,
        uint256 deadline,
        uint256 proposalId
    ) external override onlyPool {
        if (support) {
            _lockedInProposal[account][proposalId] = LockedBalance({
                amount: lockedBalanceOf(account, proposalId) + amount,
                deadline: deadline,
                forVotes: _lockedInProposal[account][proposalId].forVotes +
                    amount,
                againstVotes: _lockedInProposal[account][proposalId]
                    .againstVotes
            });
        } else {
            _lockedInProposal[account][proposalId] = LockedBalance({
                amount: lockedBalanceOf(account, proposalId) + amount,
                deadline: deadline,
                forVotes: _lockedInProposal[account][proposalId].forVotes,
                againstVotes: _lockedInProposal[account][proposalId]
                    .againstVotes + amount
            });
        }
    }

    /**
     * @dev Increases amount of tokens locked in TGE vesting contract(s)
     * @param _amount amount of tokens
     */
    function increaseTotalTGELockedTokens(uint256 _amount) external onlyTGE {
        require(
            (totalTGELockedTokens + _amount) <= type(uint256).max,
            ExceptionsLibrary.INVALID_VALUE
        );

        totalTGELockedTokens += _amount;
    }

    /**
     * @dev Decreases amount of tokens locked in TGE vesting contract(s)
     * @param _amount amount of tokens
     */
    function decreaseTotalTGELockedTokens(uint256 _amount) external onlyTGE {
        require(
            (totalTGELockedTokens - _amount) >= 0,
            ExceptionsLibrary.INVALID_VALUE
        );

        totalTGELockedTokens -= _amount;
    }

    // VIEW FUNCTIONS

    function unlockedBalanceOf(address account, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return balanceOf(account) - lockedBalanceOf(account, proposalId);
    }

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

    function getLockedInPrposal(address account, uint256 proposalId)
        public
        view
        returns (LockedBalance memory)
    {
        return _lockedInProposal[account][proposalId];
    }

    function decimals()
        public
        pure
        override(ERC20Upgradeable, IGovernanceToken)
        returns (uint8)
    {
        return 18;
    }

    function cap()
        public
        view
        override(IGovernanceToken, ERC20CappedUpgradeable)
        returns (uint256)
    {
        return super.cap();
    }

    function minUnlockedBalanceOf(address user) public view returns (uint256) {
        uint256 min = balanceOf(user);
        for (uint256 i = 0; i <= IPool(pool).maxProposalId(); i++) {
            uint256 current = unlockedBalanceOf(user, i);
            if (current < min) {
                min = current;
            }
        }
        return min;
    }

    // INTERNAL FUNCTIONS

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 min = minUnlockedBalanceOf(from);
        require(amount <= min, ExceptionsLibrary.LOW_UNLOCKED_BALANCE);

        super._transfer(from, to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }

    function _mint(address account, uint256 amount)
        internal
        override(ERC20VotesUpgradeable, ERC20CappedUpgradeable)
    {
        super._mint(account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    // MODIFIERS

    modifier onlyPool() {
        require(msg.sender == pool, ExceptionsLibrary.NOT_POOL);
        _;
    }

    modifier onlyTGE() {
        require(
            service.directory().typeOf(msg.sender) ==
                IDirectory.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }

    function testI3813() public pure returns (uint256) {
        return uint256(123);
    }
}
