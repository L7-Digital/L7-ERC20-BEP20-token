require('dotenv').config()

require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");

const config = {
    network: process.env.NETWORK,
    infura_api_key: process.env.INFURA_API_KEY,
    private_key: {
        rinkeby: process.env.PRIVATE_KEY__RINKEBY == '' ? process.env.DEFAULT_PRIVATE_KEY : process.env.PRIVATE_KEY__RINKEBY,
        kovan: process.env.PRIVATE_KEY__KOVAN == '' ? process.env.DEFAULT_PRIVATE_KEY : process.env.PRIVATE_KEY__KOVAN,
        bsc_testnet: process.env.PRIVATE_KEY__BSC_TESTNET == '' ? process.env.DEFAULT_PRIVATE_KEY : process.env.PRIVATE_KEY__BSC_TESTNET,
        bsc_mainnet: process.env.PRIVATE_KEY__BSC_MAINNET == '' ? process.env.DEFAULT_PRIVATE_KEY : process.env.PRIVATE_KEY__BSC_MAINNET
    },
    mnemonic: {
        rinkeby: process.env.MNEMONIC__RINKEBY,
        kovan: process.env.MNEMONIC__KOVAN,
        bsc_testnet: process.env.MNEMONIC__BSC_TESTNET,
        bsc_mainnet: process.env.MNEMONIC__BSC_MAINNET,
    },
    report_gas: process.env.REPORT_GAS
}

module.exports = {
    solidity: {
        version: "0.8.7",
        settings: {
            optimizer: {
                enabled: true,
                runs: 100,
            },
        },
    },
    gasReporter: {
        enabled: (config.report_gas) ? true : false
    },
    defaultNetwork: config.network,
    networks: {
        hardhat: {},
        ganache: {
            url: "http://127.0.0.1:7545",
            accounts: {
                mnemonic: "symptom bean awful husband dice accident crush tank sun notice club creek",
            },
        },
        rinkeby: {
            url: `wss://rinkeby.infura.io/ws/v3/${config.infura_api_key}`,
            apiKey: config.infura_api_key,
            accounts: {
                mnemonic: config.mnemonic.rinkeby
            }
        },    
        kovan: {
            url: `wss://kovan.infura.io/ws/v3/${config.infura_api_key}`,
            accounts: [ config.private_key.kovan ]
        },
        bsc_testnet: {
            url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
            accounts: [ config.private_key.bsc_testnet ]
        },

        bsc_mainnet: {
            url: `https://bsc-dataseed.binance.org/`,
            accounts: [ config.private_key.bsc_mainnet ]
        },
    }
}