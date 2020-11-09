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
});
