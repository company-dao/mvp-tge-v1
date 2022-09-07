// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IPool.sol";

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
    // uint256 forVotes;
    // uint256 againstVotes;
  }

  mapping(address => LockedBalance) private _locked;

  mapping(address => mapping(uint256 => LockedBalance))
    private _lockedInProposal;

  // mapping(address => mapping(address => uint256)) private _delegated;

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
    uint256 deadline,
    uint256 proposalId
  ) external override onlyPool {
    _lockedInProposal[account][proposalId] = LockedBalance({
      amount: lockedBalanceOf(account, proposalId) + amount,
      deadline: deadline
    });
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
    uint256 max = 0;
    for (uint256 i = 0; i <= IPool(pool).maxProposalId(); i++) {
      uint256 current = unlockedBalanceOf(from, i);
      if (current > max) {
        max = current;
      }
    }
    require(amount <= max, "Not enough unlocked balance");
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
      service.directory().typeOf(msg.sender) == IDirectory.ContractType.TGE,
      "Not a TGE"
    );
    _;
  }
}
