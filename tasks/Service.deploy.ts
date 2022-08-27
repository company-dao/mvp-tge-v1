import { task } from "hardhat/config";
import { Directory, WhitelistedTokens, Metadata } from "../typechain-types";

task("deploy:service", "Deploy Service contract")
    .addOptionalParam("fee", "Fee for TGE creation", "0")
    .addOptionalParam("ballotQuorumThreshold", "Ballot quorum threshold", "50")
    .addOptionalParam("ballotDecisionThreshold", "Ballot decision threshold", "50")
    .addOptionalParam("ballotLifespan", "Ballot lifespan", "25")
    .setAction(async function (
        { fee, ballotQuorumThreshold, ballotDecisionThreshold, ballotLifespan },
        { getNamedAccounts, deployments: { deploy }, ethers: { getContract, getContractFactory }, upgrades: { deployBeacon, deployProxy } }
    ) {
        const { deployer } = await getNamedAccounts();

        const directory = await getContract<Directory>("Directory");
        const proposalGateway = await getContract("ProposalGateway");
        const whitelistedTokens = await getContract<WhitelistedTokens>("WhitelistedTokens");
        const metadata = await getContract<Metadata>("Metadata");

        // const poolBeacon = await deploy("Pool", {
        //     from: deployer,
        //     proxy: {
        //         proxyContract: "OpenZeppelinBeaconProxy",
        //         methodName: "initialize",
        //     },
        //     args: [],
        //     log: true,
        // });

        // const tokenBeacon = await deploy("GovernanceToken", {
        //     from: deployer,
        //     proxy: {
        //         proxyContract: "OpenZeppelinBeaconProxy",
        //         methodName: "initialize",
        //     },
        //     args: [],
        //     log: true,
        // });

        // const tgeBeacon = await deploy("TGE", {
        //     from: deployer,
        //     proxy: {
        //         proxyContract: "OpenZeppelinBeaconProxy",
        //         methodName: "initialize",
        //     },
        //     args: [],
        //     log: true,
        // });

        // const pool = await getContractFactory("Pool");
        // const poolBeacon = await deployBeacon(pool);
        // await poolBeacon.deployed();
        // console.log("PoolBeacon deployed to: ", poolBeacon.address);

        // const token = await getContractFactory("GovernanceToken");
        // const tokenBeacon = await deployBeacon(token);
        // await tokenBeacon.deployed();
        // console.log("TokenBeacon deployed to: ", tokenBeacon.address);

        // const tge = await getContractFactory("TGE");
        // const tgeBeacon = await deployBeacon(tge);
        // await tgeBeacon.deployed();
        // console.log("TGEBeacon deployed to: ", tgeBeacon.address);

        // const poolMaster = await deploy("Pool", {
        //     from: deployer,
        //     args: [],
        //     log: true,
        // });

        // const tokenMaster = await deploy("GovernanceToken", {
        //     from: deployer,
        //     args: [],
        //     log: true,
        // });

        // const tgeMaster = await deploy("TGE", {
        //     from: deployer,
        //     args: [],
        //     log: true,
        // });

        // const metadataMaster = await deploy("Metadata", {
        //     from: deployer,
        //     args: [],
        //     log: true,
        // });

        const UNISWAP_ROUTER_ADDRESS =
            "0xe592427a0aece92de3edee1f18e0157c05861564";
        const UNISWAP_QUOTER_ADDRESS =
            "0xb27308f9f90d607463bb33ea1bebb41c27ce5ab6";
        
        // const Service = await getContractFactory("Service");
        // const service = await deployProxy(Service, 
        //     [
        //         directory.address,
        //         poolBeacon.address,
        //         proposalGateway.address,
        //         tokenBeacon.address,
        //         tgeBeacon.address,
        //         metadata.address, 
        //         fee,
        //         [
        //             ballotQuorumThreshold, 
        //             ballotLifespan, 
        //             ballotDecisionThreshold,
        //         ],
        //         UNISWAP_ROUTER_ADDRESS,
        //         UNISWAP_QUOTER_ADDRESS,
        //         whitelistedTokens.address
        //     ],
        //     {
        //         initializer: 'initialize',
        //     },
            
        // );
        // await service.deployed();
        // console.log("Service deployed to: ", service.address);

        const PoolBeacon = "0x83B2bF6ef4De89101D6C82Ed06812D4aED7aCd07";
        const TokenBeacon = "0xE76017Cec890827a4f604855Dba30Ef2063A55d1";
        const TGEBeacon = "0x697E11d70bBc001c93C512307905F37136aA40fC";

        const service = await deploy("Service", {
            from: deployer,
            proxy: {
                // proxyContract: "OpenZeppelinTransparentProxy",
                methodName: "initialize",
            },
            args: [
                directory.address,
                PoolBeacon, // poolBeacon.address,
                proposalGateway.address,
                TokenBeacon, // tokenBeacon.address,
                TGEBeacon, // tgeBeacon.address,
                metadata.address, 
                fee,
                [
                    ballotQuorumThreshold, 
                    ballotLifespan, 
                    ballotDecisionThreshold,
                ],
                UNISWAP_ROUTER_ADDRESS,
                UNISWAP_QUOTER_ADDRESS,
                whitelistedTokens.address
            ],
            log: true,
        });

        await directory.setService(service.address);
        console.log("Service is set in Directory");

        await metadata.setService(service.address);
        console.log("Service is set in Metadata");
    });
