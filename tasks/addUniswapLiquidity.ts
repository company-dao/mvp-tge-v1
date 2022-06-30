import { BigNumber, utils } from "ethers";
import { task } from "hardhat/config";
import bn from "bignumber.js";
import {
    ERC20Mock,
    IUniswapPositionManager,
    Service,
} from "../typechain-types";

function sqrt(value: BigNumber): BigNumber {
    return BigNumber.from(
        new bn(value.toString()).sqrt().toFixed().split(".")[0]
    );
}

function packArgs(
    from: string,
    token1: string,
    token2: string,
    amount1: BigNumber,
    amount2: BigNumber
) {
    if (token1 > token2) {
        [token1, token2] = [token2, token1];
        [amount1, amount2] = [amount2, amount1];
    }

    let xPriceSq: BigNumber;
    xPriceSq = amount2.mul(BigNumber.from(2).pow(96 * 2)).div(amount1);

    const amount1Hex = utils.hexZeroPad(amount1.toHexString(), 32).substring(2);
    const amount2Hex = utils.hexZeroPad(amount2.toHexString(), 32).substring(2);

    const xPrice = sqrt(xPriceSq);
    const xPriceHex = utils.hexZeroPad(xPrice.toHexString(), 32).substring(2);

    return [
        // first call
        "0x13ead562" + // encoded function signature ( createAndInitializePoolIfNecessary(address, address, uint24, uint160) )
            "000000000000000000000000" +
            token1.toLowerCase().substring(2) + // token1 address
            "000000000000000000000000" +
            token2.toLowerCase().substring(2) + // token2 address
            "00000000000000000000000000000000000000000000000000000000000001f4" + // fee
            xPriceHex, // sqrtPriceX96
        // second call
        "0x88316456" + // encoded function signature ( mint((address,address,uint24,int24,int24,uint256,uint256,uint256,uint256,address,uint256)) )
            "000000000000000000000000" +
            token1.toLowerCase().substring(2) + // token1 address
            "000000000000000000000000" +
            token2.toLowerCase().substring(2) + // token2 address
            "00000000000000000000000000000000000000000000000000000000000001f4" + // fee
            "fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff89f0e" + // tick lower
            "0000000000000000000000000000000000000000000000000000000000010dd8" + // tick upper
            amount1Hex + // amount 1 desired
            amount2Hex + // amount 2 desired
            "0000000000000000000000000000000000000000000000000000000000000000" + // min amount 1 expected
            "0000000000000000000000000000000000000000000000000000000000000000" + // min amount 2 expected
            "000000000000000000000000" +
            from.toLowerCase().substring(2) + // deployer address "00000000000000000000000000000000000000000000000000000000610bb8b6"
            "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", // deadline
    ];
}

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

task("addUniswapLiquidity", "Add uniswap liquidity to tokens").setAction(
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
        const [owner] = await getSigners();

        const token1 = await getContract<ERC20Mock>("ONE");
        const token2 = await getContract<ERC20Mock>("TWO");
        const token3 = await getContract<ERC20Mock>("THREE");

        const WETH_ADDRESS = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
        const weth = await getContractAt("IWETH", WETH_ADDRESS);

        const POSITION_MANAGER_ADDRESS =
            "0xC36442b4a4522E871399CD717aBDD847Ab11FE88";
        const positionManager = await getContractAt<IUniswapPositionManager>(
            "IUniswapPositionManager",
            POSITION_MANAGER_ADDRESS
        );

        await weth.deposit({ value: parseUnits("250") });
        await weth.approve(positionManager.address, parseUnits("250"));

        await token1.mint(owner.address, parseUnits("500000"));
        await token1.approve(positionManager.address, parseUnits("500000"));

        await token2.mint(owner.address, parseUnits("500000"));
        await token2.approve(positionManager.address, parseUnits("500000"));

        await token3.mint(owner.address, parseUnits("500000"));
        await token3.approve(positionManager.address, parseUnits("500000"));

        // Create pools and add liquidity

        await positionManager
            .connect(owner)
            .multicall(
                packArgs(
                    owner.address,
                    token1.address,
                    weth.address,
                    parseUnits("20000"),
                    parseUnits("100")
                )
            );

        await positionManager
            .connect(owner)
            .multicall(
                packArgs(
                    owner.address,
                    token1.address,
                    token2.address,
                    parseUnits("200000"),
                    parseUnits("100000")
                )
            );

        await positionManager
            .connect(owner)
            .multicall(
                packArgs(
                    owner.address,
                    token3.address,
                    weth.address,
                    parseUnits("1000"),
                    parseUnits("100")
                )
            );

        // Configure swap paths

        const service = await getContract<Service>("Service");

        await service.addTokensToWhitelist([AddressZero], ["0x"], ["0x"]);
        await service.addTokensToWhitelist(
            [token1.address, token2.address],
            [
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
                makePath([weth.address, 500, token1.address]),
                makePath([
                    weth.address,
                    500,
                    token1.address,
                    500,
                    token2.address,
                ]),
            ]
        );
        //const path1 = []
    }
);
