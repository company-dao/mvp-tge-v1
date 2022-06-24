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
        uint256 lockupDuration;
        uint256 lockupTVL;
        uint256 duration;
        address[] whitelist;
    }

    function initialize(
        address owner_,
        address token_,
        TGEInfo memory info
    ) external;

    function purchase(uint256 amount) external payable;

    function claimBack() external;

    function transferFunds() external;

    function maxPurchaseOf(address account) external view returns (uint256);

    enum State {
        Active,
        Failed,
        Successful
    }

    function state() external view returns (State);
}
