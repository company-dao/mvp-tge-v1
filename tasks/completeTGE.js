const { getProxyAddress } = require("../helpers/proxymap");

task("completeTGE", "").setAction(async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  if (accounts.length === 0) {
    console.log("Must specify signers");
    return;
  }

  const poolAddress = "0xe865b190a4f8f65ada3e369f66c3493efd916229";
  const transferTarget = "0x613e46D06A3667D2b46bf6C0d9689aA17DbFCAbc";

  const pool = await ethers.getContractAt(
    "Pool",
    poolAddress
  );

  const dispatcher = await ethers.getContractAt(
    "Dispatcher",
    getProxyAddress("Dispatcher")
  );

  const tgeAddress = await pool.lastTGE();

  const tge = await ethers.getContractAt(
    "TGE",
    tgeAddress
  );

  /*
    Purchase
  */

  const tgeTokenPrice = (await tge.info()).price;
  console.log("tgeTokenPrice: " + tgeTokenPrice);

  const tgeHardCap = (await tge.info()).hardcap;
  const tgePurchaseValue = (BigInt(tgeHardCap) / BigInt(10 ** 18)) *  BigInt(tgeTokenPrice);
  console.log("tgeHardCap: " + tgeHardCap);

  // t = await tge.purchase(tgeHardCap, { value: tgePurchaseValue });
  // await t.wait(1);

  // t = await tge.transferFunds();
  // await t.wait(1);

  /*
    Proposal
  */

  t = await dispatcher.createTransferETHProposal(poolAddress, [transferTarget], [tgePurchaseValue / BigInt(2)], "test", "testMetaHash");
  await t.wait(1);

  const lastProposalId = await pool.lastProposalId();
  console.log("lastProposalId: " + lastProposalId);

  // Vote
  t = await pool.castVote(lastProposalId, BigInt(tgeHardCap) / BigInt(2) + BigInt(1), true);
  await t.wait(1);

  let proposalState = await pool.proposalState(lastProposalId);
  console.log("proposalState: " + proposalState);

  // Execute cancel proposal after base delay
  sleep(15000 * 5);
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
  solidity: "0.8.17",
};

function sleep(milliseconds) {
  console.log("Sleeping...");

  const date = Date.now();
  let currentDate = null;
  do {
    currentDate = Date.now();
  } while (currentDate - date < milliseconds);
}