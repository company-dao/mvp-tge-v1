import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { deployments, ethers, network } from "hardhat";
import {
    ERC20Mock,
    GovernanceToken,
    Pool,
    Service,
    TGE,
} from "../typechain-types";
import { TokenInfoStruct } from "../typechain-types/GovernanceToken";
import { TGEInfoStruct } from "../typechain-types/ITGE";
import { setup } from "./shared/setup";
import { mineBlock } from "./shared/utils";

const { getContractAt, getSigners, Wallet, provider } = ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

describe("Test initial TGE", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        third: SignerWithAddress;
    let service: Service, pool: Pool, tge: TGE, token: GovernanceToken;
    let token1: ERC20Mock, token2: ERC20Mock, token3: ERC20Mock;
    let snapshotId: any;
    let tokenData: TokenInfoStruct, tgeData: TGEInfoStruct;

    before(async function () {
        [owner, other, third] = await getSigners();

        await deployments.fixture();

        // Setup
        ({
            service,
            tokenData,
            tgeData,
            pool,
            tge,
            token,
            token1,
            token2,
            token3,
        } = await setup());
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
                tge
                    .connect(other)
                    .purchase(AddressZero, 5, { value: parseUnits("0.05") })
            ).to.be.revertedWith("Amount less than min purchase");
        });

        it("Can't purchase with wrong ETH value passed", async function () {
            await expect(
                tge
                    .connect(other)
                    .purchase(AddressZero, 50, { value: parseUnits("0.1") })
            ).to.be.revertedWith("Invalid ETH value passed");
        });

        it("Can't purchase over max purchase in one tx", async function () {
            await expect(
                tge
                    .connect(other)
                    .purchase(AddressZero, 4000, { value: parseUnits("40") })
            ).to.be.revertedWith("Overflows max purchase");
        });

        it("Can't purchase over max purchase in several tx", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 2000, { value: parseUnits("20") });

            await expect(
                tge
                    .connect(other)
                    .purchase(AddressZero, 2000, { value: parseUnits("20") })
            ).to.be.revertedWith("Overflows max purchase");
        });

        it("Can't purchase over hardcap", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 3000, { value: parseUnits("30") });

            await expect(
                tge.purchase(AddressZero, 3000, { value: parseUnits("30") })
            ).to.be.revertedWith("Overflows hardcap");
        });

        it("Mint can't be called on token directly, should be done though TGE", async function () {
            await expect(
                token.connect(other).mint(other.address, 100)
            ).to.be.revertedWith("Not a TGE");
        });

        it("Purchasing works", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 1000, { value: parseUnits("10") });

            expect(await token.balanceOf(other.address)).to.equal(500);
            expect(await provider.getBalance(tge.address)).to.equal(
                parseUnits("10")
            );
            expect(await tge.lockedBalanceOf(other.address)).to.equal(500);
        });

        it("Purchasing with whitelisted token works", async function () {
            await token1.mint(other.address, parseUnits("203")); // Because of slippage we need a bit more than 200
            await token1.connect(other).approve(tge.address, parseUnits("203"));

            await tge.connect(other).purchase(token1.address, 100);
            expect(await token1.balanceOf(other.address)).to.be.lt(
                parseUnits("1")
            );

            expect(await token.balanceOf(other.address)).to.equal(50);
            expect(await tge.lockedBalanceOf(other.address)).to.equal(50);
        });

        it("Purchasing with whitelisted token that has non-direct swap works", async function () {
            await token2.mint(other.address, parseUnits("102")); // Because of slippage we need a bit more than 100
            await token2.connect(other).approve(tge.address, parseUnits("102"));

            await tge.connect(other).purchase(token2.address, 100);
            expect(await token2.balanceOf(other.address)).to.be.lt(
                parseUnits("1")
            );

            expect(await token.balanceOf(other.address)).to.equal(50);
            expect(await tge.lockedBalanceOf(other.address)).to.equal(50);
        });

        it("Can't purchase with non-whitelisted token", async function () {
            await token3.mint(other.address, parseUnits("1000")); // More than enough (if it was whitelisted)
            await token3
                .connect(other)
                .approve(tge.address, parseUnits("1000"));

            await expect(
                tge.connect(other).purchase(token3.address, 100)
            ).to.be.revertedWith("Token not whitelisted");
        });

        it("Locking is rounded up", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 1001, { value: parseUnits("10.01") });
            expect(await tge.lockedBalanceOf(other.address)).to.equal(501);
        });

        it("Can't transfer lockup tokens", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 1000, { value: parseUnits("10") });

            await expect(
                token.connect(other).transfer(owner.address, 1000)
            ).to.be.revertedWith("Not enough unlocked balance");
        });

        it("Can't purchase after event is finished", async function () {
            await mineBlock(20);

            await expect(
                tge
                    .connect(other)
                    .purchase(AddressZero, 1000, { value: parseUnits("10") })
            ).to.be.revertedWith("TGE in wrong state");
        });

        it("Can't claim back if event is not failed", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 500, { value: parseUnits("5") });

            await expect(tge.connect(third).claimBack()).to.be.revertedWith(
                "TGE in wrong state"
            );

            await tge
                .connect(other)
                .purchase(AddressZero, 500, { value: parseUnits("5") });
            await mineBlock(20);

            await expect(tge.connect(third).claimBack()).to.be.revertedWith(
                "TGE in wrong state"
            );
        });

        it("Claiming back works if TGE is failed", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 400, { value: parseUnits("4") });

            await mineBlock(20);

            await tge.connect(other).claimBack();
            expect(await token.balanceOf(other.address)).to.equal(0);
        });

        it("Burn can't be called on token directly, should be done though TGE", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 400, { value: parseUnits("4") });
            await mineBlock(20);
            await expect(
                token.connect(other).burn(other.address, 100)
            ).to.be.revertedWith("Not a TGE");
        });

        it("Can't transfer funds if event is not successful", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 500, { value: parseUnits("5") });

            await expect(tge.transferFunds(AddressZero)).to.be.revertedWith(
                "TGE in wrong state"
            );

            await mineBlock(20);

            await expect(tge.transferFunds(AddressZero)).to.be.revertedWith(
                "TGE in wrong state"
            );
        });

        it("Transferring funds for successful TGE by owner should work", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 1000, { value: parseUnits("10") });
            await mineBlock(20);

            await tge.transferFunds(AddressZero);
            expect(await provider.getBalance(pool.address)).to.equal(
                parseUnits("10")
            );
        });

        it("In successful TGE purchased funds are still locked until conditions are met", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 1000, { value: parseUnits("10") });
            await mineBlock(20);

            expect(await tge.lockedBalanceOf(other.address)).to.equal(500);
            await expect(tge.connect(other).unlock()).to.be.revertedWith(
                "Unlock not yet available"
            );
        });

        it("Funds are still locked if only TVL condition is met", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 2000, { value: parseUnits("20") });
            await mineBlock(20);

            expect(await tge.callStatic.getTVL()).to.equal(parseUnits("20"));
            await tge.setLockupTVLReached();

            expect(await tge.lockedBalanceOf(other.address)).to.equal(1000);
            await expect(tge.connect(other).unlock()).to.be.revertedWith(
                "Unlock not yet available"
            );
        });

        it("Funds are still locked if only duration condition is met", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 1000, { value: parseUnits("10") });
            await mineBlock(20);

            expect(await tge.lockedBalanceOf(other.address)).to.equal(500);
            await expect(tge.connect(other).unlock()).to.be.revertedWith(
                "Unlock not yet available"
            );
        });

        it("Funds can be unlocked as soon as all unlocked conditions are met", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 2000, { value: parseUnits("20") });
            await mineBlock(50);

            await tge.setLockupTVLReached();

            await tge.connect(other).unlock();
            expect(await tge.lockedBalanceOf(other.address)).to.equal(0);
            expect(await token.balanceOf(other.address)).to.equal(2000);
        });

        it("TVL unlock works with multiple currencies in TVL", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 1500, { value: parseUnits("15") });

            await token1.mint(other.address, parseUnits("1000"));
            await token1
                .connect(other)
                .approve(tge.address, parseUnits("1000"));
            await tge.connect(other).purchase(token1.address, 250);

            await token2.mint(other.address, parseUnits("1000"));
            await token2
                .connect(other)
                .approve(tge.address, parseUnits("1000"));
            await tge.connect(other).purchase(token2.address, 250);

            await tge.setLockupTVLReached();
            await mineBlock(50);
            await tge.connect(other).unlock();
        });

        it("Token has zero decimals", async function () {
            expect(await token.decimals()).to.equal(0);
        });

        it("Only service owner can whitelist", async function () {
            await expect(
                service.connect(other).addUserToWhitelist(other.address)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Adding to whitelist works", async function () {
            await service.addUserToWhitelist(other.address);

            const whitelist = await service.userWhitelist();
            expect(whitelist.length).to.equal(2);
            expect(whitelist[0]).to.equal(owner.address);
            expect(whitelist[1]).to.equal(other.address);

            expect(await service.userWhitelistLength()).to.equal(2);
            expect(await service.userWhitelistAt(0)).to.equal(owner.address);
            expect(await service.userWhitelistAt(1)).to.equal(other.address);
        });

        it("Can't add to whitelist twice", async function () {
            await expect(
                service.addUserToWhitelist(owner.address)
            ).to.be.revertedWith("Already whitelisted");
        });

        it("Only owner can remove from whitelist", async function () {
            await expect(
                service.connect(other).removeUserFromWhitelist(owner.address)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Can remove non-present from whitelist", async function () {
            await expect(
                service.removeUserFromWhitelist(other.address)
            ).to.be.revertedWith("Already not whitelisted");
        });

        it("Removing from whitelist works", async function () {
            await service.removeUserFromWhitelist(owner.address);

            expect(await service.userWhitelistLength()).to.equal(0);
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
            await service.addUserToWhitelist(other.address);
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
                .purchase(AddressZero, 1000, { value: parseUnits("10") });
            await mineBlock(20);

            await expect(
                service.createPool(pool.address, tokenData, tgeData, {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith("Previous TGE not failed");
        });

        it("Failed TGE can be recreated", async function () {
            await tge
                .connect(other)
                .purchase(AddressZero, 500, { value: parseUnits("5") });
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
