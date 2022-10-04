require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  defaultNetwork: "matic",
  networks: {
    hardhat: {
    },
    matic: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/OWb3U7rJFrgVFsYXrGu-h0LId9ki14_V",
      accounts: [process.env.PRIVATE_KEY]
    }
  },
};
