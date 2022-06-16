// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";

contract GovernanceToken is
    IGovernanceToken,
    OwnableUpgradeable,
    ERC20VotesUpgradeable,
    ERC20CappedUpgradeable
{
    IService public service;

    address public pool;

    struct LockedBalance {
        uint256 amount;
        uint256 deadline;
    }

    mapping(address => LockedBalance) private _locked;

    // CONSTRUCTOR

    function initialize(address pool_, TokenInfo memory info)
        external
        override
        initializer
    {
        __ERC20_init(info.name, info.symbol);
        __ERC20Capped_init(info.cap);
        __Ownable_init();

        service = IService(msg.sender);
        pool = pool_;
    }

    // RESTRICTED FUNCTIONS

    function mint(
        address to,
        uint256 amount,
        uint256 lockedAmount,
        uint256 lockDeadline
    ) external override onlyTGE {
        _mint(to, amount);
        _lock(to, lockedAmount, lockDeadline);
    }

    function burn(address from, uint256 amount) external override onlyTGE {
        _burn(from, amount);
    }

    function lock(
        address account,
        uint256 amount,
        uint256 deadline
    ) external override onlyPool {
        _lock(account, amount, deadline);
    }

    // VIEW FUNCTIONS

    function unlockedBalanceOf(address account) public view returns (uint256) {
        return balanceOf(account) - lockedBalanceOf(account);
    }

    function lockedBalanceOf(address account) public view returns (uint256) {
        if (block.number >= _locked[account].deadline) {
            return 0;
        } else {
            return _locked[account].amount;
        }
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function cap()
        public
        view
        override(IGovernanceToken, ERC20CappedUpgradeable)
        returns (uint256)
    {
        return super.cap();
    }

    // INTERNAL FUNCTIONS

    function _lock(
        address account,
        uint256 amount,
        uint256 deadline
    ) internal {
        _locked[account] = LockedBalance({amount: amount, deadline: deadline});
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            amount <= unlockedBalanceOf(from),
            "Not enough unlocked balance"
        );
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
        require(msg.sender == pool, "Not pool");
        _;
    }

    modifier onlyTGE() {
        require(
            service.directory().typeOf(msg.sender) ==
                IDirectory.ContractType.TGE,
            "Not a TGE"
        );
        _;
    }
}
