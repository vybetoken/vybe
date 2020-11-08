pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TierReward is ERC721 {
    constructor(address vybe) public ERC721("VybeReward", "REWARD") {}

    function mint(string memory _type) public {}
}
// SPDX-License-Identifier: MIT
