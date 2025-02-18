// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721URIStorage  {
    uint256 private _tokenIds;

    // 这里显式调用 ERC721 构造函数，并传递 NFT 名称和符号
    constructor() ERC721("MyNFTCollection", "MYNFT")  {}

    function mintNFT(address recipient, string memory tokenURI) public returns (uint256) {
        _tokenIds++;
        uint256 newItemId = _tokenIds;

        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}
