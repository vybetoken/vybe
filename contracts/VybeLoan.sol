// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Vybe.sol";
import "./IVybeBorrower.sol";

contract VybeLoan is ReentrancyGuard, Ownable {
  using SafeMath for uint256;

  Vybe private _VYBE;
  uint256 internal _feeDivisor = 100;

  event Loaned(uint256 amount, uint256 profit);

  constructor(address VYBE, address vybeStake) Ownable(vybeStake) {
    _VYBE = Vybe(VYBE);
  }

  // loan out VYBE from the staked funds
  function loan(uint256 amount) external noReentrancy {
    // set a profit of 1%
    uint256 profit = amount.div(_feeDivisor);
    uint256 owed = amount.add(profit);
    // transfer the funds
    require(_VYBE.transferFrom(owner(), msg.sender, amount));

    // call the loaned function
    IVybeBorrower(msg.sender).loaned(amount, owed);

    // transfer back to the staking pool
    require(_VYBE.transferFrom(msg.sender, owner(), amount));
    // take the profit
    require(_VYBE.transferFrom(msg.sender, address(this), profit));
    // burn it, distributing its value to the ecosystem
    require(_VYBE.burn(profit));

    emit Loaned(amount, profit);
  }
}
