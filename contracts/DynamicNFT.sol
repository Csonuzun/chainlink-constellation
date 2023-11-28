// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract DynamicNFT is ERC721URIStorage, AutomationCompatibleInterface {
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    uint256 public tokenCounter;
    string[] public imageURIs = [
    "https://ipfs.io/ipfs/Qme8R3TMZZbt3PgZqKNskZWdfYwKoUP3TUkHKe7AEtrBMk?filename=Ekran%20g%C3%B6r%C3%BCnt%C3%BCs%C3%BC%202023-11-28%20191654.png",
    "https://ipfs.io/ipfs/QmNXNfik2Me4fqFHcBsJWiVdvSYYNkbrPKNwr7xjKfju1H?filename=Ekran%20g%C3%B6r%C3%BCnt%C3%BCs%C3%BC%202023-08-25%20054930.png",
    "https://ipfs.io/ipfs/QmXud3axJVaFMU95YbAWe2ib3JU6v5CUBNgdB654B6wiUR?filename=Glass%2008.png"
    ];

    constructor(uint256 updateInterval) ERC721("DynamicNFT", "dNFT") {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        tokenCounter = 0;

    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
    public
    view
    override
    returns (
        bool upkeepNeeded,
        bytes memory /* performData */
    )
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }
    function changeImageURI(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not owner nor approved");
        if ()
        _setTokenURI(tokenId, newURI);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        require(upkeepNeeded, "Time interval not met");
        lastTimeStamp = block.timestamp;

// Rotate the image for each NFT
        for (uint256 i = 0; i < tokenCounter; i++) {
            uint256 currentImageIndex = (block.timestamp / interval) % imageURIs.length;
            _setTokenURI(i, imageURIs[currentImageIndex]);
        }
    }

    function mintNFT(address recipient) public returns (uint256) {
        uint256 newItemId = tokenCounter;
        _safeMint(recipient, newItemId);

// Set initial image URI
        uint256 currentImageIndex = (block.timestamp / interval) % imageURIs.length;
        _setTokenURI(newItemId, imageURIs[currentImageIndex]);

        tokenCounter += 1;
        return newItemId;
    }
}
