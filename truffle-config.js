const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 9545,
      network_id: "5777",
    },
    mynetwork: {
      host: "localhost",
      port: 8545,
      network_id: "*", // match any network
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
