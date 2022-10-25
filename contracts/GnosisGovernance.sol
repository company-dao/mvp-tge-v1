// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IPool.sol";
import "./interfaces/gnosis/IGnosisSafe.sol";
import "./libraries/ExceptionsLibrary.sol";

pragma solidity 0.8.17;

contract GnosisGovernance is Initializable {
    string public constant NAME = "Governance Module";
    string public constant VERSION = "0.1.0";

    address public pool;

    // EVENTS

    event GnosisExecutedTransfer(address token, address to, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _pool) public initializer {
        require(_pool != address(0), "ZERO_ADDRESS");

        pool = _pool;
    }

    /// @dev Allows Pool.executeBallot to transfer tokens from Gnosis Safe
    /// @param token Token contract address.
    /// @param to Address that should receive the tokens.
    /// @param amount Amount that should be transferred.
    function executeTransfer(
        address token,
        address payable to,
        uint256 amount
    ) public onlyPool {
        // TODO daily limits
        // TODO secure changing daily limits
        // TODO Gnosis guards

        transfer(token, to, amount);
        emit GnosisExecutedTransfer(token, to, amount);
    }

    function transfer(
        address token,
        address payable to,
        uint256 amount
    ) private {
        if (token == address(0)) {
            // solium-disable-next-line security/no-send
            require(
                IGnosisSafe(IPool(pool).gnosisSafe()).execTransactionFromModule(
                    to,
                    amount,
                    "",
                    Operation.Call
                ),
                ExceptionsLibrary.ETH_TRANSFER_FAIL
            );
        } else {
            bytes memory data = abi.encodeWithSignature(
                "transfer(address,uint256)",
                to,
                amount
            );
            require(
                IGnosisSafe(IPool(pool).gnosisSafe()).execTransactionFromModule(
                    token,
                    0,
                    data,
                    Operation.Call
                ),
                ExceptionsLibrary.TOKEN_TRANSFER_FAIL
            );
        }
    }

    // MODIFIER

    modifier onlyPool() {
        require(msg.sender == address(pool), ExceptionsLibrary.NOT_POOL);
        _;
    }

    function testI3813() public pure returns (uint256) {
        return uint256(123);
    }
}
