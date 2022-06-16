import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { deployments, ethers, network } from "hardhat";
import { GovernanceToken, Pool, Service, TGE } from "../typechain-types";
import { TokenInfoStruct } from "../typechain-types/GovernanceToken";
import { TGEInfoStruct } from "../typechain-types/ITGE";
import { setup } from "./shared/setup";
import { mineBlock } from "./shared/utils";

const { getContractAt, getContractFactory, getSigners, Wallet, provider } =
    ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

describe("Test initial TGE", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        third: SignerWithAddress;
    let service: Service, pool: Pool, tge: TGE, token: GovernanceToken;
    let snapshotId: any;
    let tokenData: TokenInfoStruct, tgeData: TGEInfoStruct;

    before(async function () {
        [owner, other, third] = await getSigners();

        await deployments.fixture();

        // Setup
        ({ service, tokenData, tgeData, pool, tge, token } = await setup());
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

    describe("Creating initial TGE first time", function () {
        it("Only whitelisted can create pool", async function () {
            await expect(
                service
                    .connect(other)
                    .createPool(AddressZero, tokenData, tgeData, {
                        value: parseUnits("0.01"),
                    })
            ).to.be.revertedWith("Not whitelisted");
        });

        it("Only service can set TGE and token for pool", async function () {
            await expect(
                pool.connect(other).setTGE(other.address)
            ).to.be.revertedWith("Not service");

            await expect(
                pool.connect(other).setToken(other.address)
            ).to.be.revertedWith("Not service");
        });

        it("Can't create pool with incorrect fee", async function () {
            await expect(
                service.createPool(AddressZero, tokenData, tgeData, {
                    value: parseUnits("0.005"),
                })
            ).to.be.revertedWith("Incorrect fee passed");
        });

        it("Can't create pool with hardcap higher than token cap", async function () {
            tgeData.hardcap = 20000;
            await expect(
                service.createPool(AddressZero, tokenData, tgeData, {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith("Hardcap higher than remaining supply");
        });

        it("Can't purchase less than min purchase", async function () {
            await expect(
                tge.connect(other).purchase(5, { value: parseUnits("0.05") })
            ).to.be.revertedWith("Amount less than min purchase");
        });

        it("Can't purchase with wrong ETH value passed", async function () {
            await expect(
                tge.connect(other).purchase(50, { value: parseUnits("0.1") })
            ).to.be.revertedWith("Invalid ETH value passed");
        });

        it("Can't purchase over max purchase in one tx", async function () {
            await expect(
                tge.connect(other).purchase(4000, { value: parseUnits("40") })
            ).to.be.revertedWith("Overflows max purchase");
        });

        it("Can't purchase over max purchase in several tx", async function () {
            await tge
                .connect(other)
                .purchase(2000, { value: parseUnits("20") });

            await expect(
                tge.connect(other).purchase(2000, { value: parseUnits("20") })
            ).to.be.revertedWith("Overflows max purchase");
        });

        it("Can't purchase over hardcap", async function () {
            await tge
                .connect(other)
                .purchase(3000, { value: parseUnits("30") });

            await expect(
                tge.connect(third).purchase(3000, { value: parseUnits("30") })
            ).to.be.revertedWith("Overflows hardcap");
        });

        it("Mint can't be called on token directly, should be done though TGE", async function () {
            await expect(
                token.connect(other).mint(other.address, 100, 0, 0)
            ).to.be.revertedWith("Not a TGE");
        });

        it("Purchasing works", async function () {
            await tge
                .connect(other)
                .purchase(1000, { value: parseUnits("10") });

            expect(await token.balanceOf(other.address)).to.equal(1000);
            expect(await provider.getBalance(tge.address)).to.equal(
                parseUnits("10")
            );
            expect(await token.lockedBalanceOf(other.address)).to.equal(500);
        });

        it("Locking is rounded up", async function () {
            await tge
                .connect(other)
                .purchase(1001, { value: parseUnits("10.01") });
            expect(await token.lockedBalanceOf(other.address)).to.equal(501);
        });

        it("Can't transfer lockup tokens", async function () {
            await tge
                .connect(other)
                .purchase(1000, { value: parseUnits("10") });

            await expect(
                token.connect(other).transfer(owner.address, 1000)
            ).to.be.revertedWith("Not enough unlocked balance");
        });

        it("Can't purchase after event is finished", async function () {
            await mineBlock(20);

            await expect(
                tge.connect(third).purchase(1000, { value: parseUnits("10") })
            ).to.be.revertedWith("TGE in wrong state");
        });

        it("Can't claim back if event is not failed", async function () {
            await tge.connect(other).purchase(500, { value: parseUnits("5") });

            await expect(tge.connect(third).claimBack()).to.be.revertedWith(
                "TGE in wrong state"
            );

            await tge.connect(other).purchase(500, { value: parseUnits("5") });
            await mineBlock(20);

            await expect(tge.connect(third).claimBack()).to.be.revertedWith(
                "TGE in wrong state"
            );
        });

        it("Claiming back works if TGE is failed", async function () {
            const PurchaserFactory = await getContractFactory("Purchaser");
            const purchaser = await PurchaserFactory.deploy(tge.address);

            await purchaser.purchase(400, { value: parseUnits("4") });
            await tge.connect(third).purchase(400, { value: parseUnits("4") });

            await mineBlock(20);

            await purchaser.claimBack();

            expect(await provider.getBalance(purchaser.address)).to.equal(
                parseUnits("4")
            );
        });

        it("Burn can't be called on token directly, should be done though TGE", async function () {
            await tge.connect(other).purchase(400, { value: parseUnits("4") });
            await mineBlock(20);
            await expect(
                token.connect(other).burn(other.address, 100)
            ).to.be.revertedWith("Not a TGE");
        });

        it("Can't transfer funds if event is not successful", async function () {
            await tge.connect(other).purchase(500, { value: parseUnits("5") });

            await expect(tge.transferFunds(owner.address)).to.be.revertedWith(
                "TGE in wrong state"
            );

            await mineBlock(20);

            await expect(tge.transferFunds(owner.address)).to.be.revertedWith(
                "TGE in wrong state"
            );
        });

        it("Only TGE owner can transfer funds", async function () {
            await tge
                .connect(other)
                .purchase(1000, { value: parseUnits("10") });
            await mineBlock(20);

            await expect(
                tge.connect(other).transferFunds(other.address)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Transferring funds for successful TGE by owner should work", async function () {
            await tge
                .connect(other)
                .purchase(1000, { value: parseUnits("10") });
            await mineBlock(20);

            const treasury = Wallet.createRandom();
            await tge.transferFunds(treasury.address);
            expect(await provider.getBalance(treasury.address)).to.equal(
                parseUnits("10")
            );
        });

        it("In successful TGE purchased funds are unlocked", async function () {
            await tge
                .connect(other)
                .purchase(1000, { value: parseUnits("10") });
            await mineBlock(20);

            expect(await token.lockedBalanceOf(other.address)).to.equal(0);
            await token.connect(other).transfer(third.address, 1000);
            expect(await token.balanceOf(third.address)).to.equal(1000);
        });

        it("Token has zero decimals", async function () {
            expect(await token.decimals()).to.equal(0);
        });

        it("Only service owner can whitelist", async function () {
            await expect(
                service.connect(other).addToWhitelist(other.address)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Adding to whitelist works", async function () {
            await service.addToWhitelist(other.address);

            const whitelist = await service.whitelist();
            expect(whitelist.length).to.equal(2);
            expect(whitelist[0]).to.equal(owner.address);
            expect(whitelist[1]).to.equal(other.address);

            expect(await service.whitelistLength()).to.equal(2);
            expect(await service.whitelistAt(0)).to.equal(owner.address);
            expect(await service.whitelistAt(1)).to.equal(other.address);
        });

        it("Can't add to whitelist twice", async function () {
            await expect(
                service.addToWhitelist(owner.address)
            ).to.be.revertedWith("Already whitelisted");
        });

        it("Only owner can remove from whitelist", async function () {
            await expect(
                service.connect(other).removeFromWhitelist(owner.address)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Can remove non-present from whitelist", async function () {
            await expect(
                service.removeFromWhitelist(other.address)
            ).to.be.revertedWith("Already not whitelisted");
        });

        it("Removing from whitelist works", async function () {
            await service.removeFromWhitelist(owner.address);

            expect(await service.whitelistLength()).to.equal(0);
        });

        it("Only owner can transfer funds", async function () {
            await expect(
                service.connect(other).transferFunds(other.address)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Transferring funds work", async function () {
            const treasury = Wallet.createRandom();
            await service.transferFunds(treasury.address);
            expect(await provider.getBalance(treasury.address)).to.equal(
                parseUnits("0.01")
            );
        });
    });

    describe("Recreating failed TGE", async function () {
        it("Can't recreate TGE for non-pool", async function () {
            await expect(
                service.createPool(token.address, tokenData, tgeData, {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith("Not a pool");
        });

        it("Only pool owner can recreate TGE", async function () {
            await service.addToWhitelist(other.address);
            await expect(
                service
                    .connect(other)
                    .createPool(pool.address, tokenData, tgeData, {
                        value: parseUnits("0.01"),
                    })
            ).to.be.revertedWith("Sender is not pool owner");
        });

        it("Can't recreate active TGE", async function () {
            await expect(
                service.createPool(pool.address, tokenData, tgeData, {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith("Previous TGE not failed");
        });

        it("Can't recreate successful TGE", async function () {
            await tge
                .connect(other)
                .purchase(1000, { value: parseUnits("10") });
            await mineBlock(20);

            await expect(
                service.createPool(pool.address, tokenData, tgeData, {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith("Previous TGE not failed");
        });

        it("Failed TGE can be recreated", async function () {
            await tge.connect(other).purchase(500, { value: parseUnits("5") });
            await mineBlock(20);

            // TGE is failed

            tokenData = {
                name: "DAO Token V2",
                symbol: "DTKN2",
                cap: 20000,
            };

            const tx = await service.createPool(
                pool.address,
                tokenData,
                tgeData,
                {
                    value: parseUnits("0.01"),
                }
            );
            const receipt = await tx.wait();
            const event = receipt.events!.filter(
                (e) => e.event == "PoolCreated"
            )[0];

            const pool2 = await getContractAt("Pool", event.args![0]);
            const token2 = await getContractAt(
                "GovernanceToken",
                event.args![1]
            );
            const tge2 = await getContractAt("TGE", event.args![2]);

            // Pool should remain the same, token and TGE should be new

            expect(pool2.address).to.equal(pool.address);
            expect(token2.address).not.to.equal(token.address);
            expect(tge2.address).not.to.equal(tge.address);

            expect(await token2.name()).to.equal("DAO Token V2");
            expect(await token2.symbol()).to.equal("DTKN2");
            expect(await token2.cap()).to.equal(20000);
        });
    });
});
