const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
  networks: {
    mainnet: {
      provider: () => {
        return new HDWalletProvider("KEY", "wss://mainnet.infura.io/ws/v3/");
      },
      network_id: "*",
      gas: 2500000,
      gasPrice: 120000000000,
      confirmations: 1,
      timeoutBlocks: 500,
      skipDryRun: true,
    },
  },
  mocha: {},
  compilers: {
    solc: {
      version: "^0.6.0",
      settings: {
        optimizer: {
          enabled: true,
          runs: 250,
        },
      },
    },
  },
};
