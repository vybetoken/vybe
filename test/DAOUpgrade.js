let VybeToken = artifacts.require("Vybe");
let VybeStake = artifacts.require("VybeStake");
let DAOCont = artifacts.require("DAO");

contract("Vybe token staking", async (accounts) => {
  before("Should mint 2,000,000 VYBE to the deployer", async () => {
    let VYBE = await VybeToken.deployed();
    let stake = await VybeStake.deployed();
    let DAO = await DAOCont.deployed();

    await VYBE.transferOwnership(stake.address);
    await stake.transferOwnership(DAO.address);
  });
});
