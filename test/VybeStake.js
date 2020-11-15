const BigNumber = require("bignumber.js");

let VybeToken = artifacts.require("Vybe");
let VybeStake = artifacts.require("VybeStake");

const ONE = new BigNumber(1);
const DAY = 60 * 60 * 24;
const INITIAL = new BigNumber("2000000e18");

contract("Vybe test", async (accounts) => {
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
  it("Test Staking results for 1 years and claiming rewards every month", async () => {
    let VYBE = await VybeToken.deployed();
    let stake = await VybeStake.deployed();

    await VYBE.approve(stake.address, 10000);
    await stake.increaseStake(10000);
    var balanceExpected = 10000;

    for (var i = 0; i < 365; i = i + 31) {
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
      await stake.claimRewards().then(function (result) {});
      var balanceAfter = await stake.staked.call(accounts[0]);

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
      console.log("\x1b[33m%s\x1b[0m", `Actual balance:`);
      console.log(balanceAfter.toString());
      console.log("----------------------");

      // allow a 1% variance due to division rounding
    }
  });
  it("Test Staking results for 2 year and only claiming the reward every 6 month", async () => {
    let VYBE = await VybeToken.deployed();
    let stake = await VybeStake.deployed();

    await VYBE.approve(stake.address, 10000);
    await stake.increaseStake(10000);
    var balanceExpected = 10000;

    for (var i = 212; i < 700; i = i + 212) {
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
      await stake.claimRewards().then(function (result) {});
      var balanceAfter = await stake.staked.call(accounts[0]);

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
      console.log("\x1b[33m%s\x1b[0m", `Actual balance:`);
      console.log(balanceAfter.toString());
      console.log("----------------------");

      // allow a 1% variance due to division rounding
    }
  });
});
