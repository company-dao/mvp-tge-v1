// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IPool {
    function initialize(address owner_) external;

    function setInfo(address token_, address tge_) external;

    function owner() external view returns (address);

    function tge() external view returns (address);
}
