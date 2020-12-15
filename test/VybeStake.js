const BigNumber = require("bignumber.js");

let VybeToken = artifacts.require("Vybe");
let VybeStake = artifacts.require("VybeStake.sol");

const ONE = new BigNumber(1);
const DAY = 60 * 60 * 24;
const INITIAL = new BigNumber("2000000e18");

contract("Vybe token staking", async (accounts) => {
  it("Should mint 2,000,000 VYBE to the deployer", async () => {
    let VYBE = await VybeToken.deployed();
    assert(INITIAL.isEqualTo(await VYBE.totalSupply()));
    assert(INITIAL.isEqualTo(await VYBE.balanceOf.call(accounts[0])));
  });
  it("Should allow staking/unstaking VYBE", async () => {
    let VYBE = await VybeToken.deployed();
    let stake = await VybeStake.deployed();

    let first = new BigNumber("1000000e18");
    let next = new BigNumber("500000e18");
    let decrease = new BigNumber("300000e18");
    let total = first.plus(next);

    await VYBE.approve(stake.address, INITIAL);

    await stake.increaseStake(first);
    assert(first.isEqualTo(await stake.staked(accounts[0])));
    await stake.increaseStake(next);
    assert(total.isEqualTo(await stake.staked(accounts[0])));
    assert(
      INITIAL.minus(total).isEqualTo(await VYBE.balanceOf.call(accounts[0]))
    );

    await stake.decreaseStake(decrease);
    assert(total.minus(decrease).isEqualTo(await stake.staked(accounts[0])));
    await stake.decreaseStake(total.minus(decrease));
    // isZero doesn't work with returned BigNumbers
    assert(new BigNumber(0).isEqualTo(await stake.staked(accounts[0])));
    assert(INITIAL.isEqualTo(await VYBE.balanceOf.call(accounts[0])));
  });
  it("Test Staking results for 2 year and only claiming the reward every 6 month", async () => {
    let VYBE = await VybeToken.deployed();
    let stake = await VybeStake.deployed();

    await VYBE.approve(stake.address, "50000000000000000000");
    await stake.increaseStake("50000000000000000000", { from: accounts[0] });
    var balanceExpected = 50000000000000000000;
    // 2 years
    var testDuration = 200;
    var i = 30;
    for (i = i; i <= testDuration; i = i + 30) {
      await new Promise((resolve) => {
        web3.currentProvider.send(
          {
            jsonrpc: "2.0",
            method: "evm_increaseTime",
            params: [DAY * i],
            id: null,
          },
          resolve
        );
      });
      let estimatedRewards = await stake.rewardAvailable(accounts[0]);
      await stake.claimRewards({ from: accounts[0] });
      var balanceAfter = await stake.staked(accounts[0]);

      // ensure the staking rewards were paid
      let expected = await calculateExpected();

      function calculateExpected() {
        let monthsStakingFor = i / 30;
        let rewardPerMonth = 0;
        let reward = 0;
        if (monthsStakingFor >= 6) {
          rewardPerMonth = balanceExpected * 0.0083;
        } else if (monthsStakingFor >= 3) {
          rewardPerMonth = balanceExpected * 0.0067;
        } else if (monthsStakingFor >= 1) {
          rewardPerMonth = balanceExpected * 0.0042;
        }
        reward = rewardPerMonth * monthsStakingFor;
        return reward;
      }
      balanceExpected = balanceExpected + expected;
      console.log("----------------------");
      console.log(
        "\x1b[33m%s\x1b[0m",
        `Expected balance for ${(i / 30).toFixed()} months:`
      );
      console.log("\x1b[36m%s\x1b[0m", balanceExpected.toString());
      balanceExpected = parseFloat(balanceAfter);
      console.log("\x1b[33m%s\x1b[0m", `Actual balance:`);
      console.log(balanceAfter.toString());
      console.log("\x1b[33m%s\x1b[0m", `Estimated rewards:`);
      console.log(estimatedRewards.toString());
      console.log("----------------------");
    }
  });
});
