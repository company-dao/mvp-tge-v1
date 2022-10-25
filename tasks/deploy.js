const { setProxyAddress, getProxyAddress } = require("../helpers/proxymap");

const { getProxyFactoryDeployment, getSafeSingletonDeployment } = require("@gnosis.pm/safe-deployments");

task("deploy", "Deploys entire project").setAction(async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  if (accounts.length === 0) {
    console.log("Must specify signers");
    return;
  }

  const isForceCreateNewContracts = false;
  const isVerify = true;

  const fee = 0;
  const ballotQuorumThreshold = 50;
  const ballotDecisionThreshold = 50;
  const ballotLifespan = 25;

  const UNISWAP_ROUTER_ADDRESS = "0xe592427a0aece92de3edee1f18e0157c05861564";
  const UNISWAP_QUOTER_ADDRESS = "0xb27308f9f90d607463bb33ea1bebb41c27ce5ab6";

  /// @dev protocol token fee percentage value with 4 decimals. Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000
  const protocolTokenFee = 1000;

  /*
    Gnosis config
  */

  const proxyFactory = getProxyFactoryDeployment()
  const safeSingleton = getSafeSingletonDeployment()

  const chainID = "" + hre.network.config.chainId;
  if (chainID < 1) {
    console.log("Invalid chainID");
    return;
  }

  const gnosisProxyFactoryAddress = proxyFactory.networkAddresses[chainID];
  if (gnosisProxyFactoryAddress.length != 42) {
    console.log("Invalid gnosisProxyFactoryAddress");
    return;
  }
  const gnosisSingletonAddress = safeSingleton.networkAddresses[chainID];
  if (gnosisSingletonAddress.length != 42) {
    console.log("Invalid gnosisSingletonAddress");
    return;
  }

  // Deploy

  await hre.run("compile");

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
    contractName: "GnosisGovernance",
    proxyType: "beacon",
    constructorArguments: [],
    forceCreate: isForceCreateNewContracts,
    verify: isVerify,
  });

  if (getProxyAddress("GnosisSetup") == "") {
    const GnosisSetup = await ethers.getContractFactory("GnosisSetup");
    const gnosisSetup = await GnosisSetup.deploy();
    await gnosisSetup.deployed();

    setProxyAddress("GnosisSetup", gnosisSetup.address);

    console.log(`GnosisSetup deployed @ ${gnosisSetup.address}`);  
  }

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
      [ballotQuorumThreshold, ballotLifespan, ballotDecisionThreshold],
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

  t = await service.setGnosisProxyFactory(gnosisProxyFactoryAddress);
  await t.wait(1);
  console.log("gnosisProxyFactory is set in Service: " + gnosisProxyFactoryAddress);

  t = await service.setGnosisSingleton(gnosisSingletonAddress);
  await t.wait(1);
  console.log("gnosisSingleton is set in Service: " + gnosisSingletonAddress);

  t = await service.setGnosisGovernanceBeacon(getProxyAddress("GnosisGovernance"));
  await t.wait(1);
  console.log("GnosisGovernance is set in Service: " + getProxyAddress("GnosisGovernance"));

  t = await service.setGnosisSetup(getProxyAddress("GnosisSetup"));
  await t.wait(1);
  console.log("GnosisSetup is set in Service: " + getProxyAddress("GnosisSetup"));

  console.log("\n==== Project Deploy Complete ====");
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
};
