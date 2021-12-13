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
1. Copy your BSC secret key into file [.secret](./.secret) (remember not to commit it)
2. Compile the project
```shell
$ truffle compile
```
3. Deploy the project
```shell
$ truffle deploy --network NETWORK_NAME --compile-none
```
In this case, `NETWORK_NAME` could be one of the following: *mainnet*, *testnet*, *development*.

A BSC testnet deployment costs `~ 0.1 BNB` for two contracts: [L7ERC721LazyMint.sol](https://testnet.bscscan.com/tx/0x69a78f9571ed2808d153551e323d126441162721088ec8573812b0943a6f6a00) and [L7ERC1155LazyMint.sol](https://testnet.bscscan.com/tx/0x7649e9bd9b08d56527cd89d637c66dcdd14a9e0b955661e684126b66d683af58).
If you wish to deploy another contracts, modify the scripts in the folder [migrations](./migrations).
