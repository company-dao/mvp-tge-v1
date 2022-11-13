// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IProposalGateway {
    enum ProposalType {
        None,
        TransferETH,
        TransferERC20,
        TGE,
        GovernanceSettings
    }
}
