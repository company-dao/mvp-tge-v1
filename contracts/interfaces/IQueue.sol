// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IQueue {
    function initialize() external;

    function lockRecord(uint256 jurisdiction) external returns (uint256);

    function getSerialNumber(uint256 id) external view returns (string memory);

    function setOwner(uint256 id, address owner) external;
}
