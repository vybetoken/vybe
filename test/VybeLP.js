let VybeLP = artifacts.require("VybeLP");
let Vybe = artifacts.require("Vybe");
let LPtokensmock = artifacts.require("LPtokensmock");
const BigNumber = require("bignumber.js");

function amounts(n) {
  return new BigNumber(`${n}e18`);
}

contract("UniswapLP rewards", (accounts) => {
  let uniswap, vybe;
  const contractAddress = accounts[0];
  const liquidityProviders = [accounts[1], accounts[2], accounts[3]];
  before(async () => {
    // deploys contract
    vybelp = await VybeLP.new();
    vybe = await Vybe.new();
    lp = await LPtokensmock.new();
    for (i = 0; i < liquidityProviders.length - 1; i++) {
      await lp.transfer(liquidityProviders[i], amounts("10"), {
        from: contractAddress,
      });
    }
  });
  it("Balance of the farm should have 20000 Opt", async () => {
    let balance = await opt.balanceOf(farm.address);
    assert.equal(balance.toString(), web3.utils.toWei("20000"));
  });
  it("Deposit Dai and withdraw Dai from DaiFarm", async () => {
    let daiBalance = await dai.balanceOf(investor[0]);
    await dai.approve(farm.address, daiBalance, { from: investor[0] });
    await farm.addLiquidity(daiBalance, { from: investor[0] });
    let balance = await farm.getBalance({ from: investor[0] });
    await farm.removeLiquidity("0", { from: investor[0] });
  });
});
