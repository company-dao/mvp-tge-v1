// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Pool is OwnableUpgradeable {
    address public service;

    address public token;

    address public tge;

    function initialize(address owner_) external initializier {
        service = msg.sender;
        _transferOwnership(owner_);
    }

    function setInfo(address token_, address tge_) external onlyService {
        token = token_;
        tge = tge_;
    }

    modifier onlyService() {
        require(msg.sender == service, "Not service");
        _;
    }
}
