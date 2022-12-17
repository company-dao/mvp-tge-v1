const { types } = require("hardhat/config");
const { setProxyAddress, getProxyAddress } = require("../helpers/proxymap");

task("deployContract", "Deploys a single contract")
  .addParam("contractName", "Smartcontract's name", "0x0", types.string)
  .addParam(
    "constructorArguments",
    "Smartcontract's constructor arguments",
    [],
    types.json
  )
  .addParam(
    "forceCreate",
    "Creates new proxy and implementation instead of upgrading",
    false,
    types.boolean
  )
  .addParam("verify", "Verifies on Etherscan", false, types.boolean)
  .addParam("proxyType", "Proxy type: UUPS or beacon", "uups", types.string)
  .setAction(async (taskArgs, hre) => {
    let proxyAddress = getProxyAddress(taskArgs.contractName);
    const isUpgrade =
      proxyAddress !== "" && !taskArgs.forceCreate ? true : false;

    console.log("\n==== " + taskArgs.contractName + " ====");
    console.log(isUpgrade ? "Upgrading..." : "Deploying...");

    const factory = await hre.ethers.getContractFactory(taskArgs.contractName);

    let pAddress = "0x0";
    let iAddress = "0x0";

    if (taskArgs.proxyType === "uups") {
      const proxy = !isUpgrade
        ? await hre.upgrades.deployProxy(
            factory,
            taskArgs.constructorArguments,
            { kind: "uups" }
          )
        : await hre.upgrades.upgradeProxy(proxyAddress, factory, {
            kind: "uups",
          });
      await proxy.deployed();

      const implementation =
        await hre.upgrades.erc1967.getImplementationAddress(proxy.address);

      pAddress = proxy.address;
      iAddress = implementation;
    }

    if (taskArgs.proxyType === "beacon") {
      const proxy = !isUpgrade
        ? await hre.upgrades.deployBeacon(factory)
        : await hre.upgrades.upgradeBeacon(proxyAddress, factory);
      await proxy.deployed();

      const implementation = await hre.upgrades.beacon.getImplementationAddress(
        proxy.address
      );

      pAddress = proxy.address;
      iAddress = implementation;
    }

    setProxyAddress(taskArgs.contractName, pAddress);

    console.log(
      isUpgrade ? "Kept proxy @ " + pAddress : "Deployed proxy @ " + pAddress
    );
    console.log("Deployed implementation @ " + iAddress);

    if (!taskArgs.verify) return;

    await hre.run("safeVerify", {
      proxy: pAddress,
      implementation: iAddress,
      constructorArguments: [],
    });
  });

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
};
