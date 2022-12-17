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
        0,
        0
    ];
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

    let tx;
    const deployer = await hre.ethers.provider.getSigner().getAddress(); // "0x01d50e3899A79791c2448B9f489ae0Be30Dbd345"

    if (!(await service.isUserWhitelisted(deployer))) {
        tx = await service.addUserToWhitelist(deployer);
        await tx.wait(1);
    }

    const jurisdiction = 100000;
    const entityType = 1;
    const fee = 1000000000000000;
    let [available, _] = await dispatcher.poolAvailable(jurisdiction, entityType);
    if (available != 2) {
        tx = await dispatcher.createRecord(
            jurisdiction,
            "EIN" + nextMetadataId,
            "date",
            entityType,
            fee
        );
        await tx.wait(1);
    }

    const tokenData =
        [
            "SYMBOL" + nextMetadataId,
            "" + 10*10**18,
        ];

    console.log("Test1: incorrect fee passed to createPool");
    await expect(
        service
            .createPool(
                AddressZero, 
                tokenData, 
                tgeData, 
                [
                    5100,
                    5100,
                    25
                ], 
                jurisdiction, 
                ballotExecDelay, 
                "Name" + nextMetadataId, 
                entityType,
                "ipfs://QmNqLpTVKujSSzmNTbc2k3gxWG4TgiGhY69rvBUd851TrH",
                {
                value: (fee + 1),
            })
    ).to.be.revertedWith("INCORRECT_ETH_PASSED");
    console.log("   successfully passed");

    console.log("Test2: no company available");
    await expect(
        service
            .createPool(
                AddressZero, 
                tokenData, 
                tgeData, 
                [
                    5100,
                    5100,
                    25
                ], 
                jurisdiction + 1, 
                ballotExecDelay, 
                "Name" + nextMetadataId, 
                entityType,
                "ipfs://QmNqLpTVKujSSzmNTbc2k3gxWG4TgiGhY69rvBUd851TrH",
                {
                value: fee,
            })
    ).to.be.revertedWith("NO_COMPANY");
    console.log("   successfully passed");

    console.log("Test3: successful pool creature");
    await expect(
        service
            .createPool(
                AddressZero, 
                tokenData, 
                tgeData, 
                [
                    5100,
                    5100,
                    25
                ], 
                jurisdiction, 
                ballotExecDelay, 
                "Name" + nextMetadataId, 
                entityType,
                "ipfs://QmNqLpTVKujSSzmNTbc2k3gxWG4TgiGhY69rvBUd851TrH",
                {
                value: fee,
            })
    ).to.be.not.reverted;
    console.log("   successfully passed");

    console.log("\n==== Tests Successfully Passed ====");
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
};
