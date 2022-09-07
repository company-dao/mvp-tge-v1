// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IDirectory.sol";

contract Directory is
  Initializable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  IDirectory
{
  address public service;

  struct ContractInfo {
    address addr;
    ContractType contractType;
    string description;
  }

  mapping(uint256 => ContractInfo) public contractRecordAt;

  uint256 public lastContractRecordIndex;

  mapping(address => uint256) public indexOfContract;

  struct ProposalInfo {
    address pool;
    uint256 proposalId;
    string description;
  }

  mapping(uint256 => ProposalInfo) public proposalRecordAt;

  uint256 public lastProposalRecordIndex;

  // struct ProposalOrContractInfo {
  //     address addr; // address(0) for proposal
  //     ContractType contractType; // None for proposal
  //     address pool; // address(0) for contracts
  //     uint256 proposalId; // 0 for contracts
  //     string description;
  // }

  // mapping(uint256 => ProposalOrContractInfo) public proposalOrContractRecordAt;

  // EVENTS

  event ContractRecordAdded(
    uint256 index,
    address addr,
    ContractType contractType
  );

  // event ProposalOrContractRecordAdded(
  //     uint256 index,
  //     address addr,
  //     ContractType contractType,
  //     address pool,
  //     uint256 proposalId
  // );

  event ProposalRecordAdded(uint256 index, address pool, uint256 proposalId);

  event ServiceSet(address service);

  event ContractDescriptionSet(uint256 index, string description);

  event ProposalDescriptionSet(uint256 index, string description);

  // event ProposalOrContractDescriptionSet(uint256 index, string description);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  // PUBLIC FUNCTIONS

  function addContractRecord(address addr, ContractType contractType)
    external
    override
    onlyService
    returns (uint256 index)
  {
    index = ++lastContractRecordIndex;
    contractRecordAt[index] = ContractInfo({
      addr: addr,
      contractType: contractType,
      description: ""
    });
    indexOfContract[addr] = index;

    emit ContractRecordAdded(index, addr, contractType);
  }

  function addProposalRecord(address pool, uint256 proposalId)
    external
    override
    onlyService
    returns (uint256 index)
  {
    index = ++lastProposalRecordIndex;
    proposalRecordAt[index] = ProposalInfo({
      pool: pool,
      proposalId: proposalId,
      description: ""
    });

    emit ProposalRecordAdded(index, pool, proposalId);
  }

  // function addContractOrProposalRecord(address addr, ContractType contractType, address pool, uint256 proposalId)
  //     external
  //     override
  //     onlyService
  //     returns (uint256 index)
  // {
  //     index = ++lastRecordIndex;
  //     contractRecordAt[index] = ContractInfo({
  //         addr: addr,
  //         contractType: contractType,
  //         pool: pool,
  //         proposalId: proposalId,
  //         description: ""
  //     });
  //     indexOfContract[addr] = index;

  //     emit ProposalOrContractRecordAdded(index, addr, contractType, pool, proposalId);
  // }

  function setService(address service_) external onlyOwner {
    require(service_ != address(0), "Invalid service address");

    service = service_;
    emit ServiceSet(service_);
  }

  function setContractDescription(uint256 index, string memory description)
    external
    onlyOwner
  {
    contractRecordAt[index].description = description;
    emit ContractDescriptionSet(index, description);
  }

  function setProposalDescription(uint256 index, string memory description)
    external
    onlyOwner
  {
    proposalRecordAt[index].description = description;
    emit ProposalDescriptionSet(index, description);
  }

  // function setProposalOrContractDescription(uint256 index, string memory description)
  //     external
  //     onlyOwner
  // {
  //     proposalOrContractRecordAt[index].description = description;
  //     emit ProposalOrContractDescriptionSet(index, description);
  // }

  // PUBLIC VIEW FUNCTIONS

  function typeOf(address addr) external view override returns (ContractType) {
    return contractRecordAt[indexOfContract[addr]].contractType;
  }

  // MODIFIERS

  modifier onlyService() {
    require(msg.sender == service, "Not service");
    _;
  }
}
