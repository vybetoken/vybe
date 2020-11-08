let VybeToken = artifacts.require("Vybe");
let VybeStake = artifacts.require("VybeStake");
let VybeLoan = artifacts.require("VybeLoan");
let VybeDAO = artifacts.require("VybeDAO");

module.exports = async (deployer) => {
  let VYBE = await deployer.deploy(VybeToken).chain;
  let stake = await deployer.deploy(VybeStake, VYBE.address);
  await VYBE.transferOwnership(stake.address);

  let loan = await deployer.deploy(VybeLoan, VYBE.address, stake.address);
  await stake.addMelody(loan.address);

  let dao = await deployer.deploy(VybeDAO, stake.address);
  await stake.upgradeDevelopmentFund(dao.address);
  await stake.transferOwnership(dao.address);
};
