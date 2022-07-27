// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";

contract Queue is OwnableUpgradeable {
    IService public service;

    enum Status {NotUsed, Used}

    struct QueueInfo {
        uint256 jurisdiction;
        string serialNumber;
        Status status;
        address owner;
    }

    uint256 public currentId;

    mapping(uint256 => QueueInfo) public queueInfo;

    // EVENTS

    event RecordCreated(uint256 id, uint256 jurisdiction, string serialNumber);

    event RecordDeleted(uint256 id);

    function initialize() external initializer {
        service = IService(msg.sender);
        currentId = 0;
    }

    function createRecord(uint256 jurisdiction, string memory serialNumber) external onlyOwner {
        require(
            (jurisdiction > 0) && (bytes(serialNumber).length != 0), 
            "Invalid jurisdiction or serialNumber"
        );

        for (uint256 i = 0; i < currentId; i++) {
            require(
                queueInfo[i].jurisdiction != jurisdiction && 
                keccak256(abi.encodePacked(queueInfo[i].serialNumber)) != keccak256(abi.encodePacked(serialNumber)),
                "jurisdiction and serial number can't match"
            );
        }

        currentId += 1;
        queueInfo[currentId] = QueueInfo({jurisdiction: jurisdiction, serialNumber: serialNumber, status: Status.NotUsed, owner: address(0)});
        emit RecordCreated(currentId, jurisdiction, serialNumber);
    }

    function lockRecord(uint256 jurisdiction) external onlyService returns (uint256) {
        for (uint256 i = 0; i < currentId; i++) {
            if (queueInfo[i].jurisdiction == jurisdiction && (queueInfo[jurisdiction].status == Status.NotUsed)) {
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

    function getSerialNumber(uint256 id) external view returns (string memory) {
        return queueInfo[id].serialNumber;
    }

    modifier onlyService() {
        require(msg.sender == address(service), "Not service");
        _;
    }
}
