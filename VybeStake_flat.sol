// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/IOwnershipTransferrable.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IOwnershipTransferrable {
    function transferOwnership(address owner) external;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// File: contracts/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract ReentrancyGuard {
    bool private _entered;

    modifier noReentrancy() {
        require(!_entered);
        _entered = true;
        _;
        _entered = false;
    }
}

// File: contracts/Ownable.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


abstract contract Ownable is IOwnershipTransferrable {
    address private _owner;

    constructor(address owner) public {
        _owner = owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Vybe.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;



contract Vybe is Ownable {
    using SafeMath for uint256;

    uint256 constant UINT256_MAX = ~uint256(0);

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() public Ownable(msg.sender) {
        _name = "Vybe";
        _symbol = "VYBE";
        _decimals = 18;

        _totalSupply = 2000000 * 1e18;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[msg.sender][sender] != UINT256_MAX) {
            _approve(
                sender,
                msg.sender,
                _allowances[sender][msg.sender].sub(amount)
            );
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0));
        require(recipient != address(0));

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) external returns (bool) {
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/VybeStake.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;






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

    function migrate(
        address previous,
        address[] memory people,
        uint256[] memory lastClaims
    ) external {
        require(!_migrated);
        require(people.length == lastClaims.length);
        for (uint256 i = 0; i < people.length; i++) {
            uint256 staked = VybeStake(previous).staked(people[i]);
            _staked[people[i]] = staked;
            _totalStaked = _totalStaked.add(staked);
            _lastClaim[people[i]] = lastClaims[i];
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
            monthlyLPReward = _VYBE.totalSupply().div(10000).mul(16);
            // resets the start date
            startOfPeriod = block.timestamp;
            // reset the unrewarded LP tokens
            totalLpStakedUnrewarded = _totalLpStaked;
        }
        _;
    }
}
