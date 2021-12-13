# L7-NFT

## Dependencies
* `node`: 14.17
* `npm`: 7.19
* `truffle`: 5.3 or higher
* `solidity`: 0.8.4

### Install dependencies
```shell
$ npm install
```

## How to deploy
1. Copy your secret keys into file [.env](./.env) (remember not to commit it)
2. Compile the project
```shell
$ npx hardhat compile
```

Compile the project with force
```shell
$ npx hardhat compile --force
```

3. Deploy the project
```shell
$ npx hardhat run scripts/1_deployMultisig.js
```

To choose other network to deploy the project, modify the `NETWORK` field in the `.env`(./.env) file
