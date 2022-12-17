const { getProxyAddress } = require("../helpers/proxymap");

task("createPool", "Sets up pool").setAction(async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  if (accounts.length === 0) {
    console.log("Must specify signers");
    return;
  }

  const blockNumBefore = await ethers.provider.getBlockNumber();
  const ballotExecDelay = [1, 3, 40, 40, 40, 0, 0, 0, 0, 0]; // number of blocks

  const service = await ethers.getContractAt(
    "Service",
    getProxyAddress("Service")
  );

  const dispatcher = await ethers.getContractAt(
    "Dispatcher",
    getProxyAddress("Dispatcher")
  );

  const metadataCurrentId = await dispatcher.currentId();
  const nextMetadataId = metadataCurrentId.toNumber() + 1;
  console.log("nextMetadataId: " + nextMetadataId);

  // let t = await service.addUserToWhitelist("0x01d50e3899A79791c2448B9f489ae0Be30Dbd345");
  // await t.wait(1);

  let tx;
  const deployer = await hre.ethers.provider.getSigner().getAddress(); // "0x01d50e3899A79791c2448B9f489ae0Be30Dbd345"

  if (!(await service.isUserWhitelisted(deployer))) {
    tx = await service.addUserToWhitelist(deployer);
    await tx.wait(1);
  } 

  t = await dispatcher.createRecord(
    nextMetadataId,
    "serial",
    "date",
    123123,
    1000000000000000
  );
  await t.wait(1);

  console.log("Creating pool...");

  t = await service.createPool(
    "0x0000000000000000000000000000000000000000",
    [
        "SYMBOL"+nextMetadataId,
        "" + 10*10**18,
    ],
    [
        "ipfs://QmNqLpTVKujSSzmNTbc2k3gxWG4TgiGhY69rvBUd851TrH",
        "" + 3*10**16,
        "" + 5*10**18,
        "" + 1*10**18,
        "" + 1*10**10,
        "" + 20*10**18,
        "34",
        "0",
        "1000000000000000000",
        "1041",
        [],
        "0x0000000000000000000000000000000000000000",
    ],
    "1",
    "1",
    "10",
    nextMetadataId,
    ballotExecDelay,
    "hhhj"+nextMetadataId,
    123123,
    {value: 1000000000000000}
    );
  await t.wait(1);

  console.log("\n==== Task Complete ====");
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
};
