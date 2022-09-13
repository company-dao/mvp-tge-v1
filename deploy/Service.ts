import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFunction: DeployFunction = async function ({
    run,
}: HardhatRuntimeEnvironment) {
    await run("deploy:directory", {});

    await run("deploy:proposalGateway", {});

    await run("deploy:whitelistedTokens", {});

    await run("deploy:metadata", {});

    await run("deploy:service", {});
};

export default deployFunction;

deployFunction.tags = ["Service"];
