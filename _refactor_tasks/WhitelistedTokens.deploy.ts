import { task } from "hardhat/config";

task("deploy:whitelistedTokens", "Deploy WhitelistedTokens contract").setAction(async function (
    { _ },
    { getNamedAccounts, deployments: { deploy } }
) {
    const { deployer } = await getNamedAccounts();

    return await deploy("WhitelistedTokens", {
        from: deployer,
        args: [],
        log: true,
    });
});
