import { task } from "hardhat/config";

task("upgrade:pool", "Upgrade Pool Beacon")
    .setAction(async function ( { _ },
        { getNamedAccounts, ethers: { getContractFactory }, upgrades: { deployBeacon, upgradeBeacon } }
    ) {
        const { deployer } = await getNamedAccounts();

        const pool = await getContractFactory("Pool");
        const poolBeaconAddress = "0x73df0a68c85CBFeF108EC6664447cAeEf4E15315";
        await upgradeBeacon(poolBeaconAddress, pool);
        console.log("PoolBeacon deployed to: ", poolBeaconAddress);
     
    });
