import { task } from "hardhat/config";

task("deploy:proposalGateway", "Deploy ProposalGateway contract").setAction(
    async function ({ _ }, { getNamedAccounts, deployments: { deploy } }) {
        const { deployer } = await getNamedAccounts();

        return await deploy("ProposalGateway", {
            from: deployer,
            proxy: {
                proxyContract: "OpenZeppelinTransparentProxy",
                methodName: "initialize",
            },
            args: [],
            log: true,
        });
    }
);
