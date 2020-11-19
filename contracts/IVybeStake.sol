// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IOwnershipTransferrable.sol";

interface IVybeStake is IOwnershipTransferrable {
    event StakeIncreased(address indexed staker, uint256 amount);
    event StakeDecreased(address indexed staker, uint256 amount);
    event Rewards(
        address indexed staker,
        uint256 mintage,
        uint256 developerFund
    );
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);

    function vybe() external returns (address);

    function totalStaked() external returns (uint256);

    function staked(address staker) external returns (uint256);

    function lastClaim(address staker) external returns (uint256);

    function addModule(address module) external;

    function removeModule(address module) external;

    function upgrade(address owned, address upgraded) external;
}
