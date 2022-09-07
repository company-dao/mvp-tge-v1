// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IDirectory {
  enum ContractType {
    None,
    Pool,
    GovernanceToken,
    TGE
  }

  function addContractRecord(address addr, ContractType contractType)
    external
    returns (uint256 index);

  function addProposalRecord(address pool, uint256 proposalId)
    external
    returns (uint256 index);

  function typeOf(address addr) external view returns (ContractType);
}
