// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDirectory.sol";

contract Directory is IDirectory, Ownable {
    struct ContractInfo {
        address addr;
        ContractType contractType;
    }

    mapping(uint256 => ContractInfo) public contractRecordAt;

    uint256 public lastContractRecordIndex;

    mapping(address => uint256) public indexOfContract;

    struct ProposalInfo {
        address pool;
        uint256 proposalId;
    }

    mapping(uint256 => ProposalInfo) public proposalRecordAt;

    uint256 public lastProposalRecordIndex;

    // EVENTS

    event ContractRecordAdded(
        uint256 index,
        address addr,
        ContractType contractType
    );

    event ProposalRecordAdded(uint256 index, address pool, uint256 proposalId);

    // PUBLIC FUNCTIONS

    function addContractRecord(address addr, ContractType contractType)
        external
        override
        onlyOwner
        returns (uint256 index)
    {
        index = ++lastContractRecordIndex;
        contractRecordAt[index] = ContractInfo({
            addr: addr,
            contractType: contractType
        });
        indexOfContract[addr] = index;

        emit ContractRecordAdded(index, addr, contractType);
    }

    function addProposalRecord(address pool, uint256 proposalId)
        external
        override
        onlyOwner
        returns (uint256 index)
    {
        index = ++lastProposalRecordIndex;
        proposalRecordAt[index] = ProposalInfo({
            pool: pool,
            proposalId: proposalId
        });

        emit ProposalRecordAdded(index, pool, proposalId);
    }

    // PUBLIC VIEW FUNCTIONS

    function typeOf(address addr)
        external
        view
        override
        returns (ContractType)
    {
        return contractRecordAt[indexOfContract[addr]].contractType;
    }
}
