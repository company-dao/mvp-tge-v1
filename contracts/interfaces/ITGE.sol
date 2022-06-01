// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ITGE {
    struct TGEInfo {
        string metadataURI;
        uint256 price;
        uint256 hardcap;
        uint256 softcap;
        uint256 minPurchase;
        uint256 maxPurchase;
        uint256 lockupPercent;
        uint256 duration;
    }

    function initialize(address token_, TGEInfo memory info) external;

    enum State {
        Active,
        Failed,
        Successful
    }

    function state() external view returns (State);
}
