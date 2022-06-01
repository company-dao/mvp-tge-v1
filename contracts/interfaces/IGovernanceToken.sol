// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IGovernanceToken is IERC20Upgradeable {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 cap_,
        address tge_
    ) external;

    function mint(
        address to,
        uint256 amount,
        uint256 locked
    ) external;

    function burn(address from) external;

    function cap() external view returns (uint256);
}
