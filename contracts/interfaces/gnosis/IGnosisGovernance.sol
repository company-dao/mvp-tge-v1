// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGnosisGovernance {
    function initialize(address _pool) external;

    function executeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;
}
