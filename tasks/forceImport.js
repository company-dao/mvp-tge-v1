const { getProxyAddress } = require("../helpers/proxymap");

task("forceImport", "").setAction(async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  if (accounts.length === 0) {
    console.log("Must specify signers");
    return;
  }

  await hre.run("compile");

  await hre.upgrades.forceImport(
    getProxyAddress("Dispatcher"),
    await hre.ethers.getContractFactory("Dispatcher"),
    { kind: "uups" }
  );

  await hre.upgrades.forceImport(
    getProxyAddress("ProposalGateway"),
    await hre.ethers.getContractFactory("ProposalGateway"),
    { kind: "uups" }
  );

  await hre.upgrades.forceImport(
    getProxyAddress("Pool"),
    await hre.ethers.getContractFactory("Pool"),
    { kind: "beacon" }
  );

  await hre.upgrades.forceImport(
    getProxyAddress("Token"),
    await hre.ethers.getContractFactory("Token"),
    { kind: "beacon" }
  );

  await hre.upgrades.forceImport(
    getProxyAddress("TGE"),
    await hre.ethers.getContractFactory("TGE"),
    { kind: "beacon" }
  );

  await hre.upgrades.forceImport(
    getProxyAddress("Service"),
    await hre.ethers.getContractFactory("Service"),
    { kind: "uups" }
  );

  console.log("\n==== Complete ====");
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
};
