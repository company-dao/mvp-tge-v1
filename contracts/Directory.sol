// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IDirectory.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Protocol directory
contract Directory is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IDirectory
{
    /// @dev Service address
    address public service;

    /**
     * @dev Contract information structure
     * @param addr Contract address
     * @param contractType Contract type
     * @param description Contract description
     */
    struct ContractInfo {
        address addr;
        ContractType contractType;
        string description;
    }

    mapping(uint256 => ContractInfo) public contractRecordAt;

    /// @dev Index of last contract record
    uint256 public lastContractRecordIndex;

    mapping(address => uint256) public indexOfContract;

    /**
     * @dev Proposal information structure
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @param description Proposal description
     */
    struct ProposalInfo {
        address pool;
        uint256 proposalId;
        string description;
    }

    mapping(uint256 => ProposalInfo) public proposalRecordAt;

    /// @dev Index of last proposal record
    uint256 public lastProposalRecordIndex;

    /**
     * @dev Event information structure
     * @param eventType Event type
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @param description Event description
     */
    struct Event {
        EventType eventType;
        address pool;
        uint256 proposalId;
        string description;
        string metaHash;
    }

    mapping(uint256 => Event) public events;

    /// @dev Index of last event record
    uint256 public lastEventIndex;

    // struct ProposalOrContractInfo {
    //     address addr; // address(0) for proposal
    //     ContractType contractType; // None for proposal
    //     address pool; // address(0) for contracts
    //     uint256 proposalId; // 0 for contracts
    //     string description;
    // }

    // mapping(uint256 => ProposalOrContractInfo) public proposalOrContractRecordAt;

    // EVENTS

    /**
     * @dev Event emitted on creation of contract record
     * @param index Record index
     * @param addr Contract address
     * @param contractType Contract type
     */
    event ContractRecordAdded(
        uint256 index,
        address addr,
        ContractType contractType
    );

    /**
     * @dev Event emitted on creation of proposal record
     * @param index Record index
     * @param pool Pool address
     * @param proposalId Proposal ID
     */
    event ProposalRecordAdded(uint256 index, address pool, uint256 proposalId);

    /**
     * @dev Event emitted on service change
     * @param service Service address
     */
    event ServiceSet(address service);

    /**
     * @dev Event emitted on change of contract description
     * @param index Record index
     * @param description Description
     */
    event ContractDescriptionSet(uint256 index, string description);

    /**
     * @dev Event emitted on change of proposal description
     * @param index Record index
     * @param description Description
     */
    event ProposalDescriptionSet(uint256 index, string description);

    /**
     * @dev Event emitted on creation of event
     * @param eventType Event type
     * @param pool Pool address
     * @param proposalId Proposal ID
     */
    event EventSet(EventType eventType, address pool, uint256 proposalId);

    // event ProposalOrContractRecordAdded(
    //     uint256 index,
    //     address addr,
    //     ContractType contractType,
    //     address pool,
    //     uint256 proposalId
    // );

    // event ProposalOrContractDescriptionSet(uint256 index, string description);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once
     */
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

    /**
     * @dev Add contract record
     * @param addr Contract address
     * @param contractType Contract type
     * @return index Record index
     */
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

    /**
     * @dev Add proposal record
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @return index Record index
     */
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

    /**
     * @dev Add event record
     * @param pool Pool address
     * @param eventType Event type
     * @param proposalId Proposal ID
     * @param description Description
     * @param metaHash Hash value of event metadata
     * @return index Record index
     */
    function addEventRecord(
        address pool,
        EventType eventType,
        uint256 proposalId,
        string calldata description,
        string calldata metaHash
    ) external override onlyService returns (uint256 index) {
        index = ++lastEventIndex;
        events[index] = Event({
            eventType: eventType,
            pool: pool,
            proposalId: proposalId,
            description: description,
            metaHash: metaHash
        });

        emit EventSet(eventType, pool, proposalId);
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

    /**
     * @dev Set Service in Directory
     * @param service_ Service address
     */
    function setService(address service_) external onlyOwner {
        require(service_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        service = service_;
        emit ServiceSet(service_);
    }

    /**
     * @dev Set contract description at directory index
     * @param index Directory index
     * @param description Description
     */
    function setContractDescription(uint256 index, string memory description)
        external
        onlyOwner
    {
        contractRecordAt[index].description = description;
        emit ContractDescriptionSet(index, description);
    }

    /**
     * @dev Set proposal description at directory index
     * @param index Directory index
     * @param description Description
     */
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

    /**
     * @dev Return type of contract for a given address
     * @param addr Contract index
     * @return ContractType
     */
    function typeOf(address addr)
        external
        view
        override
        returns (ContractType)
    {
        return contractRecordAt[indexOfContract[addr]].contractType;
    }

    /**
     * @dev Return global proposal ID
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @return Global proposal ID
     */
    function getGlobalProposalId(address pool, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 1; i <= lastProposalRecordIndex; i++) {
            ProposalInfo memory proposalRecord = proposalRecordAt[i];
            if (
                (proposalRecord.pool == pool) &&
                (proposalRecord.proposalId == proposalId)
            ) {
                return i;
            }
        }
        return 0;
    }

    // MODIFIERS

    modifier onlyService() {
        require(msg.sender == service, ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    function test83122() external pure returns (uint256) {
        return 3;
    }
}
