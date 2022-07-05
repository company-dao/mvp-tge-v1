import { ethers, run } from "hardhat";
import {
    ERC20Mock,
    Pool,
    ProposalGateway,
    Service,
    TGE,
} from "../../typechain-types";
import {
    GovernanceToken,
    TokenInfoStruct,
} from "../../typechain-types/GovernanceToken";
import { TGEInfoStruct } from "../../typechain-types/IService";

const { getContract, getContractAt, getSigners } = ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

export async function setup() {
    const [owner, other] = await getSigners();

    // Mocks and uniswap

    const token1 = await getContract<ERC20Mock>("ONE");
    const token2 = await getContract<ERC20Mock>("TWO");
    const token3 = await getContract<ERC20Mock>("THREE");

    // Add liquitiy to uniswap

    await run("addUniswapLiquidity");

    // Protocol

    const service: Service = await getContract("Service");
    await service.addUserToWhitelist(owner.address);
    await service.setFee(parseUnits("0.01"));

    const tokenData: TokenInfoStruct = {
        name: "DAO Token",
        symbol: "DTKN",
        cap: 10000,
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
        userWhitelist: [owner.address, other.address],
        tokenWhitelist: [],
    };
    const tx = await service.createPool(AddressZero, tokenData, tgeData, {
        value: parseUnits("0.01"),
    });
    const receipt = await tx.wait();

    const event = receipt.events!.filter((e) => e.event == "PoolCreated")[0];
    const pool: Pool = await getContractAt("Pool", event.args![0]);
    const token: GovernanceToken = await getContractAt(
        "GovernanceToken",
        event.args![1]
    );
    const tge: TGE = await getContractAt("TGE", event.args![2]);

    const gateway = await getContract<ProposalGateway>("ProposalGateway");

    return {
        service,
        tokenData,
        tgeData,
        pool,
        token,
        tge,
        gateway,
        token1,
        token2,
        token3,
    };
}
