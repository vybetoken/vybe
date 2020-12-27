let VybeLP = artifacts.require("VybeLP");
let Vybe = artifacts.require("Vybe");
let LPtokensmock = artifacts.require("LPtokensmock");
let RewardsDistributionRecipient = artifacts.require(
  "RewardsDistributionRecipient"
);
const BigNumber = require("bignumber.js");
const DAY = 60 * 60 * 24;

function amounts(n) {
  return new BigNumber(`${n}e18`);
}

contract("UniswapLP rewards", (accounts) => {
  let uniswap, vybe, lp, vybelp;
  const contractAddress = accounts[0];
  const liquidityProviders = [accounts[1], accounts[2], accounts[3]];
  before(async () => {
    // deploys contract

    vybe = await Vybe.new();
    lp = await LPtokensmock.new();
    vybelp = await VybeLP.new(contractAddress, vybe.address, lp.address);
    for (i = 0; i < liquidityProviders.length; i++) {
      await lp.transfer(liquidityProviders[i], amounts("10"), {
        from: contractAddress,
      });
    }
    await vybe.transfer(vybelp.address, "10000000");
  });
  it("1 user depositing LP tokens, waiting 1 month and exiting", async () => {
    // check staker balance
    let lpBalance = await lp.balanceOf(liquidityProviders[0]);
    //approve LP token transfer
    await lp.approve(vybelp.address, lpBalance, {
      from: liquidityProviders[0],
    });
    // Stake lp tokens
    await vybelp.stake(amounts("10"), { from: liquidityProviders[0] });
    await vybelp.notifyRewardAmount("10000", { from: accounts[0] });
    // change the time to 1 month from now
    await new Promise((resolve) => {
      web3.currentProvider.send(
        {
          jsonrpc: "2.0",
          method: "evm_increaseTime",
          params: [DAY * 200],
          id: null,
        },
        resolve
      );
    });
    // check balance
    await vybelp.notifyRewardAmount("10000", { from: accounts[0] });
    let lpBalanceAfter = await vybelp.balanceOf(liquidityProviders[0]);
    await vybelp.exit({ from: liquidityProviders[0] });
    let vybeRewards = await vybelp.earned(liquidityProviders[0]);
    let _rewardPerToken = await vybelp.rewardPerToken();
    console.log(_rewardPerToken.toString());
    console.log("-------AFTER--------");
    console.log(`Vybe rewarded: ${(vybeRewards / 1e18).toString()}`);
    console.log(`LP tokens: ${(lpBalanceAfter / 1e18).toString()}`);
    console.log(`For 30 days`);

    console.log("--------------------");
  });
});
