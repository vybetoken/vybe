let VybeToken = artifacts.require("Vybe");
let VybeStake = artifacts.require("VybeStake");
let VybeLoan = artifacts.require("VybeLoan");

module.exports = async (deployer) => {
  let VYBE = await deployer.deploy(VybeToken).chain;
  let stake = await deployer.deploy(VybeStake, VYBE.address);
  await VYBE.transferOwnership(stake.address);
  let loan = await deployer.deploy(VybeLoan, VYBE.address, stake.address);
  await stake.addMelody(loan.address);
};
