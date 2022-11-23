const { setProxyAddress, getProxyAddress } = require("../helpers/proxymap");

// const { getProxyFactoryDeployment, getSafeSingletonDeployment } = require("@gnosis.pm/safe-deployments");

task("deploy", "Deploys entire project").setAction(async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  if (accounts.length === 0) {
    console.log("Must specify signers");
    return;
  }

  const isForceCreateNewContracts = false;
  const isVerify = true;

  const fee = 0;
  const ballotQuorumThreshold = 5100;
  const ballotDecisionThreshold = 7500;
  const ballotLifespan = 23;
  const ballotExecDelay = [1, 3, 40, 40, 40, 0, 0, 0, 0, 0]; // number of blocks

  const UNISWAP_ROUTER_ADDRESS = "0xe592427a0aece92de3edee1f18e0157c05861564";
  const UNISWAP_QUOTER_ADDRESS = "0xb27308f9f90d607463bb33ea1bebb41c27ce5ab6";
  const USDT_ADDRESS = "0xe583769738b6dd4e7caf8451050d1948be717679";
  const WETH_ADDRESS = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6";

  // protocol token fee percentage value with 4 decimals. Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000
  const protocolTokenFee = 1000;

  // Deploy

  await hre.run("compile");

  await hre.run("docgen");

  await hre.run("deployContract", {
    contractName: "Directory",
    proxyType: "uups",
    constructorArguments: [],
    forceCreate: isForceCreateNewContracts,
    verify: isVerify,
  });

  await hre.run("deployContract", {
    contractName: "ProposalGateway",
    proxyType: "uups",
    constructorArguments: [],
    forceCreate: isForceCreateNewContracts,
    verify: isVerify,
  });

  await hre.run("deployContract", {
    contractName: "WhitelistedTokens",
    proxyType: "uups",
    constructorArguments: [],
    forceCreate: isForceCreateNewContracts,
    verify: isVerify,
  });

  await hre.run("deployContract", {
    contractName: "Metadata",
    proxyType: "uups",
    constructorArguments: [],
    forceCreate: isForceCreateNewContracts,
    verify: isVerify,
  });

  await hre.run("deployContract", {
    contractName: "Pool",
    proxyType: "beacon",
    constructorArguments: [],
    forceCreate: isForceCreateNewContracts,
    verify: isVerify,
  });

  await hre.run("deployContract", {
    contractName: "GovernanceToken",
    proxyType: "beacon",
    constructorArguments: [],
    forceCreate: isForceCreateNewContracts,
    verify: isVerify,
  });

  await hre.run("deployContract", {
    contractName: "TGE",
    proxyType: "beacon",
    constructorArguments: [],
    forceCreate: isForceCreateNewContracts,
    verify: isVerify,
  });

  await hre.run("deployContract", {
    contractName: "Service",
    proxyType: "uups",
    constructorArguments: [
      getProxyAddress("Directory"),
      getProxyAddress("Pool"),
      getProxyAddress("ProposalGateway"),
      getProxyAddress("GovernanceToken"),
      getProxyAddress("TGE"),
      getProxyAddress("Metadata"),
      fee,
      [ballotQuorumThreshold, ballotLifespan, ballotDecisionThreshold, ...ballotExecDelay],
      UNISWAP_ROUTER_ADDRESS,
      UNISWAP_QUOTER_ADDRESS,
      getProxyAddress("WhitelistedTokens"),
      protocolTokenFee
    ],
    forceCreate: isForceCreateNewContracts,
    verify: isVerify,
  });

  const directory = await ethers.getContractAt(
    "Directory",
    getProxyAddress("Directory")
  );
  let t = await directory.setService(getProxyAddress("Service"));
  await t.wait(1);
  console.log("Service is set in Directory");

  const metadata = await ethers.getContractAt(
    "Metadata",
    getProxyAddress("Metadata")
  );
  t = await metadata.setService(getProxyAddress("Service"));
  await t.wait(1);
  console.log("Service is set in Metadata");

  /*
    Set Service values
  */

  const service = await ethers.getContractAt(
    "Service",
    getProxyAddress("Service")
  );

  t = await service.setUsdt(USDT_ADDRESS);
  await t.wait(1);
  console.log("usdt is set in Service: " + USDT_ADDRESS);

  t = await service.setWeth(WETH_ADDRESS);
  await t.wait(1);
  console.log("weth is set in Service: " + WETH_ADDRESS);

  const whitelistedTokens = await ethers.getContractAt(
    "WhitelistedTokens",
    getProxyAddress("WhitelistedTokens")
  );

  t = await whitelistedTokens.addTokensToWhitelist(
    ["0x0000000000000000000000000000000000000000"],
    ["0x"],
    ["0x"]
  );
  await t.wait(1);
  console.log("ETH is added to WhitelistedTokens");

  console.log("\n==== Project Deploy Complete ====");
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
};
