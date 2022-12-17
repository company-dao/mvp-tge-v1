import { ethers, run } from "hardhat";
import {
    ERC20Mock,
    Pool,
    ProposalGateway,
    Metadata,
    WhitelistedTokens,
    Service,
    TGE,
    Directory,
} from "../../typechain-types";
import {
    GovernanceToken,
    TokenInfoStruct,
} from "../../typechain-types/GovernanceToken";
import { TGEInfoStruct } from "../../typechain-types/IService";


// import { getProxyAddress } from "../../helpers/proxymap";
import { hrtime } from "process";

const { getContract, getContractAt, getSigners } = ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

import { readFileSync, writeFileSync } from "fs";
const filename = "./contract_proxy_address_map.json";

function getProxyAddress(contractName: any) {
  const addresses = JSON.parse((readFileSync(filename)).toString());
  return addresses[contractName] ? addresses[contractName] : "";
}

function setProxyAddress(contractName: any, proxyAddress: any) {
    let addresses = JSON.parse((readFileSync(filename)).toString());
  
    addresses[contractName] = proxyAddress;
  
    writeFileSync(filename, JSON.stringify(addresses));
}

export async function setup() {
    const [owner, other] = await getSigners();

    // Mocks and uniswap

    // const token1 = await getContract<ERC20Mock>("ONE");
    // const token2 = await getContract<ERC20Mock>("TWO");
    // const token3 = await getContract<ERC20Mock>("THREE");

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const Token1 = await ERC20Mock.deploy("ONE", "ONE");
    await Token1.deployed();
    const token1: ERC20Mock = await getContractAt("ERC20Mock", Token1.address);
    const Token2 = await ERC20Mock.deploy("TWO", "TWO");
    await Token2.deployed();
    const token2: ERC20Mock = await getContractAt("ERC20Mock", Token2.address);
    const Token3 = await ERC20Mock.deploy("THREE", "THREE");
    await Token3.deployed();
    const token3: ERC20Mock = await getContractAt("ERC20Mock", Token3.address);


    // Add liquitiy to uniswap

    // await run("addUniswapLiquidity");

    // Deploy contracts

    // await run("deploy");

    const isForceCreateNewContracts = false;
    const isVerify = true;

    const fee = 0;
    const ballotQuorumThreshold = 50;
    const ballotDecisionThreshold = 50;
    const ballotLifespan = 25;

    const UNISWAP_ROUTER_ADDRESS = "0xe592427a0aece92de3edee1f18e0157c05861564";
    const UNISWAP_QUOTER_ADDRESS = "0xb27308f9f90d607463bb33ea1bebb41c27ce5ab6";

    await run("compile");

    await run("deployContract", {
        contractName: "Directory",
        proxyType: "uups",
        constructorArguments: [],
        forceCreate: isForceCreateNewContracts,
        verify: isVerify,
    });

    await run("deployContract", {
        contractName: "ProposalGateway",
        proxyType: "uups",
        constructorArguments: [],
        forceCreate: isForceCreateNewContracts,
        verify: isVerify,
    });

    await run("deployContract", {
        contractName: "WhitelistedTokens",
        proxyType: "uups",
        constructorArguments: [],
        forceCreate: isForceCreateNewContracts,
        verify: isVerify,
    });

    await run("deployContract", {
        contractName: "Metadata",
        proxyType: "uups",
        constructorArguments: [],
        forceCreate: isForceCreateNewContracts,
        verify: isVerify,
    });

    await run("deployContract", {
        contractName: "Pool",
        proxyType: "beacon",
        constructorArguments: [],
        forceCreate: isForceCreateNewContracts,
        verify: isVerify,
    });

    await run("deployContract", {
        contractName: "GovernanceToken",
        proxyType: "beacon",
        constructorArguments: [],
        forceCreate: isForceCreateNewContracts,
        verify: isVerify,
    });

    await run("deployContract", {
        contractName: "TGE",
        proxyType: "beacon",
        constructorArguments: [],
        forceCreate: isForceCreateNewContracts,
        verify: isVerify,
    });

    await run("deployContract", {
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

    const protocolTokenFee = 1000;

    await run("deployContract", {
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

    const directory: Directory = await getContractAt(
        "Directory",
        getProxyAddress("Directory")
    );
    let t = await directory.setService(getProxyAddress("Service"));
    await t.wait(1);
    console.log("Service is set in Directory");

    const metadata: Metadata = await getContractAt(
        "Metadata",
        getProxyAddress("Metadata")
    );
    const whitelistedTokens: WhitelistedTokens = await getContractAt(
        "WhitelistedTokens",
        getProxyAddress("WhitelistedTokens")
    );
    await whitelistedTokens.addTokensToWhitelist([ethers.constants.AddressZero], ["0x"], ["0x"]);
    const service: Service = await getContractAt(
        "Service",
        getProxyAddress("Service")
    );
    t = await metadata.setService(getProxyAddress("Service"));
    await t.wait(1);
    console.log("Service is set in Metadata");

    t = await service.setGnosisGovernanceBeacon(getProxyAddress("GnosisGovernance"));
    await t.wait(1);
    console.log("GnosisGovernance beacon is set in Service");

    t = await service.setGnosisSetup(getProxyAddress("GnosisSetup"));
    await t.wait(1);
    console.log("GnosisSetup is set in Service");
        
    console.log("\n==== Project Deploy Complete ====");

    // Protocol

    // const whitelistedTokens: WhitelistedTokens = await getContract("WhitelistedTokens");
    // const metadata: Metadata = await getContract("Metadata");
    // const service: Service = await getContract("Service");
    await service.addUserToWhitelist(owner.address);
    await service.setFee(parseUnits("0.01"));

    const tokenData: TokenInfoStruct = {
        name: "DAO Token",
        symbol: "DTKN",
        cap: ethers.utils.parseUnits("1"),
    };
    const tgeData: TGEInfoStruct = {
        metadataURI: "uri",
        price: parseUnits("0.01"),
        hardcap: 5000,
        softcap: 1000,
        minPurchase: 10,
        maxPurchase: 3000,
        lockupPercent: 50,
        lockupDuration: 50,
        lockupTVL: parseUnits("20"),
        duration: 20,
        userWhitelist: [], // [owner.address, other.address],
        unitOfAccount: AddressZero
    };

    await metadata.createRecord(1, "SerialNumber1002", "22-09-2022", 1);

    const tx = await service.createPool(AddressZero, tokenData, tgeData, 50, 50, 25, 1, "Name", {
        value: parseUnits("0.01"),
    });
    const receipt = await tx.wait();

    const event = receipt.events!.filter((e: any) => e.event == "PoolCreated")[0];
    const pool: Pool = await getContractAt("Pool", event.args![0]);
    const token: GovernanceToken = await getContractAt(
        "GovernanceToken",
        event.args![1]
    );
    const tge: TGE = await getContractAt("TGE", event.args![2]);

    const gateway: ProposalGateway = await getContractAt("ProposalGateway", await service.proposalGateway());

    // const service: Service = await getContractAt("Service", "0x1B8a1aCD2fe1a63565CA8C787F5627E4a52A1a11");
    // const metadata: Metadata = await getContractAt("Metadata", "0x0c3ac867De28d0b20040cAbA44cB3a17608DeeA1");
    // const gateway: ProposalGateway = await getContractAt("ProposalGateway", "0xB8f4a4AD9a1d23861C650e1dd1F0A96BB7DC6e0d");
    // const whitelistedTokens: WhitelistedTokens = await getContractAt("WhitelistedTokens", "0x5E64814FE239823AF0699A8391BE4aeF2F64B3D7");
    // const pool: Pool = await getContractAt("Pool", "0x9dd85D2f7b13fD8E402e800CbF09194f57960297");
    // const tge: TGE = await getContractAt("TGE", "0xf88a7618CC009d11FF149a6F47667229EdA1d389");
    // const token: GovernanceToken = await getContractAt("GovernanceToken", "0x519be21DC6E68fD68d661cC9796FDdE32977061C");
    // const direcory = await getContractAt("Directory", "0xcD0EDc1C90319bEf259ce714d5C2E37019311543");
    // const token1: ERC20Mock = await getContractAt("ONE", "0x060a005301b973A890E402eE475b60eFa293F3B6");
    // const token2: ERC20Mock = await getContractAt("TWO", "0xd53B5A10ef3d6a4fFAd8Ddc6Bc07C67EEC285B68");
    // const token3: ERC20Mock = await getContractAt("THREE", "0x3CC48a04500d635D0040737578efef45905B0641");

    // const tokenData: TokenInfoStruct = {
    //     name: "DAO Token",
    //     symbol: "DTKN",
    //     cap: 10000,
    // };
    // const tgeData: TGEInfoStruct = {
    //     metadataURI: "uri",
    //     price: parseUnits("0.01"),
    //     hardcap: 5000,
    //     softcap: 1000,
    //     minPurchase: 10,
    //     maxPurchase: 3000,
    //     lockupPercent: 50,
    //     lockupDuration: 50,
    //     lockupTVL: parseUnits("20"),
    //     duration: 20,
    //     userWhitelist: [owner.address, other.address],
    //     unitOfAccount: AddressZero
    // };

    return {
        service,
        metadata,
        tokenData,
        tgeData,
        pool,
        token,
        tge,
        gateway,
        directory, 
        token1,
        token2,
        token3,
    };
}
