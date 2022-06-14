// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IDirectory.sol";
import "./ITGE.sol";

interface IService {
    function createSecondaryTGE(ITGE.TGEInfo memory tgeInfo) external;

    function addProposal(uint256 proposalId) external;

    function directory() external view returns (IDirectory);
}
