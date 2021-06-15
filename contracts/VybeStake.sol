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
    // =============Vybe===================/
    Vybe private _VYBE;

    bool private _dated;
    bool private _migrated;
    uint256 _deployedAt;

    uint256 _totalStaked;

    mapping(address => uint256) private _staked;
    mapping(address => uint256) private _lastClaim;
    mapping(address => uint256) private _lastDecrease;
    mapping(address => bool) private _migratedFunds;

    address private _developerFund;
    address private _oldStakingContract;

    event StakeIncreased(address indexed staker, uint256 amount);
    event StakeDecreased(address indexed staker, uint256 amount);
    event Rewards(
        address indexed staker,
        uint256 mintage,
        uint256 developerFund
    );
    event MelodyAdded(address indexed melody);
    event MelodyRemoved(address indexed melody);

    constructor(
        address vybe,
        address oldStakingContract
    ) public Ownable(msg.sender) {
        _VYBE = Vybe(vybe);
        _developerFund = msg.sender;
        _deployedAt = block.timestamp;
        _oldStakingContract = oldStakingContract;
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

    function previousStake() external view returns (address) {
        return address(_oldStakingContract);
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function migrate() external {
        require(!_migratedFunds[msg.sender]);
        uint256 staked = VybeStake(_oldStakingContract).staked(msg.sender);
        uint256 lastClaim = VybeStake(_oldStakingContract).lastClaim(
            msg.sender
        );
        require(lastClaim < _deployedAt);
        _staked[msg.sender] = staked;
        _lastClaim[msg.sender] = lastClaim;
        _migratedFunds[msg.sender] = true;
        emit StakeIncreased(msg.sender, staked);
    }

    function migrateFunds(uint256 amount) external {
        require(!_migrated, "migrate is true");
        require(
            _VYBE.transferFrom(_oldStakingContract, address(this), amount),
            "transaction failed"
        );
        _totalStaked = _totalStaked.add(amount);
        _migrated = true;
    }

    function migratedFunds(address staker) external view returns (bool) {
        return _migratedFunds[staker];
    }

    function migrated() external view returns (bool) {
        return _migrated;
    }

    function staked(address staker) external view returns (uint256) {
        return _staked[staker];
    }

    function lastClaim(address staker) external view returns (uint256) {
        return _lastClaim[staker];
    }

    function rewardAvailable(address staker) external view returns (bool) {
        if (block.timestamp.sub(_lastClaim[staker]) >= 24 hours) {
            return false;
        } else {
            return true;
        }
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
            amount <= _staked[msg.sender].div(20) &&
            _lastDecrease[msg.sender] < block.timestamp - MONTH
        ) {
            _lastDecrease[msg.sender] = block.timestamp;
        // If they withdraw more than 5% or withdraw less then 5% twice in 1 month then their tier is reset
        } else {
            _lastClaim[msg.sender] = block.timestamp;
        }
        emit StakeDecreased(msg.sender, amount);
    }

    // New function for calculating profit
    function _calculateStakerReward(address staker)
        private
        view
        returns (uint256)
    {
        uint256 interestPerMonth;
        uint256 StakerReward;
        uint256 stakedTime = block.timestamp.sub(_lastClaim[staker]);

        // Platinum Tier
        if (stakedTime > MONTH.mul(6)) {
            // in basis points (10% APY)
            interestPerMonth = 28;
            // Gold Tier
        } else if (stakedTime > MONTH.mul(3)) {
            // in basis points (8% APY)
            interestPerMonth = 22;
            // Silver tier
        } else {
            // in basis points (5% APY)
            interestPerMonth = 14;
        }
        if (stakedTime >= 24 hours) {
            stakedTime = stakedTime.div(24 hours);
            uint256 interest = interestPerMonth.mul(stakedTime);

            StakerReward = _staked[staker].div(1e5).mul(interest);
        }

        return StakerReward;
    }

    function calculateRewards(address staker) public view returns (uint256) {
        return _calculateStakerReward(staker);
    }

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

    function addMelody(address melody) external onlyOwner {
        _VYBE.approve(melody, UINT256_MAX);
        emit MelodyAdded(melody);
    }

    function removeMelody(address melody) external onlyOwner {
        _VYBE.approve(melody, 0);
        emit MelodyRemoved(melody);
    }

    function upgrade(address owned, address upgraded) external onlyOwner {
        _dated = true;
        IOwnershipTransferrable(owned).transferOwnership(upgraded);
    }
}
