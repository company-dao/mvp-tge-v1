import { task } from "hardhat/config";

task("deploy:directory", "Deploy Directory contract").setAction(async function (
    { _ },
    { getNamedAccounts, deployments: { deploy } }
) {
    const { deployer } = await getNamedAccounts();

    return await deploy("Directory", {
        from: deployer,
        proxy: {
            proxyContract: "UUPSProxy",
            methodName: "initialize",
        },
        args: [],
        log: true,
    });
});
