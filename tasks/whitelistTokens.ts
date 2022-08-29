import { BigNumber, utils } from "ethers";
import { task } from "hardhat/config";
import bn from "bignumber.js";
import { ERC20Mock, Service, WhitelistedTokens } from "../typechain-types";

function makePath(path: Array<string | number>) {
    let res = "";
    for (let i = 0; i < path.length; i += 2) {
        res += (path[i] as string).substring(2);
        if (i < path.length - 1) {
            res += utils
                .hexZeroPad(BigNumber.from(path[i + 1]).toHexString(), 3)
                .substring(2);
        }
    }
    return "0x" + res;
}

task("whitelistTokens", "Whitelist tokens in Service").setAction(
    async function (
        { _ },
        {
            ethers: {
                getSigners,
                getContract,
                getContractAt,
                utils: { parseUnits },
                constants: { AddressZero },
            },
        }
    ) {
        // Configure swap paths

        console.log("Adding to whitelist");

        // const service = await getContract<Service>("Service");
        const whitelistedTokens = await getContract<WhitelistedTokens>("WhitelistedTokens");

        const WETH_ADDRESS = "0xb4fbf271143f4fbf7b91a5ded31805e42b2208d6"; // WETH in Goerli
        const weth = await getContractAt("IWETH", WETH_ADDRESS);

        const token1 = await getContract<ERC20Mock>("ONE");
        const token2 = await getContract<ERC20Mock>("TWO");

        await whitelistedTokens
            .addTokensToWhitelist(
                [AddressZero, token1.address, token2.address],
                [
                    "0x",
                    makePath([token1.address, 500, weth.address]),
                    makePath([
                        token2.address,
                        500,
                        token1.address,
                        500,
                        weth.address,
                    ]),
                ],
                [
                    "0x",
                    makePath([weth.address, 500, token1.address]),
                    makePath([
                        weth.address,
                        500,
                        token1.address,
                        500,
                        token2.address,
                    ]),
                ]
            )
            .then((tx) => tx.wait());
    }
);
