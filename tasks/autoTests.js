const { getProxyAddress } = require("../helpers/proxymap");
const { expect } = require("chai");
const Exceptions = require("../test/shared/Exceptions");

task("autoTests", "Runs automated tests after push").setAction(async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();
    if (accounts.length === 0) {
        console.log("Must specify signers");
        return;
    }

    const { AddressZero } = ethers.constants;
    const tgeData = [
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
        AddressZero,
    ];
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const ballotExecDelay = [1, 3, 40, 40, 40, 0, 0, 0, 0, 0]; // number of blocks

    const service = await ethers.getContractAt(
        "Service",
        getProxyAddress("Service")
    );

    const metadata = await ethers.getContractAt(
        "Metadata",
        getProxyAddress("Metadata")
    );

    const metadataCurrentId = await metadata.currentId();
    const nextMetadataId = metadataCurrentId.toNumber() + 1;
    console.log("nextMetadataId: " + nextMetadataId);

    // let tx = await service.addUserToWhitelist("0x01d50e3899A79791c2448B9f489ae0Be30Dbd345");
    // await tx.wait(1);

    let tx;

    const jurisdiction = 100000;
    const jurisdictionAvailable = await metadata.jurisdictionAvailable(jurisdiction);
    if (jurisdictionAvailable != 2) {
        tx = await metadata.createRecord(
            jurisdiction,
            "serial"+nextMetadataId,
            "date",
            123123,
        );
        await tx.wait(1);
    }
    
    const tokenData =
        [
            "NAME"+nextMetadataId,
            "SYMBOL"+nextMetadataId,
            "" + 10*10**18,
        ];

    console.log("Test1: incorrect fee passed to createPool");
    const fee = await service.fee();
    await expect(
        service
            .createPool(AddressZero, tokenData, tgeData, 50, 50, 25, jurisdiction, ballotExecDelay, "Name"+nextMetadataId, {
                value: (fee + 1),
            })
    ).to.be.revertedWith("INCORRECT_ETH_PASSED");
    console.log("   successfully passed");

    console.log("Test2: no company available");
    await expect(
        service
            .createPool(AddressZero, tokenData, tgeData, 50, 50, 25, jurisdiction + 1, ballotExecDelay, "Name"+nextMetadataId, {
                value: fee,
            })
    ).to.be.revertedWith("NO_COMPANY");
    console.log("   successfully passed");

    console.log("Test3: successful pool creature");
    await expect(
        service
            .createPool(AddressZero, tokenData, tgeData, 50, 50, 25, jurisdiction, ballotExecDelay, "Name"+nextMetadataId, {
                value: fee,
            })
    ).to.be.not.reverted;
    console.log("   successfully passed");

    console.log("\n==== Tests Successfully Passed ====");
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
};
