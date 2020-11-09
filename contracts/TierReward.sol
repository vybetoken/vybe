pragma solidity ^0.6.0;

import "node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TierReward is ERC721 {
    constructor() public ERC721("Vybe Tier Reward", "REWARD") {}

    mapping(address => uint256) private _type;

    uint256 counter = 0;

    function mint(address staker, uint256 tier) private {
        counter = counter + 1;
        uint256 _id = counter;

        _type[_id] = tier;

        _mint(staker, _id);
    }

    function burn(uint256 _id) private {
        _burn(_id);
    }

    function getRewardType(uint256 _id) public view returns (string memory) {
        uint256 tier = _type[_id];

        if (tier == 1) {
            return "silver";
        } else if (tier == 2) {
            return "gold";
        } else if (tier == 3) {
            return "platinum";
        }
    }
}
// SPDX-License-Identifier: MIT
