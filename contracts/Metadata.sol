// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IMetadata.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Protocol Metadata
contract Metadata is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IMetadata
{
    /// @dev Service address
    IService public service;

    /// @dev Last metadata ID
    uint256 public currentId;

    /// @dev Metadata queue
    mapping(uint256 => QueueInfo) public queueInfo;

    // EVENTS

    /**
     * @dev Event emitted on service change.
     * @param service Service address
     */
    event ServiceSet(address service);

    /**
     * @dev Event emitted on record creation.
     * @param id Record ID
     * @param jurisdiction Jurisdiction
     * @param EIN EIN
     * @param date Date
     * @param entityType Entity type
     */
    event RecordCreated(
        uint256 id,
        uint256 jurisdiction,
        string EIN,
        string date,
        uint256 entityType
    );

    /**
     * @dev Event emitted on record removal.
     * @param id Record ID
     */
    event RecordDeleted(uint256 id);

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        currentId = 0;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * @dev Set Service in Metadata
     * @param service_ Service address
     */
    function setService(address service_) external onlyOwner {
        require(service_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        service = IService(service_);

        emit ServiceSet(service_);
    }

    /**
     * @dev Create metadata record
     * @param jurisdiction Jurisdiction
     * @param EIN EIN
     * @param dateOfIncorporation Date of incorporation
     * @param entityType Entity type
     */
    function createRecord(
        uint256 jurisdiction,
        string memory EIN,
        string memory dateOfIncorporation,
        uint256 entityType
    ) public onlyManager {
        require(
            (jurisdiction > 0) && (bytes(EIN).length != 0),
            ExceptionsLibrary.VALUE_ZERO
        );
        currentId += 1;

        for (uint256 i = 1; i < currentId; i++) {
            require(
                queueInfo[i].jurisdiction != jurisdiction ||
                    (queueInfo[i].jurisdiction == jurisdiction &&
                        keccak256(abi.encodePacked(queueInfo[i].EIN)) !=
                        keccak256(abi.encodePacked(EIN))),
                ExceptionsLibrary.INVALID_EIN
            );
        }

        queueInfo[currentId] = QueueInfo({
            jurisdiction: jurisdiction,
            EIN: EIN,
            dateOfIncorporation: dateOfIncorporation,
            entityType: entityType,
            status: Status.NotUsed,
            owner: address(0)
        });

        emit RecordCreated(
            currentId,
            jurisdiction,
            EIN,
            dateOfIncorporation,
            entityType
        );
    }

    function createCompanies(uint256 amount) external onlyManager {
        for (uint256 i = 0; i < amount; i++) {
            createRecord(1, string(abi.encodePacked("102-00000", StringsUpgradeable.toString(currentId + 1))), "22.11.2022", 1);
        }
    }

    /**
     * @dev Lock metadata record
     * @param jurisdiction Jurisdiction
     * @return Record ID
     */
    function lockRecord(uint256 jurisdiction)
        external
        onlyService
        returns (uint256)
    {
        for (uint256 i = 1; i <= currentId; i++) {
            if (
                queueInfo[i].jurisdiction == jurisdiction &&
                (queueInfo[i].status == Status.NotUsed)
            ) {
                queueInfo[i].status = Status.Used;
                return i;
            }
        }
        return 0;
    }

    /**
     * @dev Set queue item owner
     * @param id Queue index
     * @param owner Owner address
     */
    function setOwner(uint256 id, address owner) external onlyService {
        queueInfo[id].owner = owner;
    }

    /**
     * @dev Delete queue record
     * @param id Queue index
     */
    function deleteRecord(uint256 id) external onlyManager {
        require(
            queueInfo[id].status == Status.NotUsed,
            ExceptionsLibrary.RECORD_IN_USE
        );

        delete queueInfo[id];
        emit RecordDeleted(id);
    }

    /**
     * @dev Get queue item
     * @param id Queue index
     * @return Queue item
     */
    function getQueueInfo(uint256 id) external view returns (QueueInfo memory) {
        return queueInfo[id];
    }

    /**
     * @dev Check if jurisdiction available
     * @param jurisdiction Jurisdiction
     * @return 0 if there are no available companies
     * 1 if there are no available companies in current jurisdiction, but exists in other jurisdiction
     * 2 if there are available companies in current jurisdiction
     */
    function jurisdictionAvailable(uint256 jurisdiction)
        external
        view
        returns (uint256)
    {
        uint256 flag = 0;
        for (uint256 i = 1; i <= currentId; i++) {
            if (
                queueInfo[i].jurisdiction != jurisdiction &&
                (queueInfo[i].status == Status.NotUsed)
            ) {
                flag = 1;
            }

            if (
                queueInfo[i].jurisdiction == jurisdiction &&
                (queueInfo[i].status == Status.NotUsed)
            ) {
                return 2;
            }
        }

        return flag;
    }

    function avaliableCompaniesCount(uint256 jurisdiction) external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= currentId; i++) {
            if (
                queueInfo[i].jurisdiction == jurisdiction &&
                queueInfo[i].status == Status.NotUsed
            ) {
                count += 1;
            }
        }
        return count;
    }

    modifier onlyService() {
        require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    modifier onlyManager() {
        require(
            msg.sender == service.owner() ||
                service.isManagerWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    function test82312() external pure returns (uint256) {
        return 3;
    }
}
