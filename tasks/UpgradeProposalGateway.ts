import { task } from "hardhat/config";

task("upgrade:proposalGateway", "Upgrade ProposalGateway Implementation")
    .setAction(async function ( { _ },
        { getNamedAccounts, ethers: { getContractFactory }, upgrades: { upgradeProxy } }
    ) {
        const { deployer } = await getNamedAccounts();

        const proposalGateway = await getContractFactory("ProposalGateway");
        const gatewayAddress = "0x9Ea94C63D6b454fCf9a81e7Bb1db05d7f49d8ae5"; // 0x9cDccE49d62e52Ea74071565cA83eb5780194e36
        const newAddress = await upgradeProxy(gatewayAddress, proposalGateway);
        console.log("ProposalGateway upgraded to: ", newAddress);
     
    });
