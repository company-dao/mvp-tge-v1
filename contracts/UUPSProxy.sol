// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Kept for backwards compatibility with older versions of Hardhat and Truffle plugins.
contract UUPSProxy is ERC1967Proxy {
  constructor(
    address _logic,
    address, 
    bytes memory _data
  ) payable ERC1967Proxy(_logic, _data) {}
}