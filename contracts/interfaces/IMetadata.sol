// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IMetadata {
    enum Status {NotUsed, Used}

    struct QueueInfo {
        uint256 jurisdiction;
        string EIN;
        string dateOfIncorporation;
        uint256 entityType;
        Status status;
        address owner;
    }

    function initialize() external;

    function lockRecord(uint256 jurisdiction) external returns (uint256);

    function getQueueInfo(uint256 id) external view returns (QueueInfo memory);

    function setOwner(uint256 id, address owner) external;
}
