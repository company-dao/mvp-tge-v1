import { task } from "hardhat/config";

task("deploy:service", "Deploy Service contract")
    .addOptionalParam("fee", "Fee for TGE creation", "0")
    .setAction(async function (
        { fee },
        { getNamedAccounts, deployments: { deploy } }
    ) {
        const { deployer } = await getNamedAccounts();

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

        return await deploy("Service", {
            from: deployer,
            args: [tokenMaster.address, tgeMaster.address, fee],
            log: true,
        });
    });
