const dotenv = require("dotenv");

dotenv.config();

const CONTRACT_NAME = process.env.NEAR_LOCAL_CONTRACT_NAME || "app.test.near";

const localConfig = {
  nodeUrl: process.env.NEAR_NODE_URL || "http://127.0.0.1:61266",
  keyPath: process.env.NEAR_CLI_LOCALNET_KEY_PATH,
  walletUrl: process.env.NEAR_WALLET_URL || "http://127.0.0.1:61372",
  contractName: CONTRACT_NAME,
  helperAccount: process.env.NEAR_HELPER_ACCOUNT || "test.near",
  helperUrl: process.env.NEAR_HELPER_URL || "http://127.0.0.1:55268",
};

function getConfig(env) {
  switch (env) {
    case "production":
    case "mainnet":
      return {
        networkId: "mainnet",
        nodeUrl: "https://rpc.mainnet.near.org",
        contractName: CONTRACT_NAME,
        walletUrl: "https://wallet.near.org",
        helperUrl: "https://helper.mainnet.near.org",
      };
    case "development":
    case "testnet":
      return {
        networkId: "testnet",
        nodeUrl: "https://rpc.testnet.near.org",
        contractName: "app.evanpiro.testnet",
        walletUrl: "https://wallet.testnet.near.org",
        helperUrl: "https://helper.testnet.near.org",
      };
    case "betanet":
      return {
        networkId: "betanet",
        nodeUrl: "https://rpc.betanet.near.org",
        contractName: CONTRACT_NAME,
        walletUrl: "https://wallet.betanet.near.org",
        helperUrl: "https://helper.betanet.near.org",
      };
    case "local":
      return {
        networkId: "local",
        ...localConfig,
        masterAccount: "test.near",
      };
    case "ci":
      return {
        networkId: "shared-test",
        nodeUrl: "https://rpc.ci-testnet.near.org",
        contractName: CONTRACT_NAME,
        masterAccount: "test.near",
      };
    case "ci-betanet":
      return {
        networkId: "shared-test-staging",
        nodeUrl: "https://rpc.ci-betanet.near.org",
        contractName: CONTRACT_NAME,
        masterAccount: "test.near",
      };
    default:
      throw Error(
        `Unconfigured environment '${env}'. Can be configured in src/config.js.`
      );
  }
}

module.exports = getConfig;
