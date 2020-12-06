let VybeLP = artifacts.require("VybeLP");
let Vybe = artifacts.require("Vybe");
let LPtokensmock = artifacts.require("LPtokensmock");
let RewardsDistributionRecipient = artifacts.require(
  "RewardsDistributionRecipient"
);
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

    vybe = await Vybe.new();
    lp = await LPtokensmock.new();
    vybelp = await VybeLP.new(contractAddress, vybe.address, lp.address);
    for (i = 0; i < liquidityProviders.length; i++) {
      await lp.transfer(liquidityProviders[i], amounts("10"), {
        from: contractAddress,
      });
    }
  });
  it("Depositing LP tokens", async () => {
    let lpBalance = await lp.balanceOf(liquidityProviders[0]);
    await lp.approve(vybelp.address, lpBalance, {
      from: liquidityProviders[0],
    });
    await vybelp.stake(amounts("10"), { from: liquidityProviders[0] });
    await new Promise((resolve) => {
      web3.currentProvider.send(
        {
          jsonrpc: "2.0",
          method: "evm_increaseTime",
          params: [DAY * 30],
          id: null,
        },
        resolve
      );
    });
  });
});
