import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ContractTransaction } from "ethers";
import { deployments, ethers, network } from "hardhat";
import { ERC20Mock, Pool, ProposalGateway, TGE } from "../typechain-types";
import { TGEInfoStruct } from "../typechain-types/ITGE";
import { setup } from "./shared/setup";
import { mineBlock } from "./shared/utils";

const { getSigners, provider } = ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

describe("Test transfer proposals", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        third: SignerWithAddress;
    let pool: Pool, tge: TGE, gateway: ProposalGateway, token1: ERC20Mock;
    let snapshotId: any;
    let tgeData: TGEInfoStruct;
    let tx: ContractTransaction;

    before(async function () {
        [owner, other, third] = await getSigners();

        await deployments.fixture();

        // Setup
        ({ tgeData, pool, tge, gateway, token1 } = await setup());

        // Successfully finish TGE
        await tge
            .connect(other)
            .purchase(AddressZero, 1000, { value: parseUnits("10") });
        await mineBlock(20);

        tgeData.duration = 30;
        tgeData.softcap = 500;
        tgeData.hardcap = 2000;
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

    describe("Transfer ETH", function () {
        this.beforeEach(async function () {
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

    describe("Transfer ERC20", function () {
        this.beforeEach(async function () {
            tx = await gateway
                .connect(other)
                .createTransferERC20Proposal(
                    pool.address,
                    25,
                    token1.address,
                    third.address,
                    parseUnits("10"),
                    "Let's give this guy some ONE"
                );
        });

        it("Can't execute transfer proposal if pool doesn't hold enough funds", async function () {
            await pool.connect(other).castVote(1, true);
            await mineBlock(25);

            await expect(pool.execute(1)).to.be.revertedWith(
                "ERC20: transfer amount exceeds balance"
            );
        });

        it("Executing succeeded transfer proposals should work", async function () {
            await pool.connect(other).castVote(1, true);
            await mineBlock(25);
            await token1.mint(pool.address, parseUnits("100"));

            await pool.execute(1);
            expect(await token1.balanceOf(pool.address)).to.equal(
                parseUnits("90")
            );
            expect(await token1.balanceOf(third.address)).to.equal(
                parseUnits("10")
            );
        });
    });
});
