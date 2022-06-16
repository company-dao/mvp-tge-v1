import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ContractTransaction } from "ethers";
import { deployments, ethers, network } from "hardhat";
import {
    Directory,
    GovernanceToken,
    Pool,
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

describe("Test secondary TGE", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        third: SignerWithAddress;
    let service: Service,
        pool: Pool,
        tge: TGE,
        token: GovernanceToken,
        directory: Directory;
    let snapshotId: any;
    let tgeData: TGEInfoStruct;
    let tx: ContractTransaction;

    before(async function () {
        [owner, other, third] = await getSigners();

        await deployments.fixture();

        // Setup
        ({ service, tgeData, pool, tge, token } = await setup());
        directory = await getContract<Directory>("Directory");

        // Successfully finish TGE
        await tge.connect(other).purchase(1000, { value: parseUnits("10") });
        await mineBlock(20);

        tgeData.duration = 30;
        tgeData.softcap = 500;
        tgeData.hardcap = 2000;

        tx = await pool
            .connect(other)
            .createTGEProposal(25, 500, tgeData, "Let's do TGE once again");
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

    it("Only shareholder can create secondary TGE proposals", async function () {
        await expect(
            pool
                .connect(third)
                .createTGEProposal(25, 500, tgeData, "Let's do TGE once again")
        ).to.be.revertedWith("Not shareholder");
    });

    it("Proposing secondary TGE works", async function () {
        await expect(tx).to.emit(pool, "ProposalCreated");

        const receipt = await tx.wait();

        const proposal = await pool.proposals(1);
        expect(proposal.quorum).to.equal(500);
        expect(proposal.startBlock).to.equal(receipt.blockNumber);
        expect(proposal.endBlock).to.equal(receipt.blockNumber + 25);
        expect(proposal.forVotes).to.equal(0);
        expect(proposal.executed).to.be.false;
    });

    it("Can't propose secondary TGE when there is active proposal", async function () {
        await expect(
            pool
                .connect(other)
                .createTGEProposal(25, 500, tgeData, "And one more")
        ).to.be.revertedWith("Already has active proposal");
    });

    it("Only shareholders can vote on proposal", async function () {
        await expect(pool.connect(third).castVote(1)).to.be.revertedWith(
            "No votes"
        );
    });

    it("Casting votes from valid voter works", async function () {
        await expect(pool.connect(other).castVote(1))
            .to.emit(pool, "VoteCast")
            .withArgs(other.address, 1, 1000);

        const proposal = await pool.proposals(1);
        expect(proposal.forVotes).to.equal(1000);
    });

    it("Can't vote twice (if tokens are blocked)", async function () {
        await pool.connect(other).castVote(1);

        await expect(pool.connect(other).castVote(1)).to.be.revertedWith(
            "No votes"
        );
    });

    it("Can't vote twice (if ballot present)", async function () {
        await token.connect(other).transfer(third.address, 100);
        await pool.connect(other).castVote(1);
        await token.connect(third).transfer(other.address, 100);

        await expect(pool.connect(other).castVote(1)).to.be.revertedWith(
            "Already voted"
        );
    });

    it("Only pool can lock tokens for voting", async function () {
        await expect(
            token.connect(third).lock(other.address, 100, 0)
        ).to.be.revertedWith("Not pool");
    });

    it("Voting tokens are locked and can be transferred", async function () {
        await pool.connect(other).castVote(1);

        expect(await token.lockedBalanceOf(other.address)).to.equal(1000);
        expect(await token.unlockedBalanceOf(other.address)).to.equal(0);

        await expect(
            token.connect(other).transfer(third.address, 100)
        ).to.be.revertedWith("Not enough unlocked balance");
    });

    it("After voting in finished tokens are unlocked", async function () {
        await pool.connect(other).castVote(1);
        await mineBlock(25);

        expect(await token.lockedBalanceOf(other.address)).to.equal(0);
        expect(await token.unlockedBalanceOf(other.address)).to.equal(1000);

        await token.connect(other).transfer(third.address, 100);
        expect(await token.balanceOf(third.address)).to.equal(100);
    });

    it("Can't vote after voting period is finished", async function () {
        await mineBlock(25);

        await expect(pool.connect(other).castVote(1)).to.be.revertedWith(
            "Voting finished"
        );
    });

    it("Can't execute non-existent proposal", async function () {
        await expect(pool.execute(2)).to.be.revertedWith(
            "Proposal does not exist"
        );
    });

    it("Can't execute proposal before voting period is finished", async function () {
        await pool.connect(other).castVote(1);

        await expect(pool.execute(1)).to.be.revertedWith("Voting not finished");
    });

    it("Can't execute proposal if quorum is not reached", async function () {
        await mineBlock(25);

        await expect(pool.execute(1)).to.be.revertedWith("Quorum not reached");
    });

    it("Can execute successful proposal, creating secondary TGE", async function () {
        await pool.connect(other).castVote(1);
        await mineBlock(25);

        await expect(pool.execute(1)).to.emit(service, "SecondaryTGECreated");

        const tgeRecord = await directory.contractRecordAt(
            await directory.lastContractRecordIndex()
        );
        const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

        expect(await tge2.duration()).to.equal(30);
        expect(await tge2.softcap()).to.equal(500);
        expect(await tge2.hardcap()).to.equal(2000);
    });

    it("Only pool can request creating TGEs and recording proposals on service", async function () {
        await expect(service.createSecondaryTGE(tgeData)).to.be.revertedWith(
            "Not a pool"
        );

        await expect(service.addProposal(35)).to.be.revertedWith("Not a pool");
    });

    it("While secondary TGE is active, new proposals can't be created", async function () {
        await pool.connect(other).castVote(1);
        await mineBlock(25);
        await pool.execute(1);

        await expect(
            pool
                .connect(other)
                .createTGEProposal(25, 500, tgeData, "And one more")
        ).to.be.revertedWith("Has active TGE");
    });

    it("If secondary TGE is failed, user can't burn there more tokens than he has purchased", async function () {
        await pool.connect(other).castVote(1);
        await mineBlock(25);
        await pool.execute(1);
        const tgeRecord = await directory.contractRecordAt(
            await directory.lastContractRecordIndex()
        );
        const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

        const PurchaserFactory = await getContractFactory("Purchaser");
        const purchaser = await PurchaserFactory.deploy(tge2.address);
        await purchaser.purchase(100, { value: parseUnits("1") });

        await mineBlock(30);

        expect(await tge2.state()).to.equal(1);

        await token.connect(other).transfer(purchaser.address, 400);

        // Despite purchaser has 500 tokens now, only 100 would be burnt as it is his purchase
        const balanceBefore = await provider.getBalance(purchaser.address);
        await purchaser.claimBack();
        const balanceAfter = await provider.getBalance(purchaser.address);
        expect(balanceAfter.sub(balanceBefore)).to.equal(parseUnits("1"));
        expect(await token.balanceOf(purchaser.address)).to.equal(400);

        // Subsequnt reclaims would do nothing
        await purchaser.claimBack();
        expect(await token.balanceOf(purchaser.address)).to.equal(400);
    });

    it("If secondary TGE is failed, user can't burn tokens that are locked in subsequent proposal voting", async function () {
        await pool.connect(other).castVote(1);
        await mineBlock(25);
        await pool.execute(1);
        const tgeRecord = await directory.contractRecordAt(
            await directory.lastContractRecordIndex()
        );
        const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

        await tge2.connect(third).purchase(100, { value: parseUnits("1") });
        await mineBlock(30);

        await pool
            .connect(other)
            .createTGEProposal(
                25,
                500,
                tgeData,
                "That didn't work out, let's try again!"
            );
        await pool.connect(third).castVote(2);

        // Nothing should be burnt as tokens are locked in voting
        await tge2.connect(third).claimBack();
        expect(await token.balanceOf(third.address)).to.equal(100);
    });

    it("New TGE can't be created before previous TGE is finished", async function () {
        // This is unprobable in reality as successful proposal would likely be executed ASAP
        // However theoretically there can be two unexecuted proposals that are attemplted to be executed subsequently

        // Succeed first proposal, but not execute
        await pool.connect(other).castVote(1);
        await mineBlock(25);

        // Create, succeed and execute second proposal
        await pool
            .connect(other)
            .createTGEProposal(25, 500, tgeData, "Let's do TGE once again");
        await pool.connect(other).castVote(2);
        await mineBlock(25);
        await pool.execute(2);

        // Execution of first proposal should fail
        await expect(pool.execute(1)).to.be.revertedWith("Has active TGE");
    });

    it("Secondary TGE's hardcap can't overflow remaining (unminted) supply", async function () {
        await mineBlock(25);

        tgeData.hardcap = 9500;
        await pool
            .connect(other)
            .createTGEProposal(5, 500, tgeData, "Let's do TGE once again");
        await pool.connect(other).castVote(2);
        await mineBlock(5);

        await expect(pool.execute(2)).to.be.revertedWith(
            "Hardcap higher than remaining supply"
        );
    });
});
