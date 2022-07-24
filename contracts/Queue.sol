// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";

contract Queue is OwnableUpgradeable {
    IService public service;

    enum Status {NotUsed, Used}

    struct QueueInfo {
        uint256 region;
        string serialNumber;
        Status status;
        address owner;
    }

    uint256 public currentId;

    mapping(uint256 => QueueInfo) public queueInfo;

    // EVENTS

    event RecordCreated(uint256 id, uint256 region, string serialNumber);

    event RecordDeleted(uint256 id);

    function initialize() external initializer { // TODO: service owner = Queue owner
        service = IService(msg.sender);
        currentId = 0;
    }

    function createRecord(uint256 region, string memory serialNumber) external onlyOwner {
        for (uint256 i = 0; i < currentId; i++) {
            require(
                queueInfo[i].region != region && 
                keccak256(abi.encodePacked(queueInfo[i].serialNumber)) != keccak256(abi.encodePacked(serialNumber)),
                "Region and serial number can't match"
            );
        }

        currentId += 1;
        queueInfo[currentId] = QueueInfo({region: region, serialNumber: serialNumber, status: Status.NotUsed, owner: address(0)});
        emit RecordCreated(currentId, region, serialNumber);
    }

    function lockRecord(uint256 region) external onlyService returns (string memory) {
        for (uint256 i = 0; i < currentId; i++) {
            if (queueInfo[i].region == region && (queueInfo[region].status == Status.NotUsed)) {
                queueInfo[i].status = Status.NotUsed;
                return queueInfo[i].serialNumber;
            }
        }
        return "";
    }

    function deleteRecord(uint256 id) external onlyOwner {
        require(
            queueInfo[id].status == Status.NotUsed, 
            "Record is in use"
        );

        delete queueInfo[id];
        emit RecordDeleted(id);
    }

    modifier onlyService() {
        require(msg.sender == address(service), "Not service");
        _;
    }
}

