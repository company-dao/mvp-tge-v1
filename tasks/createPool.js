const { getProxyAddress } = require("../helpers/proxymap");

task("createPool", "Sets up pool").setAction(async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  if (accounts.length === 0) {
    console.log("Must specify signers");
    return;
  }

  const blockNumBefore = await ethers.provider.getBlockNumber();

  const service = await ethers.getContractAt(
    "Service",
    getProxyAddress("Service")
  );

  const tge = await ethers.getContractAt(
    "TGE",
    getProxyAddress("TGE")
  );

  const pool = await ethers.getContractAt(
    "Pool",
    getProxyAddress("Pool")
  );

  const metadata = await ethers.getContractAt(
    "Metadata",
    getProxyAddress("Metadata")
  );

  const metadataCurrentId = await metadata.currentId();
  const nextMetadataId = metadataCurrentId.toNumber() + 1;
  console.log("nextMetadataId: " + nextMetadataId);

  // let t = await service.addUserToWhitelist("0x613e46D06A3667D2b46bf6C0d9689aA17DbFCAbc");
  // await t.wait(1);

  t = await metadata.createRecord(
    nextMetadataId,
    "serial",
    "date",
    123123,
  );
  await t.wait(1);

  t = await service.createPool(
    "0x0000000000000000000000000000000000000000",
    [
        "NAME"+nextMetadataId,
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
    "505",
    nextMetadataId,
    "hhhj"+nextMetadataId,
    {value: 10000000000000}
    );
  await t.wait(1);

  console.log("\n==== Task Complete ====");
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
};
