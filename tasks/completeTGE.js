const { getProxyAddress } = require("../helpers/proxymap");

task("completeTGE", "").setAction(async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  if (accounts.length === 0) {
    console.log("Must specify signers");
    return;
  }

  const poolAddress = "0x5dC0f9b0a4Fa42013074999cDf105B2A546fd399";
  const transferTarget = "0x613e46D06A3667D2b46bf6C0d9689aA17DbFCAbc";

  const pool = await ethers.getContractAt(
    "Pool",
    poolAddress
  );

  const proposalGateway = await ethers.getContractAt(
    "ProposalGateway",
    getProxyAddress("ProposalGateway")
  );

  const tgeAddress = await pool.tge();
  const gnosisAddress = await pool.gnosisSafe();

  const tge = await ethers.getContractAt(
    "TGE",
    tgeAddress
  );

  /*
    Purchase
  */

  const tgeTokenPrice = await tge.price();
  console.log("tgeTokenPrice: " + tgeTokenPrice);

  const tgeHardCap = await tge.hardcap();
  const tgePurchaseValue = (BigInt(tgeHardCap) / BigInt(10 ** 18)) *  BigInt(tgeTokenPrice);
  console.log("tgeHardCap: " + tgeHardCap);

  t = await tge.purchase(tgeHardCap, { value: tgePurchaseValue });
  await t.wait(1);

  t = await tge.transferFunds();
  await t.wait(1);

  /*
    Proposal
  */

  t = await proposalGateway.createTransferETHProposal(poolAddress, transferTarget, tgePurchaseValue / BigInt(2), "test");
  await t.wait(1);

  const lastProposalId = await pool.lastProposalId();
  console.log("lastProposalId: " + lastProposalId);

  t = await pool.castVote(lastProposalId, BigInt(tgeHardCap) / BigInt(10), true);
  await t.wait(1);

  let proposalState = await pool.proposalState(lastProposalId);
  console.log("proposalState: " + proposalState);

  t = await pool.executeBallot(lastProposalId);
  await t.wait(1);

  proposalState = await pool.proposalState(lastProposalId);
  console.log("proposalState: " + proposalState);
 
  //  t = await proposalGateway.createTransferERC20Proposal(poolAddress, "0x0", transferTarget, tgeHardCap / 2, "test");
//  await t.wait(1);

  console.log("\n==== Task Complete ====");
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
};
