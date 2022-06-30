import { task } from "hardhat/config";
import { Directory } from "../typechain-types";

task("deploy:service", "Deploy Service contract")
    .addOptionalParam("fee", "Fee for TGE creation", "0")
    .addOptionalParam("proposalQuorum", "Proposal quorum", "30")
    .addOptionalParam("proposalThreshold", "Proposal threshold", "50")
    .setAction(async function (
        { fee, proposalQuorum, proposalThreshold },
        { getNamedAccounts, deployments: { deploy }, ethers: { getContract } }
    ) {
        const { deployer } = await getNamedAccounts();

        const directory = await getContract<Directory>("Directory");
        const proposalGateway = await getContract("ProposalGateway");

        const poolMaster = await deploy("Pool", {
            from: deployer,
            args: [],
            log: true,
        });

        const tokenMaster = await deploy("GovernanceToken", {
            from: deployer,
            args: [],
            log: true,
        });

        const tgeMaster = await deploy("TGE", {
            from: deployer,
            args: [],
            log: true,
        });

        const UNISWAP_ROUTER_ADDRESS =
            "0xe592427a0aece92de3edee1f18e0157c05861564";
        const UNISWAP_QUOTER_ADDRESS =
            "0xb27308f9f90d607463bb33ea1bebb41c27ce5ab6";

        const service = await deploy("Service", {
            from: deployer,
            args: [
                directory.address,
                poolMaster.address,
                proposalGateway.address,
                tokenMaster.address,
                tgeMaster.address,
                fee,
                proposalQuorum,
                proposalThreshold,
                UNISWAP_ROUTER_ADDRESS,
                UNISWAP_QUOTER_ADDRESS,
            ],
            log: true,
        });

        await directory.setService(service.address);
    });
