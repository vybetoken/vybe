let VybeToken = artifacts.require("Vybe");
let VybeStake = artifacts.require("VybeStake");
let LPtoken = artifacts.require("LPVybe");

const BigNumber = require("bignumber.js");
const DAY = 60 * 60 * 24;

function amounts(n) {
  return new BigNumber(`${n}e18`);
}

contract("VybeStake", (accounts) => {
  let vybe, lp, stake;
  const contractAddress = accounts[0];
  const liquidityProviders = [accounts[1], accounts[2], accounts[3]];
  before(async () => {
    // ======== Deploy all contracts ========== //
    vybe = await VybeToken.new();
    lp = await LPtoken.new();
    stake = await VybeStake.new(vybe.address, lp.address);
    // ========== Give all liquidity providers some LP tokens and approve stake contract for transfering them ============ //
    for (i = 0; i < liquidityProviders.length; i++) {
      await lp.transfer(liquidityProviders[i], amounts("100"), {
        from: contractAddress,
      });
      console.log(`Starting LP token balance on LP ${i}`);
      console.log(
        ((await lp.balanceOf(liquidityProviders[i])) / 1e18).toString()
      );
      await lp.approve(stake.address, amounts("100"), {
        from: liquidityProviders[i],
      });
    }
    await vybe.transferOwnership(stake.address);
  });
  it("deposit LP tokens", async () => {
    // ============ all liquidity providers increase stake ============ //
    for (i = 0; i < liquidityProviders.length; i++) {
      await stake.increaseLpStake(amounts("99"), {
        from: liquidityProviders[i],
      });
    }

    // ============== change time to 31 days in the future ============ //
    await new Promise((resolve) => {
      web3.currentProvider.send(
        {
          jsonrpc: "2.0",
          method: "evm_increaseTime",
          params: [DAY * 40],
          id: null,
        },
        resolve
      );
    });
    let monthlyLPReward = await stake._monthlyLPReward();
    let totalLpStakedUnrewarded = await stake._totalLpStakedUnrewarded();
    console.log(`Starting stats after 1 month`);
    console.log(`monthlyLPReward: ${monthlyLPReward / 1e18}`);
    // ============== all Liquidity providers claim rewards =========== //
    for (i = 0; i < liquidityProviders.length; i++) {
      await stake.claimLpRewards({
        from: liquidityProviders[i],
      });
      let LpStaked = await stake.lpBalanceOf(liquidityProviders[i]);
      let vybeRewarded = await vybe.balanceOf(liquidityProviders[i]);
      console.log(`========== Liquidity Provider ${i + 1} Stats =========`);
      console.log("\x1b[33m%s\x1b[0m", `Lp staked: ${LpStaked / 1e18}`);
      console.log("\x1b[33m%s\x1b[0m", `Lp rewarded: ${vybeRewarded / 1e18}`);

      monthlyLPReward = await stake._monthlyLPReward();
      totalLpStakedUnrewarded = await stake._totalLpStakedUnrewarded();
      console.log(
        "\x1b[36m%s\x1b[0m",
        `Total LP Reward left: ${monthlyLPReward / 1e18}`
      );
      console.log(
        "\x1b[36m%s\x1b[0m",
        `Total Unrewarded LP staked: ${totalLpStakedUnrewarded / 1e18}`
      );
    }
  });
});
