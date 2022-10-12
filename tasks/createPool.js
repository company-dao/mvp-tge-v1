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

//  let t = await service.addUserToWhitelist("0x19D3d9B224770c7c55CC471aAC68A566a701DE34");
//  await t.wait(1);

  t = await metadata.createRecord(
    nextMetadataId,
    "serial",
    "date",
    "address",
    "taxation",
    "name",
  );
  await t.wait(1);

t = await service.createPool(
    "0x0000000000000000000000000000000000000000",
    [
        "NAME"+nextMetadataId,
        "SYMBOL"+nextMetadataId,
        "11113311",
    ],
    [
      "ipfs://QmNqLpTVKujSSzmNTbc2k3gxWG4TgiGhY69rvBUd851TrH",
      "10000000000000000000000000",
      "90000000000000000000000000000",
      "2000000000000000000000000000",
      "1000000000000000000000000",
      "20000000000000000000000000",
      "50",
      "40",
      "1000000000000000000",
      "1041",
      [],
      "0x0000000000000000000000000000000000000000",
  ],
    "2000",
    "5000",
    "205",
    nextMetadataId,
    "hhhj"+nextMetadataId
    );
  await t.wait(1);
 // [
    //     "ipfs://QmNqLpTVKujSSzmNTbc2k3gxWG4TgiGhY69rvBUd851TrH",
    //     "40000000",
    //     "1111",
    //     "1000",
    //     "111",
    //     "1111",
    //     "34",
    //     "0",
    //     "1000000000000000000",
    //     "1041",
    //     [],
    //     "0x0000000000000000000000000000000000000000",
    // ],
  console.log("\n==== Task Complete ====");
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
};
