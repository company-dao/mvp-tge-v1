// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../interfaces/ITGE.sol";

contract Purchaser {
    ITGE public tge;

    constructor(ITGE tge_) {
        tge = tge_;
    }

    function purchase(uint256 amount) external payable {
        tge.purchase{value: msg.value}(amount);
    }

    function claimBack() external {
        tge.claimBack();
    }

    receive() external payable {}
}
