// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IGovernanceToken is IERC20Upgradeable {
    struct TokenInfo {
        string name;
        string symbol;
        uint256 cap;
    }

    function initialize(address tge_, TokenInfo memory info) external;

    function mint(
        address to,
        uint256 amount,
        uint256 locked
    ) external;

    function burn(address from) external;

    function cap() external view returns (uint256);
}
