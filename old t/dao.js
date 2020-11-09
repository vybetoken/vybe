const BigNumber = require("bignumber.js");

const VybeToken = artifacts.require("Vybe");
const VybeStake = artifacts.require("VybeStake");
const VybeLoan = artifacts.require("VybeLoan");
const VybeDAO = artifacts.require("VybeDAO");

const DAY = 60 * 60 * 24;

// Uses new instead of deployed due to problems with the clean room env truffle should provide

contract("DAO test", async (accounts) => {
  it("Should support fund proposals", async () => {
    let VYBE = await VybeToken.new();
    let stake = await VybeStake.new(VYBE.address);
    await VYBE.transferOwnership(stake.address);
    let dao = await VybeDAO.new(stake.address);
    await stake.upgradeDevelopmentFund(dao.address);
    await stake.transferOwnership(dao.address);

    // Stake so we have voting weight/to init the dev fund
    await VYBE.approve(stake.address, 1);
    await stake.increaseStake(1);
    await (new Promise((resolve) => {
      web3.currentProvider.send({
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [29 * DAY],
        id: null
      }, resolve);
    }));

    // Claim the rewards so the dev fund gets 5%.
    await stake.claimRewards();
    // Advance the clock a second to make sure lastClaim is different
    await (new Promise((resolve) => {
      web3.currentProvider.send({
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [1],
        id: null
      }, resolve);
    }));

    let devFund = new BigNumber(await VYBE.balanceOf.call(dao.address));
    assert(devFund.gt(new BigNumber(0)));

    // Create a proposal for funds.
    await VYBE.approve(dao.address, new BigNumber("10e18"));
    let id = (await dao.proposeFund(accounts[0], devFund, "Info for Fund")).logs[0].args.proposal;
    let balance = new BigNumber(await VYBE.balanceOf.call(accounts[0]));
    await dao.completeProposal(id, [accounts[0]]);

    // The DAO should now only have the proposal fee left
    assert((new BigNumber(await VYBE.balanceOf.call(dao.address))).isEqualTo(new BigNumber("10e18")));
    assert((new BigNumber(await VYBE.balanceOf.call(accounts[0]))).isEqualTo(balance.plus(devFund)));
  });

  it("Should support removing and adding melodies", async () => {
    let VYBE = await VybeToken.new();
    let stake = await VybeStake.new(VYBE.address);
    let loan = await VybeLoan.new(VYBE.address, stake.address);
    let dao = await VybeDAO.new(stake.address);
    await stake.transferOwnership(dao.address);

    // Stake so we have voting weight
    await VYBE.approve(stake.address, 1);
    await stake.increaseStake(1);
    await (new Promise((resolve) => {
      web3.currentProvider.send({
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [1],
        id: null
      }, resolve);
    }));

    // Create a proposal to add it
    await VYBE.approve(dao.address, new BigNumber("10e18"));
    let id = (await dao.proposeMelodyAddition(loan.address, "Info for Addition")).logs[0].args.proposal;
    await dao.completeProposal(id, [accounts[0]]);
    assert.equal(
      (await VYBE.allowance.call(stake.address, loan.address)).toString(),
      "115792089237316195423570985008687907853269984665640564039457584007913129639935"
    );

    // Create a proposal to remove the flash loans contract
    await VYBE.approve(dao.address, new BigNumber("10e18"));
    id = (await dao.proposeMelodyRemoval(loan.address, "Info for Removal")).logs[0].args.proposal;
    await dao.completeProposal(id, [accounts[0]]);
    assert.equal((await VYBE.allowance.call(stake.address, loan.address)).toString(), "0");
  });

  it("Should support upgrading the staking contract", async () => {
    let VYBE = await VybeToken.new();
    let stake = await VybeStake.new(VYBE.address);
    await VYBE.transferOwnership(stake.address);
    let loan = await VybeLoan.new(VYBE.address, stake.address);
    let dao = await VybeDAO.new(stake.address);
    await stake.transferOwnership(dao.address);

    assert.equal(await VYBE.owner.call(), stake.address);
    assert.equal(await loan.owner.call(), stake.address);
    assert.equal(await dao.stake(), stake.address);

    let newStake = await VybeStake.new(VYBE.address);
    assert(stake.address !== newStake.address);

    await VYBE.approve(stake.address, 1);
    await stake.increaseStake(1);
    await (new Promise((resolve) => {
      web3.currentProvider.send({
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [1],
        id: null
      }, resolve);
    }));

    await VYBE.approve(dao.address, new BigNumber("10e18"));
    let id = (
      await dao.proposeStakeUpgrade(
        newStake.address,
        [VYBE.address, loan.address],
        "Info for Stake Upgrade"
      )
    ).logs[0].args.proposal;
    await dao.completeProposal(id, [accounts[0]]);

    assert.equal(await VYBE.owner.call(), newStake.address);
    assert.equal(await loan.owner.call(), newStake.address);
    assert.equal(await dao.stake.call(), newStake.address);

    assert(
      (new BigNumber(
        await VYBE.allowance.call(stake.address, newStake.address))
      ).isGreaterThan(
        await VYBE.balanceOf.call(stake.address)
      )
    );
  });

  it("Should support upgrading itself", async () => {
    let VYBE = await VybeToken.new();
    let stake = await VybeStake.new(VYBE.address);
    let dao = await VybeDAO.new(stake.address);
    await stake.transferOwnership(dao.address);
    assert(!(await dao.upgraded.call()));

    let newDAO = await VybeDAO.new(stake.address);

    await VYBE.approve(stake.address, 1);
    await stake.increaseStake(1);
    await (new Promise((resolve) => {
      web3.currentProvider.send({
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [1],
        id: null
      }, resolve);
    }));

    await VYBE.approve(dao.address, new BigNumber("10e18"));
    let id = (await dao.proposeDAOUpgrade(newDAO.address, "Info for DAO Upgrade")).logs[0].args.proposal;
    await dao.completeProposal(id, [accounts[0]]);

    // Verify the DAO successfully upgraded
    assert(await dao.upgraded.call());
    assert.equal(await dao.upgrade.call(), newDAO.address);
    assert.equal(await stake.owner.call(), newDAO.address);
    // Verify it forwarded its funds
    assert((new BigNumber("0")).isEqualTo(await VYBE.balanceOf.call(dao.address)));
    assert((new BigNumber("10e18")).isEqualTo(await VYBE.balanceOf.call(newDAO.address)));

    // Verify it's not usable
    await VYBE.approve(dao.address, new BigNumber("10e18"));
    let failed = false;
    try {
      await dao.proposeDAOUpgrade(newDAO.address, "Info for DAO Upgrade after already upgrading");
    } catch(e) {
      failed = true;
    }
    assert(failed);
  });
});
