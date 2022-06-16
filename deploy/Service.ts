import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFunction: DeployFunction = async function ({
    run,
}: HardhatRuntimeEnvironment) {
    await run("deploy:directory", {});

    await run("deploy:service", {});
};

export default deployFunction;

deployFunction.dependencies = ["Directory"];

deployFunction.tags = ["Service"];
