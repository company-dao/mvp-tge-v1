const { types } = require("hardhat/config");

task("safeVerify", "Verifies contract on Etherscan safely")
  .addParam(
    "implementation",
    "Smartcontract's implementation address",
    "0x",
    types.string
  )
  .addParam("proxy", "Smartcontract's proxy address", "0x", types.string)
  .addParam(
    "constructorArguments",
    "Smartcontract's constructor arguments",
    [],
    types.json
  )
  .setAction(async (taskArgs, hre) => {
    if (hre.network.config.chainId === 31337 || !hre.config.etherscan.apiKey) {
      console.log("Skipping verification");
      return;
    }

    // await contract.deployTransaction.wait(5);

    try {
      sleep(10000 * 1);
      console.log("Verifying ...");

      await hre.run("verify:verify", {
        address: taskArgs.implementation,
        constructorArguments: taskArgs.constructorArguments,
      });
    } catch (error) {
      if (error.message.includes("Contract source code already verified"))
        return;

      console.log(error);
      process.exitCode = 1;
    }
  });

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
};

function sleep(milliseconds) {
  console.log("Sleeping...");

  const date = Date.now();
  let currentDate = null;
  do {
    currentDate = Date.now();
  } while (currentDate - date < milliseconds);
}