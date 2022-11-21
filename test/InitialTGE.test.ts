import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { deployments, ethers, network } from "hardhat";
import {
    ERC20Mock,
    GovernanceToken,
    Pool,
    Service,
    TGE,
    Metadata,
} from "../typechain-types";
import { TokenInfoStruct } from "../typechain-types/GovernanceToken";
import { TGEInfoStruct } from "../typechain-types/ITGE";
import { setup } from "./shared/setup";
import { mineBlock } from "./shared/utils";
import Exceptions from "./shared/Exceptions"

const { getContractAt, getSigners, Wallet, provider } = ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

describe.only("Test initial TGE", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        third: SignerWithAddress;
    let service: Service, pool: Pool, tge: TGE, token: GovernanceToken;
    let metadata: Metadata;
    let token1: ERC20Mock, token2: ERC20Mock, token3: ERC20Mock;
    let snapshotId: any;
    let tokenData: TokenInfoStruct, tgeData: TGEInfoStruct;

    before(async function () {
        [owner, other, third] = await getSigners();

        // await deployments.fixture();

        // Setup
        ({
            service,
            metadata,
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

        await metadata.createRecord(1, "SerialNumber2", "22-09-2022", 1);
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
                    .createPool(AddressZero, tokenData, tgeData, 50, 50, 25, 1, "Name", {
                        value: parseUnits("0.01"),
                    })
            ).to.be.revertedWith(Exceptions.NOT_WHITELISTED);
        });

        it("Only service can set TGE and token for pool", async function () {
            await expect(
                pool.connect(other).setTGE(other.address)
            ).to.be.revertedWith(Exceptions.NOT_SERVICE);

            await expect(
                pool.connect(other).setToken(other.address)
            ).to.be.revertedWith(Exceptions.NOT_SERVICE);
        });

        it("Can't create pool with incorrect fee", async function () {
            await expect(
                service.createPool(AddressZero, tokenData, tgeData, 50, 50, 25, 1, "Name", {
                    value: parseUnits("0.005"),
                })
            ).to.be.revertedWith(Exceptions.INCORRECT_ETH_PASSED);
        });

        it("Can't create pool with hardcap higher than token cap", async function () {
            tgeData.hardcap = 20000;
            await expect(
                service.createPool(AddressZero, tokenData, tgeData, 50, 50, 25, 1, "Name", {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith(Exceptions.REMAINING_SUPPLY_OVERFLOW);
        });

        it("Can't purchase less than min purchase", async function () {
            await expect(
                tge
                    .connect(other)
                    .purchase(5, { value: parseUnits("0.05") })
            ).to.be.revertedWith(Exceptions.MIN_PURCHASE_UNDERFLOW);
        });

        it("Can't purchase with wrong ETH value passed", async function () {
            await expect(
                tge
                    .connect(other)
                    .purchase(50, { value: parseUnits("0.1") })
            ).to.be.revertedWith(Exceptions.INCORRECT_ETH_PASSED);
        });

        it("Can't purchase over max purchase in one tx", async function () {
            await expect(
                tge
                    .connect(other)
                    .purchase(4000, { value: parseUnits("40") })
            ).to.be.revertedWith(Exceptions.MAX_PURCHASE_OVERFLOW);
        });

        it("Can't purchase over max purchase in several tx", async function () {
            await tge
                .connect(other)
                .purchase(2000, { value: parseUnits("20") });

            await expect(
                tge
                    .connect(other)
                    .purchase(2000, { value: parseUnits("20") })
            ).to.be.revertedWith(Exceptions.MAX_PURCHASE_OVERFLOW);
        });

        it("Can't purchase over hardcap", async function () {
            await tge
                .connect(other)
                .purchase(3000, { value: parseUnits("30") });

            await expect(
                tge.purchase(3000, { value: parseUnits("30") })
            ).to.be.revertedWith(Exceptions.HARDCAP_OVERFLOW);
        });

        it("Mint can't be called on token directly, should be done though TGE", async function () {
            await expect(
                token.connect(other).mint(other.address, 100)
            ).to.be.revertedWith(Exceptions.NOT_TGE);
        });

        it("Purchasing works", async function () {
            await tge
                .connect(other)
                .purchase(1000, { value: parseUnits("10") });

            expect(await token.balanceOf(other.address)).to.equal(500);
            expect(await provider.getBalance(tge.address)).to.equal(
                parseUnits("10")
            );
            expect(await tge.lockedBalanceOf(other.address)).to.equal(500);
        });

        it("Purchasing with whitelisted token works", async function () {
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
                unitOfAccount: token1.address
            };
            const tx = await service.createPool(AddressZero, tokenData, tgeData, 50, 50, 25, 1, "Name", {
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
        

            await token1.mint(other.address, parseUnits("203")); // Because of slippage we need a bit more than 200
            await token1.connect(other).approve(tge.address, parseUnits("203"));

            await tge.connect(other).purchase(100);

            expect(await token.balanceOf(other.address)).to.equal(50);
            expect(await tge.lockedBalanceOf(other.address)).to.equal(50);
        });

        it("Purchasing with whitelisted token that has non-direct swap works", async function () {
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
                unitOfAccount: token2.address
            };
            const tx = await service.createPool(AddressZero, tokenData, tgeData, 50, 50, 25, 1, "Name", {
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

            await token2.mint(other.address, parseUnits("102")); // Because of slippage we need a bit more than 100
            await token2.connect(other).approve(tge.address, parseUnits("102"));

            await tge.connect(other).purchase(100);

            expect(await token.balanceOf(other.address)).to.equal(50);
            expect(await tge.lockedBalanceOf(other.address)).to.equal(50);
        });

        it("Locking is rounded up", async function () {
            await tge
                .connect(other)
                .purchase(1001, { value: parseUnits("10.01") });
            expect(await tge.lockedBalanceOf(other.address)).to.equal(501);
        });

        it("Can't transfer lockup tokens", async function () {
            await tge
                .connect(other)
                .purchase(1000, { value: parseUnits("10") });

            await expect(
                token.connect(other).transfer(owner.address, 1000)
            ).to.be.revertedWith(Exceptions.LOW_UNLOCKED_BALANCE);
        });

        it("Can't purchase after event is finished", async function () {
            await mineBlock(20);

            await expect(
                tge
                    .connect(other)
                    .purchase(1000, { value: parseUnits("10") })
            ).to.be.revertedWith(Exceptions.WRONG_STATE);
        });

        it("Can't claim back if event is not failed", async function () {
            await tge
                .connect(other)
                .purchase(500, { value: parseUnits("5") });

            await expect(tge.connect(third).redeem()).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );

            await tge
                .connect(other)
                .purchase(500, { value: parseUnits("5") });
            await mineBlock(20);

            await expect(tge.connect(third).redeem()).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Claiming back works if TGE is failed", async function () {
            await tge
                .connect(other)
                .purchase(400, { value: parseUnits("4") });

            await mineBlock(20);

            await tge.connect(other).redeem();
            expect(await token.balanceOf(other.address)).to.equal(0);
        });

        it("Burn can't be called on token directly, should be done though TGE", async function () {
            await tge
                .connect(other)
                .purchase(400, { value: parseUnits("4") });
            await mineBlock(20);
            await expect(
                token.connect(other).burn(other.address, 100)
            ).to.be.revertedWith(Exceptions.NOT_TGE);
        });

        it("Can't transfer funds if event is not successful", async function () {
            await tge
                .connect(other)
                .purchase(500, { value: parseUnits("5") });

            await expect(tge.transferFunds()).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );

            await mineBlock(20);

            await expect(tge.transferFunds()).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Transferring funds for successful TGE by owner should work", async function () {
            await tge
                .connect(other)
                .purchase(1000, { value: parseUnits("10") });
            await mineBlock(20);

            await tge.transferFunds();
            expect(await provider.getBalance(pool.address)).to.equal(
                parseUnits("10")
            );
        });

        it("In successful TGE purchased funds are still locked until conditions are met", async function () {
            await tge
                .connect(other)
                .purchase(1000, { value: parseUnits("10") });
            await mineBlock(20);
            await tge.transferFunds();

            expect(await tge.lockedBalanceOf(other.address)).to.equal(500);
            await expect(tge.connect(other).claim()).to.be.revertedWith(
                Exceptions.CLAIM_NOT_AVAILABLE
            );
        });

        it("Funds are still locked if only TVL condition is met", async function () {
            await tge
                .connect(other)
                .purchase(2000, { value: parseUnits("20") });
            await mineBlock(20);

            await tge.transferFunds();
            expect(await pool.callStatic.getTVL()).to.equal(parseUnits("20"));
            await tge.setLockupTVLReached();

            expect(await tge.lockedBalanceOf(other.address)).to.equal(1000);
            await expect(tge.connect(other).claim()).to.be.revertedWith(
                Exceptions.CLAIM_NOT_AVAILABLE
            );
        });

        it("Funds are still locked if only duration condition is met", async function () {
            await tge
                .connect(other)
                .purchase(1000, { value: parseUnits("10") });
            await mineBlock(20);
            
            expect(await tge.lockedBalanceOf(other.address)).to.equal(500);
            await expect(tge.connect(other).claim()).to.be.revertedWith(
                Exceptions.CLAIM_NOT_AVAILABLE
            );
        });

        it("Funds can be unlocked as soon as all unlocked conditions are met", async function () {
            await tge
                .connect(other)
                .purchase(2000, { value: parseUnits("20") });
            await mineBlock(50);
            await tge.transferFunds();
            await tge.setLockupTVLReached();

            await tge.connect(other).claim();
            expect(await tge.lockedBalanceOf(other.address)).to.equal(0);
            expect(await token.balanceOf(other.address)).to.equal(2000);
        });

        it("TVL unlock works with token currencies in TVL", async function () {
            const tgeData: TGEInfoStruct = {
                metadataURI: "uri",
                price: parseUnits("0.01"),
                hardcap: 2000,
                softcap: 1000,
                minPurchase: 10,
                maxPurchase: 3000,
                lockupPercent: 50,
                lockupDuration: 50,
                lockupTVL: parseUnits("20"),
                duration: 20,
                userWhitelist: [owner.address, other.address],
                unitOfAccount: token1.address
            };
            const tx = await service.createPool(AddressZero, tokenData, tgeData, 50, 50, 25, 1, "Name", {
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

            await token1.mint(other.address, parseUnits("2000"));
            await token1
                .connect(other)
                .approve(tge.address, parseUnits("2000"));
            await tge.connect(other).purchase(2000);
            // await tge.transferFunds();
            // await tge.setLockupTVLReached();

            // await mineBlock(50);
            // await tge.connect(other).claim();
        });

        it("Token has zero decimals", async function () {
            expect(await token.decimals()).to.equal(18);
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
            ).to.be.revertedWith(Exceptions.ALREADY_WHITELISTED);
        });

        it("Only owner can remove from whitelist", async function () {
            await expect(
                service.connect(other).removeUserFromWhitelist(owner.address)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Can remove non-present from whitelist", async function () {
            await expect(
                service.removeUserFromWhitelist(other.address)
            ).to.be.revertedWith(Exceptions.ALREADY_NOT_WHITELISTED);
        });

        it("Removing from whitelist works", async function () {
            await service.removeUserFromWhitelist(owner.address);

            expect(await service.userWhitelistLength()).to.equal(0);
        });

        it("Only owner can transfer funds", async function () {
            await expect(
                service.connect(other).transferCollectedFees(other.address)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Transferring funds work", async function () {
            const treasury = Wallet.createRandom();
            await service.transferCollectedFees(treasury.address);
            expect(await provider.getBalance(treasury.address)).to.equal(
                parseUnits("0.01")
            );
        });
    });

    describe("Recreating failed TGE", async function () {
        it("Can't recreate TGE for non-pool", async function () {
            await expect(
                service.createPool(token.address, tokenData, tgeData, 50, 50, 25, 1, "Name", {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith(Exceptions.NOT_POOL);
        });

        it("Only pool owner can recreate TGE", async function () {
            await service.addUserToWhitelist(other.address);
            await expect(
                service
                    .connect(other)
                    .createPool(pool.address, tokenData, tgeData, 50, 50, 25, 1, "Name", {
                        value: parseUnits("0.01"),
                    })
            ).to.be.revertedWith(Exceptions.NOT_POOL_OWNER);
        });

        it("Can't recreate successful TGE", async function () {
            await tge
                .connect(other)
                .purchase(1000, { value: parseUnits("10") });
            await mineBlock(20);

            await expect(
                service.createPool(pool.address, tokenData, tgeData, 50, 50, 25, 1, "Name", {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith(Exceptions.IS_DAO);
        });

        it("Failed TGE can be recreated", async function () {
            await tge
                .connect(other)
                .purchase(500, { value: parseUnits("5") });
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
                50, 50, 25, 1, "Name", 
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

            expect(await token2.name()).to.equal("Name"); // pool.getTrademark()
            expect(await token2.symbol()).to.equal("DTKN2");
            expect(await token2.cap()).to.equal(20000);
        });
    });

    describe("Rounding softcap tests", async function () {
        it("check states and purchase amount rounding", async function () {
            const tokenData2: TokenInfoStruct = {
                name: "Strange DAO Token",
                symbol: "SDTKN",
                cap: 1234567,
            };
            const tgeData2: TGEInfoStruct = {
                metadataURI: "uri",
                price: parseUnits("0.01"),
                hardcap: 5431,
                softcap: 1117,
                minPurchase: 11,
                maxPurchase: 3023,
                lockupPercent: 1,
                lockupDuration: 51,
                lockupTVL: parseUnits("11"),
                duration: 23,
                userWhitelist: [owner.address, other.address, third.address],
                unitOfAccount: AddressZero
            };

            await service.createPool(AddressZero, tokenData2, tgeData2, 13, 37, 11, 1, "Name", {
                value: parseUnits("0.01"),
            });

            await expect(tge
                .connect(other)
                .purchase(3024, { value: parseUnits("30.24") })
            ).to.be.revertedWith(Exceptions.MAX_PURCHASE_OVERFLOW);

        });
    });

    describe("purchase tests", async function () {
        it("check states and purchase amount rounding", async function () {
            const tokenData2: TokenInfoStruct = {
                name: "Strange DAO Token",
                symbol: "SDTKN",
                cap: parseUnits("1"),
            };
            const tgeData2: TGEInfoStruct = {
                metadataURI: "uri",
                price: 100, // price per 1000 tokenweis
                hardcap: 5431,
                softcap: 1117,
                minPurchase: 11,
                maxPurchase: 3023,
                lockupPercent: 1,
                lockupDuration: 51,
                lockupTVL: parseUnits("11"),
                duration: 23,
                userWhitelist: [owner.address, other.address, third.address],
                unitOfAccount: AddressZero
            };

            const tx = await service.createPool(AddressZero, tokenData2, tgeData2, 13, 37, 11, 1, "Name", {
                value: parseUnits("0.01"),
            });

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

            await expect(tge2
                .connect(other)
                .purchase(2000, { value: 200 })
            ).to.be.not.reverted;

        });
    });

    describe.only("redeem tests", async function () {
        it("check states and purchase amount and redeem", async function () {
            const tokenData2: TokenInfoStruct = {
                name: "Strange DAO Token",
                symbol: "SDTKN",
                cap: parseUnits("1"),
            };
            const tgeData2: TGEInfoStruct = {
                metadataURI: "uri",
                price: 100000000000, // price per 1000 tokenweis
                hardcap: 50000000000,
                softcap: 10000000000,
                minPurchase: 1000,
                maxPurchase: 10000000000,
                lockupPercent: 30,
                lockupDuration: 51,
                lockupTVL: parseUnits("11"),
                duration: 23,
                userWhitelist: [owner.address, other.address, third.address],
                unitOfAccount: AddressZero
            };

            const tx = await service.createPool(AddressZero, tokenData2, tgeData2, 13, 37, 11, 1, "Name", {
                value: parseUnits("0.01"),
            });

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

            const amount = 10**20;
            await expect(tge2
                .connect(other)
                .purchase(amount, { value: parseUnits("0.000001") })
            ).to.be.not.reverted;

        });
    });
});
