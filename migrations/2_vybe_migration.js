let VybeToken = artifacts.require("Vybe");
let VybeStake = artifacts.require("VybeStake");
let VybeDAO = artifacts.require("VybeDAO");
let _LPVybe = artifacts.require("LPVybe");

module.exports = async (deployer) => {
  let VYBE = await deployer.deploy(VybeToken).chain;
  let LP = await deployer.deploy(_LPVybe);
  let stake = await deployer.deploy(VybeStake, VYBE.address, LP.address);
  await VYBE.transferOwnership(stake.address);
  let dao = await deployer.deploy(VybeDAO, stake.address);
  await stake.upgradeDevelopmentFund(dao.address);
  await stake.transferOwnership(dao.address);
};
