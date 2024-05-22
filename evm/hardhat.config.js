require('hardhat-gas-reporter')
require('hardhat-spdx-license-identifier')
require('hardhat-deploy')
require('hardhat-abi-exporter')
require('@nomiclabs/hardhat-ethers')
require('dotenv/config')
require('@nomiclabs/hardhat-etherscan')
require('@nomiclabs/hardhat-waffle')
require('solidity-coverage')
require('./tasks')

const { PRIVATE_KEY, INFURA_KEY} = process.env;
let accounts = [];
accounts.push(PRIVATE_KEY);


module.exports = {
  defaultNetwork: 'hardhat',
  abiExporter: {
    path: './abi',
    clear: false,
    flat: true
  },
  networks: {
    hardhat: {
      forking: {
        enabled: false,
        url: `https://data-seed-prebsc-1-s1.binance.org:8545`
        //url: `https://bsc-dataseed.eme-node.com`,
        //url: `https://bsc-dataseed2.defibit.io/`,
      },
      allowUnlimitedContractSize: true,
      live: true,
      saveDeployments: false,
      tags: ['local'],
      timeout: 2000000,
      chainId:212
    },
    Map: {
      url: `https://rpc.maplabs.io/`,
      chainId : 22776,
      accounts: accounts
    },
    Makalu: {
      url: `https://testnet-rpc.maplabs.io/`,
      chainId : 212,
      accounts: accounts
    },
    Matic: {
      url: `https://rpc-mainnet.maticvigil.com`,
      chainId : 137,
      accounts: accounts
    },
    MaticTest: {
      url: `https://rpc-mumbai.maticvigil.com/`,
      chainId : 80001,
      accounts: accounts
    },
    Bsc: {
      url: `https://bsc-dataseed1.binance.org/`,
      chainId : 56,
      accounts: accounts
    },
    BscTest: {
      url: `https://data-seed-prebsc-2-s2.binance.org:8545`,
      chainId : 97,
      accounts: accounts
     // gasPrice: 11 * 1000000000
    },
    Eth: {
      url: `https://mainnet.infura.io/v3/` + INFURA_KEY,
      chainId : 1,
      accounts: accounts
    },
    Sepolia: {
      url: `https://1rpc.io/sepolia`,
      chainId: 11155111,
      accounts: accounts
    },
    Klay: {
      url: `https://public-node-api.klaytnapi.com/v1/cypress`,
      chainId : 8217,
      accounts: accounts
    },
    KlayTest: {
      url: `https://api.baobab.klaytn.net:8651/`,
      chainId : 1001,
      accounts: accounts
    },

    Conflux: {
      url: `https://evm.confluxrpc.com`,
      chainId : 1030,
      accounts: accounts
    },
    ConfluxTest: {
      url: `https://evmtestnet.confluxrpc.com`,
      chainId : 71,
      accounts: accounts
    },

    Avax: {
      url: `https://rpc.ankr.com/avalanche`,
      chainId : 43114,
      accounts: accounts
    },
    Filecoin: {
      url: `https://rpc.ankr.com/filecoin`,
      chainId : 314,
      accounts: accounts
    },

    Arbitrum: {
      url: `https://1rpc.io/arb`,
      chainId : 42161,
      accounts: accounts
    },
    ArbitrumSepolia: {
      chainId: 421614,
      url: `https://arbitrum-sepolia.blockpi.network/v1/rpc/public`,
      accounts: accounts
    },

    zkSync: {
      url: `https://mainnet.era.zksync.io`,
      chainId : 324,
      zksync: true,
      ethNetwork: 'Eth',
      accounts: accounts
    },
    Optimism: {
      url: `https://1rpc.io/op`,
      chainId : 10,
      accounts: accounts
    },
    Base: {
      url: `https://mainnet.base.org`,
      chainId : 8453,
      accounts: accounts
    },
    zkEvm: {
      url: `https://zkevm-rpc.com`,
      chainId : 1101,
      accounts: accounts
    },
    Linea: {
      url: `https://rpc.linea.build`,
      chainId : 59144,
      accounts: accounts
    },
    Scroll: {
      url: `https://rpc.scroll.io`,
      chainId : 534352,
      accounts: accounts
    },
    Boba: {
      url: `https://mainnet.boba.network`,
      chainId : 288,
      accounts: accounts
    },
    Metis: {
      url: `https://andromeda.metis.io/?owner=1088`,
      chainId : 1088,
      accounts: accounts
    },
    Mantle: {
      url: `https://rpc.mantle.xyz`,
      chainId : 5000,
      accounts: accounts
    },
    DodoTest: {
      url: `https://dodochain-testnet.alt.technology`,
      chainId : 53457,
      accounts: accounts
    },
  },
  solidity: {
    compilers: [
      {
        version: '0.8.7',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: '0.4.22',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },
  spdxLicenseIdentifier: {
    overwrite: true,
    runOnCompile: false
  },
  mocha: {
    timeout: 2000000
  },
  etherscan: {
    apiKey: process.env.INFURA_KEY
  }
}
