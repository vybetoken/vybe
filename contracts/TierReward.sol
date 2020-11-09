pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TierReward is ERC721 {
    constructor() public ERC721("Vybe Tier Reward", "REWARD") {}

    mapping(address => string) private _type;

    uint256 counter = 0;

    function mint(address staker, uint256 tier) private {
        counter = counter + 1;
        uint256 _id = counter;

        if (tier == 1){
            _type[_id] = "silver";

        } else if (tier == 2) {
            _type[_id] = "gold";

        } else if (tier == 3) {
            _type[_id] = "platinum";

        }
        _mint(staker, _id);
    }

    function burn(uint _id) private {
        _burn(uint _id)
    }

    function getRewardType(uint256 _id) public view returns (string) {
        string type = _type[id];
        return type;
    }
}
// SPDX-License-Identifier: MIT
