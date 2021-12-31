require('dotenv').config()

require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");

const fs = require("fs")

function getSortedFiles(dependenciesGraph) {
    const tsort = require("tsort")
    const graph = tsort()

    const filesMap = {}
    const resolvedFiles = dependenciesGraph.getResolvedFiles()
    resolvedFiles.forEach((f) => (filesMap[f.sourceName] = f))

    for (const [from, deps] of dependenciesGraph.entries()) {
        for (const to of deps) {
            graph.add(to.sourceName, from.sourceName)
        }
    }

    const topologicalSortedNames = graph.sort()

    // If an entry has no dependency it won't be included in the graph, so we
    // add them and then dedup the array
    const withEntries = topologicalSortedNames.concat(resolvedFiles.map((f) => f.sourceName))

    const sortedNames = [...new Set(withEntries)]
    return sortedNames.map((n) => filesMap[n])
}

function getFileWithoutImports(resolvedFile) {
    const IMPORT_SOLIDITY_REGEX = /^\s*import(\s+)[\s\S]*?;\s*$/gm

    return resolvedFile.content.rawContent.replace(IMPORT_SOLIDITY_REGEX, "").trim()
}

subtask("flat:get-flattened-sources", "Returns all contracts and their dependencies flattened")
    .addOptionalParam("files", undefined, undefined, types.any)
    .addOptionalParam("output", undefined, undefined, types.string)
    .setAction(async ({ files, output }, { run }) => {
        const dependencyGraph = await run("flat:get-dependency-graph", { files })
        console.log(dependencyGraph)

        let flattened = ""

        if (dependencyGraph.getResolvedFiles().length === 0) {
            return flattened
        }

        const sortedFiles = getSortedFiles(dependencyGraph)

        let isFirst = true
        for (const file of sortedFiles) {
            if (!isFirst) {
                flattened += "\n"
            }
            flattened += `// File ${file.getVersionedName()}\n`
            flattened += `${getFileWithoutImports(file)}\n`

            isFirst = false
        }

        // Remove every line started with "// SPDX-License-Identifier:"
        flattened = flattened.replace(/SPDX-License-Identifier:/gm, "License-Identifier:")

        flattened = `// SPDX-License-Identifier: MIXED\n\n${flattened}`

        // Remove every line started with "pragma experimental ABIEncoderV2;" except the first one
        flattened = flattened.replace(/pragma experimental ABIEncoderV2;\n/gm, ((i) => (m) => (!i++ ? m : ""))(0))

        flattened = flattened.trim()
        if (output) {
            console.log("Writing to", output)
            fs.writeFileSync(output, flattened)
            return ""
        }
        return flattened
    })

subtask("flat:get-dependency-graph")
    .addOptionalParam("files", undefined, undefined, types.any)
    .setAction(async ({ files }, { run }) => {
        const sourcePaths = files === undefined ? await run("compile:solidity:get-source-paths") : files.map((f) => fs.realpathSync(f))

        const sourceNames = await run("compile:solidity:get-source-names", {
            sourcePaths,
        })

        const dependencyGraph = await run("compile:solidity:get-dependency-graph", { sourceNames })

        return dependencyGraph
    })

task("flat", "Flattens and prints contracts and their dependencies")
    .addOptionalVariadicPositionalParam("files", "The files to flatten", undefined, types.inputFile)
    .addOptionalParam("output", "Specify the output file", undefined, types.string)
    .setAction(async ({ files, output }, { run }) => {
        console.log(
            await run("flat:get-flattened-sources", {
                files,
                output,
            })
        )
    })

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
        version: "0.8.9",
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