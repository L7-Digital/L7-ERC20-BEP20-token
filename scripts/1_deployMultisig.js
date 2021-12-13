const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const MultisigWallet = await hre.ethers.getContractFactory("MultisigWallet");
  const multisigWallet = await MultisigWallet.deploy();
  
  console.log("Network:", hre.network.name);
  console.log("MultisigWallet deployed to:", multisigWallet.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
