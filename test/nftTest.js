const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT Contract", function () {
    let MyNFT;
    let myNFT;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    beforeEach(async function () {
        MyNFT = await ethers.getContractFactory("NFT");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        myNFT = await MyNFT.deploy();
        await myNFT.deployed();
    });

    describe("Minting NFT", function () {
        it("Should mint and return correct metadata", async function () {
            const tokenURI = "https://ipfs.io/ipfs/QmXud3axJVaFMU95YbAWe2ib3JU6v5CUBNgdB654B6wiUR?filename=Glass%2008.png";

            // Mint the NFT
            await myNFT.connect(owner).mintNFT(owner.address, tokenURI);

            // Get the URI of the minted NFT
            expect(await myNFT.tokenURI(1)).to.equal(tokenURI);
        });
    });
});
