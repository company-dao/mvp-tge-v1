// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IMetadata.sol";
import "./libraries/ExceptionsLibrary.sol";

contract Metadata is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IMetadata
{
    IService public service;

    uint256 public currentId;

    mapping(uint256 => QueueInfo) public queueInfo;

    // EVENTS

    event ServiceSet(address service);

    event RecordCreated(
        uint256 id,
        uint256 jurisdiction,
        string EIN,
        string date,
        uint256 entityType
    );

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

    function setService(address service_) external onlyOwner {
        require(service_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        service = IService(service_);

        emit ServiceSet(service_);
    }

    function createRecord(
        uint256 jurisdiction,
        string memory EIN,
        string memory dateOfIncorporation,
        uint256 entityType
    ) external onlyOwner {
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

    function setOwner(uint256 id, address owner) external onlyService {
        queueInfo[id].owner = owner;
    }

    function deleteRecord(uint256 id) external onlyOwner {
        require(
            queueInfo[id].status == Status.NotUsed,
            ExceptionsLibrary.RECORD_IN_USE
        );

        delete queueInfo[id];
        emit RecordDeleted(id);
    }

    function getQueueInfo(uint256 id) external view returns (QueueInfo memory) {
        return queueInfo[id];
    }

    /*
        returns 0 if there are no available companies
        returns 1 if there are no available companies in current jurisdiction, but exists in other jurisdiction
        returns 2 if there are available companies in current jurisdiction 
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

    modifier onlyService() {
        require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
        _;
    }

}
