// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IQueue {
    function initialize() external;

    function lockRecord(uint256 region) external;
}
