// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./IOwnershipTransferrable.sol";
import "./ReentrancyGuard.sol";
import "./Vybe.sol";
import "./IERC20.sol";

contract VybeStake is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    uint256 constant UINT256_MAX = ~uint256(0);
    uint256 constant MONTH = 30 days;
    // =============Vybe===================//
    Vybe private _VYBE;

    bool private _dated;
    bool private _migrated;
    uint256 _deployedAt;

    uint256 _totalStaked;

    mapping(address => uint256) private _staked;
    mapping(address => uint256) private _lastClaim;
    mapping(address => uint256) private _lastSignificantDecrease;
    mapping(address => uint256) private _lastDecrease;

    address private _developerFund;

    event StakeIncreased(address indexed staker, uint256 amount);
    event StakeDecreased(address indexed staker, uint256 amount);
    event Rewards(
        address indexed staker,
        uint256 mintage,
        uint256 developerFund
    );
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);

    // ========== Vybe LP =========== //
    IERC20 private _LP;
    mapping(address => uint256) private _lpStaked;
    mapping(address => uint256) private _lpLastClaim;
    uint256 _totalLpStaked;
    uint256 totalLpStakedUnrewarded;
    uint256 startOfPeriod;
    uint256 monthlyLPReward;

    event StakeIncreasedLP(address indexed lpStaker, uint256 amount);
    event StakeDecreasedLP(address indexed lpStaker, uint256 amount);
    event RewardsLP(address indexed staker, uint256 mintage);

    constructor(address vybe, address lpvybe) public Ownable(msg.sender) {
        _VYBE = Vybe(vybe);
        _developerFund = msg.sender;
        _deployedAt = block.timestamp;
        _LP = IERC20(lpvybe);
        monthlyLPReward = _VYBE.totalSupply().div(10000).mul(16);
        // resets the start date
        startOfPeriod = block.timestamp;
    }

    //===============VYBE=================//
    function upgradeDevelopmentFund(address fund) external onlyOwner {
        _developerFund = fund;
    }

    function vybe() external view returns (address) {
        return address(_VYBE);
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function migrate(address previous, address[] memory people) external {
        require(!_migrated);
        for (uint256 i = 0; i < people.length; i++) {
            uint256 staked = VybeStake(previous).staked(people[i]);
            uint256 lastClaim = VybeStake(previous).lastClaim(people[i]);
            _staked[people[i]] = staked;
            _totalStaked = _totalStaked.add(staked);
            _lastClaim[people[i]] = lastClaim;
            emit StakeIncreased(people[i], staked);
        }
        require(
            _VYBE.transferFrom(
                previous,
                address(this),
                _VYBE.balanceOf(previous)
            )
        );
        _migrated = true;
    }

    function staked(address staker) external view returns (uint256) {
        return _staked[staker];
    }

    function lastClaim(address staker) external view returns (uint256) {
        return _lastClaim[staker];
    }

    function increaseStake(uint256 amount) external {
        require(!_dated);

        require(_VYBE.transferFrom(msg.sender, address(this), amount));
        _totalStaked = _totalStaked.add(amount);
        _lastClaim[msg.sender] = block.timestamp;
        _staked[msg.sender] = _staked[msg.sender].add(amount);
        emit StakeIncreased(msg.sender, amount);
    }

    function decreaseStake(uint256 amount) external {
        _staked[msg.sender] = _staked[msg.sender].sub(amount);
        _totalStaked = _totalStaked.sub(amount);
        require(_VYBE.transfer(address(msg.sender), amount));
        uint256 cutoffPercentage = 5;
        // checks is the amount they are withdrawing in more than 5% and if it has been over a month since they withdrew less than 5%
        if (
            amount >= _staked[msg.sender] * (cutoffPercentage.div(10)) &&
            _lastDecrease[msg.sender] > MONTH
        ) {
            _lastSignificantDecrease[msg.sender] = block.timestamp;
            _lastDecrease[msg.sender] = block.timestamp;
            // If they withdraw more than 5% or withdraw less then 5% twice in 1 month then their tier is reset
        } else {
            _lastClaim[msg.sender] = block.timestamp;

            emit StakeDecreased(msg.sender, amount);
        }
    }

    // New function for calculating profit
    function _calculateStakerReward(address staker)
        public
        view
        returns (uint256)
    {
        uint256 interestPerMonth;
        uint256 claimFrom = _lastClaim[msg.sender];
        if (_lastSignificantDecrease[msg.sender] > _lastClaim[msg.sender]) {
            claimFrom = _lastSignificantDecrease[msg.sender];
        }
        uint256 stakedTime = block.timestamp.sub(claimFrom);

        // Platinum Tier
        if (stakedTime > MONTH.mul(6)) {
            // in basis points (10% APY)
            interestPerMonth = 84;
            // Gold Tier
        } else if (stakedTime > MONTH.mul(3)) {
            // in basis points (8% APY)
            interestPerMonth = 67;
            // Silver tier
        } else {
            // in basis points (5% APY)
            interestPerMonth = 42;
        }
        stakedTime = stakedTime.div(30 days);
        uint256 interest = interestPerMonth.mul(stakedTime);

        uint256 StakerReward = (_staked[staker] / 10000) * interest;

        return StakerReward;
    }

    // TODO convert to new function
    function calculateRewards(address staker) public view returns (uint256) {
        // removes the five percent for the dev fund
        return _calculateStakerReward(staker);
    }

    // new claim rewards
    function claimRewards() external noReentrancy {
        require(!_dated);
        require(_staked[msg.sender] > 0, "user has 0 staked");

        uint256 stakerReward = _calculateStakerReward(msg.sender);
        uint256 devPiece = stakerReward.div(100);

        stakerReward = stakerReward - devPiece;

        require(stakerReward > 0);
        _lastClaim[msg.sender] = block.timestamp;

        _staked[msg.sender] = _staked[msg.sender].add(stakerReward);
        _totalStaked = _totalStaked.add(stakerReward);
        _VYBE.mint(address(this), stakerReward);
        _VYBE.mint(_developerFund, devPiece);

        emit Rewards(msg.sender, stakerReward, devPiece);
    }

    function addModule(address module) external onlyOwner {
        _VYBE.approve(module, UINT256_MAX);
        emit ModuleAdded(module);
    }

    function removeModule(address module) external onlyOwner {
        _VYBE.approve(module, 0);
        emit ModuleRemoved(module);
    }

    function upgrade(address owned, address upgraded) external onlyOwner {
        _dated = true;
        IOwnershipTransferrable(owned).transferOwnership(upgraded);
    }

    // ============= Vybe LP =============== //

    function totalLpStaked() external view returns (uint256) {
        return _totalLpStaked;
    }

    function increaseLpStake(uint256 amount) external {
        require(!_dated);

        require(
            _LP.transferFrom(msg.sender, address(this), amount),
            "Can't transfer"
        );
        _totalLpStaked = _totalLpStaked.add(amount);
        _lpLastClaim[msg.sender] = block.timestamp;
        _lpStaked[msg.sender] = _lpStaked[msg.sender].add(amount);
        emit StakeIncreasedLP(msg.sender, amount);
    }

    function decreaseLpStake(uint256 amount) external {
        _lpStaked[msg.sender] = _lpStaked[msg.sender].sub(amount);
        _totalLpStaked = _totalLpStaked.sub(amount);
        require(_LP.transfer(address(msg.sender), amount));

        _lpLastClaim[msg.sender] = block.timestamp;
        emit StakeDecreasedLP(msg.sender, amount);
    }

    function lpBalanceOf(address account) public view returns (uint256) {
        return _lpStaked[account];
    }

    function timeLeftTillNextClaim() public view returns (uint256) {
        return block.timestamp.sub(startOfPeriod).sub(30 days);
    }

    function _monthlyLPReward() public view returns (uint256) {
        return monthlyLPReward;
    }

    function _totalLpStakedUnrewarded() public view returns (uint256) {
        return totalLpStakedUnrewarded;
    }

    function claimLpRewards() external noReentrancy updateLPReward() {
        require(_lpLastClaim[msg.sender] < startOfPeriod);
        // gets the amount of rewards per token
        uint256 lpRewardPerToken = monthlyLPReward.div(totalLpStakedUnrewarded);
        // get the exact reward amount
        uint256 lpReward = lpRewardPerToken.mul(_lpStaked[msg.sender]);
        // subtracts the amount been taken from the unrewarded variable
        totalLpStakedUnrewarded = totalLpStakedUnrewarded.sub(
            _lpStaked[msg.sender]
        );
        monthlyLPReward = monthlyLPReward.sub(lpReward);
        _VYBE.mint(msg.sender, lpReward);
        emit RewardsLP(msg.sender, lpReward);
    }

    modifier updateLPReward() {
        if (block.timestamp.sub(startOfPeriod) > 30 days) {
            // gets 2% of the vybe supply
            monthlyLPReward = _VYBE.totalSupply().div(10000).mul(41);
            // resets the start date
            startOfPeriod = block.timestamp;
            // reset the unrewarded LP tokens
            totalLpStakedUnrewarded = _totalLpStaked;
        }
        _;
    }
}
