import { task } from "hardhat/config";

task("deploy:metadata", "Deploy Metadata contract").setAction(
    async function ({ _ }, { getNamedAccounts, deployments: { deploy } }) {
        const { deployer } = await getNamedAccounts();

        return await deploy("Metadata", {
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
