// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IQueue {
    enum Status {NotUsed, Used}

    struct QueueInfo {
        uint256 jurisdiction;
        string serialNumber;
        string dateOfIncorporation;
        string legalAddress;
        string taxationStatus;
        Status status;
        address owner;
    }

    function initialize(address owner_) external;

    function lockRecord(uint256 jurisdiction) external returns (uint256);

    function getInfo(uint256 id) external view returns (string[4] memory);

    function setOwner(uint256 id, address owner) external;
}
