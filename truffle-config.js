const HDWalletProvider = require('@truffle/hdwallet-provider');
const fs = require('fs');

let testnetBSCProvider, mainnetBSCProvider
try {
    const privateKey = fs.readFileSync(".secret").toString().trim();
    testnetBSCProvider = new HDWalletProvider(privateKey, `https://data-seed-prebsc-1-s1.binance.org:8545`, 0, 1)
    mainnetBSCProvider = new HDWalletProvider(privateKey, `https://bsc-dataseed.binance.org/`, 0, 1)
    // kovanInfuraProvider = new HDWalletProvider(privateKey, 'https://kovan.poa.network/')
    kovanInfuraProvider = new HDWalletProvider(privateKey, 'wss://kovan.infura.io/ws/v3/0172f183d22c4d279b7d6fe18fee2b55')
} catch (e) {
    console.log(e)
}

module.exports = {
    plugins: ["truffle-contract-size"],
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*" // Match any network id
        },
        bsc_testnet: {
            provider: testnetBSCProvider,
            network_id: 97,
            confirmations: 1,
            timeoutBlocks: 10000,
            gasLimit: 100000000
        },
        kovan: {
            provider: kovanInfuraProvider,
            gas: 5000000,
            gasPrice: 25000000000,
            network_id: 42,
            skipDryRun: true
        },
        mainnet: {
            networkCheckTimeout: 100000,
            provider: mainnetBSCProvider,
            network_id: 56,
            confirmations: 5,
            timeoutBlocks: 200,
            skipDryRun: true
        },
    },
    contracts_directory: './contracts/',
    contracts_build_directory: './abi/',
    mocha: {
        reporter: "eth-gas-reporter",
        reporterOptions: {
            currency: "USD",
            gasPrice: 2,
        },
    },
    compilers: {
        solc: {
            version: "0.8.4",
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    }
}