const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DynamicNFT", function () {
    let DynamicNFT;
    let dynamicNFT;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    beforeEach(async function () {
        DynamicNFT = await ethers.getContractFactory("DynamicNFT");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        dynamicNFT = await DynamicNFT.deploy(1800); // Set interval to 30 minutes (1800 seconds)
        await dynamicNFT.deployed();
    });

    describe("Minting", function () {
        it("Should mint a new NFT and set the initial URI", async function () {
            await dynamicNFT.mintNFT(addr1.address);
            console.log("URI is:", await dynamicNFT.tokenURI(0));
            expect(await dynamicNFT.tokenURI(0)).to.equal(await dynamicNFT.imageURIs(0));
        });
    });

    describe("Image Rotation", function () {
        it("Should rotate the image URI after the interval", async function () {
            await dynamicNFT.mintNFT(addr1.address);
            const initialURI = await dynamicNFT.tokenURI(0);

            // Increase the EVM time by 31 minutes
            await ethers.provider.send("evm_increaseTime", [1860]);
            await ethers.provider.send("evm_mine");

            // Trigger upkeep (manually in this test case)
            console.log(await dynamicNFT.checkUpkeep([]));
            console.log(await dynamicNFT.performUpkeep([]));
            const newURI = await dynamicNFT.tokenURI(0);

            expect(newURI).to.not.equal(initialURI);
            expect(newURI).to.equal(await dynamicNFT.imageURIs(1));
        });
    });

    describe("Upkeep Mechanism", function () {
        it("Should only allow performUpkeep to execute after the interval", async function () {
            let upkeepNeeded = await dynamicNFT.checkUpkeep([]);
            expect(upkeepNeeded).to.equal(false);

            // Increase the EVM time by 31 minutes
            await ethers.provider.send("evm_increaseTime", [1860]);
            await ethers.provider.send("evm_mine");

            upkeepNeeded = await dynamicNFT.checkUpkeep([]);
            expect(upkeepNeeded).to.equal(true);
        });
    });
});
