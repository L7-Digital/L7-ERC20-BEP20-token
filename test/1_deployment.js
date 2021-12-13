const { expect } = require("chai");

describe("Deployment", function () {
    it("Deployment should success", async function () {
        const [owner] = await ethers.getSigners();
    
        const MultisigWallet = await ethers.getContractFactory("MultisigWallet");
        const multisigWallet = await MultisigWallet.deploy();

        const contractOwner = await multisigWallet.owner();
        expect(await owner.address).to.equal(contractOwner);
    });
});