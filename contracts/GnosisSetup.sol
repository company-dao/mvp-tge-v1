// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract GnosisSetup {
    address internal singleton;

    address internal constant SENTINEL_MODULES = address(0x1);

    mapping(address => address) internal modules;

    constructor() {
        singleton = SENTINEL_MODULES;
    }

    function enableModule(address module) external {
        // Module address cannot be null or sentinel.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        // Module cannot be added twice.
        require(modules[module] == address(0), "GS102");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
    }

    function testI3813() public pure returns (uint256) {
        return uint256(123);
    }
}
