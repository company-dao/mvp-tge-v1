// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IMetadata.sol";

contract Metadata is IMetadata, OwnableUpgradeable {
    IService public service;

    uint256 public currentId;

    mapping(uint256 => QueueInfo) public queueInfo;

    // EVENTS

    event RecordCreated(
        uint256 id, 
        uint256 jurisdiction, 
        string serialNumber, 
        string dateOfIncorporation, 
        string legalAddress, 
        string taxationStatus
    );

    event RecordDeleted(uint256 id);

    function initialize(address owner_) external initializer {
        service = IService(msg.sender);
        _transferOwnership(owner_);
        currentId = 1;
    }

    function createRecord(
        uint256 jurisdiction, 
        string memory serialNumber, 
        string memory dateOfIncorporation, 
        string memory legalAddress, 
        string memory taxationStatus
    ) external onlyOwner {
        require(
            (jurisdiction > 0) && (bytes(serialNumber).length != 0), 
            "Invalid jurisdiction or serialNumber"
        );

        for (uint256 i = 0; i < currentId; i++) {
            require(
                queueInfo[i].jurisdiction != jurisdiction || 
                (
                    queueInfo[i].jurisdiction == jurisdiction && 
                    keccak256(abi.encodePacked(queueInfo[i].serialNumber)) != keccak256(abi.encodePacked(serialNumber))
                ),
                "jurisdiction must have different serial numbers"
            );
        }

        currentId += 1;
        queueInfo[currentId] = QueueInfo({
            jurisdiction: jurisdiction, 
            serialNumber: serialNumber, 
            dateOfIncorporation: dateOfIncorporation, 
            legalAddress: legalAddress, 
            taxationStatus: taxationStatus, 
            status: Status.NotUsed, 
            owner: address(0)});
        emit RecordCreated(currentId, jurisdiction, serialNumber, dateOfIncorporation, legalAddress, taxationStatus);
    }

    function lockRecord(uint256 jurisdiction) external onlyService returns (uint256) {
        for (uint256 i = 0; i <= currentId; i++) {
            if (queueInfo[i].jurisdiction == jurisdiction && (queueInfo[i].status == Status.NotUsed)) {
                queueInfo[i].status = Status.Used;
                return i; // queueInfo[i].serialNumber;
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
            "Record is in use"
        );

        delete queueInfo[id];
        emit RecordDeleted(id);
    }

    function getInfo(uint256 id) external view returns (string[4] memory) {
        return [
            queueInfo[id].serialNumber, 
            queueInfo[id].dateOfIncorporation, 
            queueInfo[id].legalAddress, 
            queueInfo[id].taxationStatus
        ];
    }

    function getQueueInfo(uint256 id) external view returns (QueueInfo memory) {
        return queueInfo[id];
    }

    /*
        returns 0 if there are no available companies
        returns 1 if there are no available companies in current jurisdiction, but exists in other jurisdiction
        returns 2 if there are available companies in current jurisdiction 
    */
    function jurisdictionAvailable(uint256 jurisdiction) external view returns (uint256) {
        uint256 flag = 0;
        for (uint256 i = 0; i < currentId; i++) {
            if (queueInfo[i].jurisdiction != jurisdiction && (queueInfo[i].status == Status.NotUsed)) {
                flag = 1;
            }

            if (queueInfo[i].jurisdiction == jurisdiction && (queueInfo[i].status == Status.NotUsed)) {
                return 2;
            }
        }

        return flag;
    }

    modifier onlyService() {
        require(msg.sender == address(service), "Not service");
        _;
    }
}