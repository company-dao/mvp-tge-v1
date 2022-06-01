import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumberish } from "ethers";
import { deployments, ethers, network, run } from "hardhat";

const { getContract, getContractAt, getSigners } = ethers;
const { MaxUint256 } = ethers.constants;
const { parseUnits } = ethers.utils;

describe("Test Sample", function () {
    let owner: SignerWithAddress, other: SignerWithAddress;
    let snapshotId: any;

    before(async function () {
        [owner, other] = await getSigners();

        await deployments.fixture();

        // Make setup
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

    it("Some test", async function () {});
});
