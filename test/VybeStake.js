const BigNumber = require("bignumber.js");

const VybeToken = artifacts.require("Vybe");
const VybeStake = artifacts.require("VybeStake");
const VybeLoan = artifacts.require("VybeLoan");
const VybeDAO = artifacts.require("VybeDAO");


contracts("staking test", async (accounts) => {
 let VYBE = await Vybetoken.new(VYBE.address);
 let Stake = await VybeStake.new();
 let StakeSomeVybe = Vybe
}