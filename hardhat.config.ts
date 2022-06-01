import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "hardhat-spdx-license-identifier";
import "solidity-coverage";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-deploy";
import "hardhat-dependency-compiler";
import "./tasks";

dotenv.config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

const networkConfig = (url: string | null | undefined) => ({
    url: url || "",
    accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
});

const defaultNetworkConfig = networkConfig(process.env.RPC_URL);

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: "0.8.13",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
    },
    networks: {
        hardhat: {
            forking: {
                url: process.env.FORKING_RPC_URL!,
                blockNumber: 14791509,
            },
        },
        mainnet: defaultNetworkConfig,
        ropsten: defaultNetworkConfig,
        rinkeby: defaultNetworkConfig,
        kovan: defaultNetworkConfig,
        BSCTest: networkConfig(
            "https://data-seed-prebsc-1-s1.binance.org:8545/"
        ),
        BSC: networkConfig("https://bsc-dataseed.binance.org/"),
        fantom: networkConfig("https://rpc.ftm.tools/"),
        mumbai: defaultNetworkConfig,
        polygon: defaultNetworkConfig,
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS !== undefined,
        currency: "USD",
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
    },
    spdxLicenseIdentifier: {
        overwrite: true,
        runOnCompile: true,
    },
    verify: {
        etherscan: {
            apiKey: process.env.ETHERSCAN_API_KEY,
        },
    },
};

export default config;
