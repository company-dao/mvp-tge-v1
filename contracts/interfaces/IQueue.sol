// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IService.sol";
import "./ITGE.sol";
import "./IGovernanceToken.sol";

interface IQueue {
    function initialize(address owner_) external;

    function createRecord(uint256 region, uint256 serialNumber) external;
}
