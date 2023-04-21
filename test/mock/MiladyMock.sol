// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract MiladyMock is ERC721 {
    constructor() ERC721("Milady", "MLDY") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}
