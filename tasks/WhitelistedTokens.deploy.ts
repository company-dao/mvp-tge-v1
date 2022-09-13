import { task } from "hardhat/config";

task("deploy:whitelistedTokens", "Deploy WhitelistedTokens contract").setAction(async function (
    { _ },
    { getNamedAccounts, deployments: { deploy } }
) {
    const { deployer } = await getNamedAccounts();

    return await deploy("WhitelistedTokens", {
        from: deployer,
        proxy: {
            proxyContract: "UUPSProxy",
            methodName: "initialize",
        },
        args: [],
        log: true,
    });
});
