pragma solidity ^0.7.0;

import "./ERC721.sol";

contract TierReward is ERC721 {
    constructor() public ERC721("VybeReward", "REWARD") {}
}
