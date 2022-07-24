// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";

contract Queue is OwnableUpgradeable {
    IService public service;

    enum Status {NotUsed, Used}

    struct Info {
        uint256 serialNumber;
        Status status;
        address lockedFor;
    }

    mapping(uint256 => Info) public regionToInfo;

    function initialize(address owner_) external initializer {
        service = IService(msg.sender);
        _transferOwnership(owner_);
    }

    function createRecord(uint256 region, uint256 serialNumber) external onlyService {
        if(regionToInfo[region].serialNumber > 1) {
            regionToInfo[region] = Info({serialNumber: serialNumber, status: Status.NotUsed, lockedFor: address(0)});
        } else {
            regionToInfo[region] = Info({serialNumber: serialNumber, status: Status.NotUsed, lockedFor: address(0)});
        }
    }

    function deleteRecord(uint256 region) external onlyOwner {
        require(
            (regionToInfo[region].serialNumber == 0) && (regionToInfo[region].status == Status.NotUsed) && (regionToInfo[region].lockedFor == address(0)), 
            "Can't delete non empty record"
        );

        delete regionToInfo[region];
    }

    modifier onlyService() {
        require(msg.sender == address(service), "Not service");
        _;
    }
}

