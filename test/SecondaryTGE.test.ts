import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ContractTransaction } from "ethers";
import { deployments, ethers, network } from "hardhat";
import {
    Directory,
    GovernanceToken,
    Pool,
    ProposalGateway,
    Service,
    TGE,
} from "../typechain-types";
import { TGEInfoStruct } from "../typechain-types/ITGE";
import { setup } from "./shared/setup";
import { mineBlock } from "./shared/utils";

const { getContractAt, getContract, getSigners, provider } = ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

describe("Test secondary TGE", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        third: SignerWithAddress;
    let service: Service,
        pool: Pool,
        tge: TGE,
        token: GovernanceToken,
        directory: Directory,
        gateway: ProposalGateway;
    let snapshotId: any;
    let tgeData: TGEInfoStruct;
    let tx: ContractTransaction;

    before(async function () {
        [owner, other, third] = await getSigners();

        await deployments.fixture();

        // Setup
        ({ service, tgeData, pool, tge, token, gateway } = await setup());
        directory = await getContract<Directory>("Directory");

        // Successfully finish TGE
        await tge
            .connect(other)
            .purchase(AddressZero, 1000, { value: parseUnits("10") });
        await mineBlock(20);

        tgeData.duration = 30;
        tgeData.softcap = 500;
        tgeData.hardcap = 2000;

        tx = await gateway
            .connect(other)
            .createTGEProposal(
                pool.address,
                25,
                tgeData,
                "Let's do TGE once again"
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

    it("Only shareholder can create secondary TGE proposals", async function () {
        await expect(
            gateway
                .connect(third)
                .createTGEProposal(
                    pool.address,
                    25,
                    tgeData,
                    "Let's do TGE once again"
                )
        ).to.be.revertedWith("Not shareholder");
    });

    it("Proposing secondary TGE works", async function () {
        await expect(tx).to.emit(pool, "ProposalCreated");

        const receipt = await tx.wait();

        const proposal = await pool.proposals(1);
        expect(proposal.quorum).to.equal(30);
        expect(proposal.threshold).to.equal(50);
        expect(proposal.startBlock).to.equal(receipt.blockNumber);
        expect(proposal.endBlock).to.equal(receipt.blockNumber + 25);
        expect(proposal.forVotes).to.equal(0);
        expect(proposal.executed).to.be.false;
    });

    it("Can't propose secondary TGE when there is active proposal", async function () {
        await expect(
            gateway
                .connect(other)
                .createTGEProposal(pool.address, 25, tgeData, "And one more")
        ).to.be.revertedWith("Already has active proposal");
    });

    it("Only shareholders can vote on proposal", async function () {
        await expect(pool.connect(third).castVote(1, true)).to.be.revertedWith(
            "No votes"
        );
    });

    it("Casting votes from valid voter works", async function () {
        await expect(pool.connect(other).castVote(1, true))
            .to.emit(pool, "VoteCast")
            .withArgs(other.address, 1, 500, true);

        const proposal = await pool.proposals(1);
        expect(proposal.forVotes).to.equal(500);
    });

    it("Can't vote twice (if tokens are blocked)", async function () {
        await pool.connect(other).castVote(1, true);

        await expect(pool.connect(other).castVote(1, true)).to.be.revertedWith(
            "No votes"
        );
    });

    it("Only pool can lock tokens for voting", async function () {
        await expect(
            token.connect(third).lock(other.address, 100, 0)
        ).to.be.revertedWith("Not pool");
    });

    it("Voting tokens are locked and can be transferred", async function () {
        await pool.connect(other).castVote(1, true);

        expect(await token.lockedBalanceOf(other.address)).to.equal(500);
        expect(await token.unlockedBalanceOf(other.address)).to.equal(0);

        await expect(
            token.connect(other).transfer(third.address, 100)
        ).to.be.revertedWith("Not enough unlocked balance");
    });

    it("After voting in finished tokens are unlocked", async function () {
        await pool.connect(other).castVote(1, true);
        await mineBlock(25);

        expect(await token.lockedBalanceOf(other.address)).to.equal(0);
        expect(await token.unlockedBalanceOf(other.address)).to.equal(500);

        await token.connect(other).transfer(third.address, 100);
        expect(await token.balanceOf(third.address)).to.equal(100);
    });

    it("Can't vote after voting period is finished", async function () {
        await mineBlock(25);

        await expect(pool.connect(other).castVote(1, true)).to.be.revertedWith(
            "Voting finished"
        );
    });

    it("Can't execute non-existent proposal", async function () {
        await expect(pool.execute(2)).to.be.revertedWith(
            "Proposal is in wrong state"
        );
    });

    it("Can't execute proposal before voting period is finished", async function () {
        await pool.connect(other).castVote(1, true);

        await expect(pool.execute(1)).to.be.revertedWith(
            "Proposal is in wrong state"
        );
    });

    it("Can't execute proposal if quorum is not reached", async function () {
        await mineBlock(25);

        await expect(pool.execute(1)).to.be.revertedWith(
            "Proposal is in wrong state"
        );
    });

    it("Can execute successful proposal, creating secondary TGE", async function () {
        await pool.connect(other).castVote(1, true);
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

    it("If secondary TGE is failed, user can't burn there more tokens than he has purchased", async function () {
        await pool.connect(other).castVote(1, true);
        await mineBlock(25);
        await pool.execute(1);
        const tgeRecord = await directory.contractRecordAt(
            await directory.lastContractRecordIndex()
        );
        const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

        await tge2
            .connect(owner)
            .purchase(AddressZero, 100, { value: parseUnits("1") });

        await mineBlock(30);

        expect(await tge2.state()).to.equal(1);

        await token.connect(other).transfer(owner.address, 400);

        // Despite purchaser has 450 tokens now (+50 in lockup), only 100 would be burnt as it is his purchase
        await tge2.connect(owner).claimBack();
        expect(await token.balanceOf(owner.address)).to.equal(350);
        expect(await tge2.lockedBalanceOf(owner.address)).to.equal(50);

        // Subsequnt reclaims would do nothing
        await tge2.connect(owner).claimBack();
        expect(await token.balanceOf(owner.address)).to.equal(350);
        expect(await tge2.lockedBalanceOf(owner.address)).to.equal(50);
    });

    it("If secondary TGE is failed, user can't burn tokens that are locked in subsequent proposal voting", async function () {
        await pool.connect(other).castVote(1, true);
        await mineBlock(25);
        await pool.execute(1);
        const tgeRecord = await directory.contractRecordAt(
            await directory.lastContractRecordIndex()
        );
        const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

        await tge2
            .connect(owner)
            .purchase(AddressZero, 100, { value: parseUnits("1") });
        await mineBlock(30);

        await gateway
            .connect(other)
            .createTGEProposal(
                pool.address,
                25,
                tgeData,
                "That didn't work out, let's try again!"
            );
        await pool.connect(owner).castVote(2, true);

        // Nothing should be burnt as tokens are locked in voting
        await tge2.connect(owner).claimBack();
        expect(await token.balanceOf(third.address)).to.equal(0);
    });

    it("New TGE can't be created before previous TGE is finished", async function () {
        // This is unprobable in reality as successful proposal would likely be executed ASAP
        // However theoretically there can be two unexecuted proposals that are attemplted to be executed subsequently

        // Succeed first proposal, but not execute
        await pool.connect(other).castVote(1, true);
        await mineBlock(25);

        // Create, succeed and execute second proposal
        await gateway
            .connect(other)
            .createTGEProposal(
                pool.address,
                25,
                tgeData,
                "Let's do TGE once again"
            );
        await pool.connect(other).castVote(2, true);
        await mineBlock(25);
        await pool.execute(2);

        // Execution of first proposal should fail
        await expect(pool.execute(1)).to.be.revertedWith("Has active TGE");
    });

    it("Secondary TGE's hardcap can't overflow remaining (unminted) supply", async function () {
        await mineBlock(25);

        tgeData.hardcap = 9500;
        await gateway
            .connect(other)
            .createTGEProposal(
                pool.address,
                5,
                tgeData,
                "Let's do TGE once again"
            );
        await pool.connect(other).castVote(2, true);
        await mineBlock(5);

        await expect(pool.execute(2)).to.be.revertedWith(
            "Hardcap higher than remaining supply"
        );
    });
});
