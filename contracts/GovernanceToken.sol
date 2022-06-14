// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";

contract GovernanceToken is
    IGovernanceToken,
    OwnableUpgradeable,
    ERC20VotesUpgradeable,
    ERC20CappedUpgradeable
{
    ITGE public tge;

    mapping(address => uint256) private _locked;

    // CONSTRUCTOR

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 cap_,
        address tge_
    ) external override initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Capped_init(cap_);

        tge = ITGE(tge_);
        _transferOwnership(tge_);
    }

    // RESTRICTED FUNCTIONS

    function mint(
        address to,
        uint256 amount,
        uint256 locked
    ) external override onlyOwner {
        _mint(to, amount);
        _locked[to] += locked;
    }

    function burn(address from) external override onlyOwner {
        _burn(from, balanceOf(from));
        _locked[from] = 0;
    }

    // VIEW FUNCTIONS

    function lockedOf(address account) public view returns (uint256) {
        if (tge.unlockAvailable()) {
            return 0;
        } else {
            return _locked[account];
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            amount <= balanceOf(from) - lockedOf(from),
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
}
