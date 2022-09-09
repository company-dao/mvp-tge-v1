// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IService.sol";

interface IGovernanceToken is IERC20Upgradeable {
    struct TokenInfo {
        string name;
        string symbol;
        uint256 cap;
    }

    function initialize(address pool_, TokenInfo memory info) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function lock(
        address account,
        uint256 amount,
        bool support, 
        uint256 deadline,
        uint256 proposalId
    ) external;

    function cap() external view returns (uint256);

    function unlockedBalanceOf(address account, uint256 proposalId) external view returns (uint256);

    function pool() external view returns (address);

    function service() external view returns (IService);
}
