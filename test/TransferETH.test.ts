import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ContractTransaction, Transaction } from "ethers";
import { deployments, ethers, network } from "hardhat";
import {
    Directory,
    GovernanceToken,
    Pool,
    ProposalGateway,
    Service,
    TGE,
} from "../typechain-types";
import { TokenInfoStruct } from "../typechain-types/GovernanceToken";
import { TGEInfoStruct } from "../typechain-types/ITGE";
import { setup } from "./shared/setup";
import { mineBlock } from "./shared/utils";

const { getContractAt, getContract, getContractFactory, getSigners, provider } =
    ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

describe("Test transfer ETH", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        third: SignerWithAddress;
    let service: Service,
        pool: Pool,
        tge: TGE,
        token: GovernanceToken,
        gateway: ProposalGateway;
    let snapshotId: any;
    let tokenData: TokenInfoStruct, tgeData: TGEInfoStruct;
    let tx: ContractTransaction;

    before(async function () {
        [owner, other, third] = await getSigners();

        await deployments.fixture();

        // Setup
        ({ service, tokenData, tgeData, pool, tge, token, gateway } =
            await setup());

        // Successfully finish TGE
        await tge.connect(other).purchase(1000, { value: parseUnits("10") });
        await mineBlock(20);

        tgeData.duration = 30;
        tgeData.softcap = 500;
        tgeData.hardcap = 2000;

        tx = await gateway
            .connect(other)
            .createTransferETHProposal(
                pool.address,
                25,
                third.address,
                parseUnits("1"),
                "Let's give this guy some money"
            );
    });

    beforeEach(async function () {
        snapshotId = await network.provider.request({
            method: "evm_snapshot",
            params: [],
        });
    });

    afterEach(async function () {
        snapshotId = await network.provider.request({
            method: "evm_revert",
            params: [snapshotId],
        });
    });

    it("Only shareholder can create transfer proposals", async function () {
        await expect(
            gateway
                .connect(third)
                .createTransferETHProposal(
                    pool.address,
                    25,
                    third.address,
                    parseUnits("1"),
                    "Let's give this guy some money"
                )
        ).to.be.revertedWith("Not shareholder");
    });

    it("Can't execute transfer proposal if pool doesn't hold enough funds", async function () {
        await pool.connect(other).castVote(1, true);
        await mineBlock(25);

        await expect(pool.execute(1)).to.be.revertedWith(
            "Call reverted without message"
        );
    });

    it("Executing succeeded transfer proposals should work", async function () {
        await pool.connect(other).castVote(1, true);
        await mineBlock(25);
        await owner.sendTransaction({
            to: pool.address,
            value: parseUnits("10"),
        });

        const thirdBefore = await provider.getBalance(third.address);
        await pool.execute(1);
        const thirdAfter = await provider.getBalance(third.address);
        expect(await provider.getBalance(pool.address)).to.equal(
            parseUnits("9")
        );
        expect(thirdAfter.sub(thirdBefore)).to.equal(parseUnits("1"));
    });
});
