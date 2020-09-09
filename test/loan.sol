// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../contracts/SafeMath.sol";
import "../contracts/Vybe.sol";
import "../contracts/VybeStake.sol";
import "../contracts/VybeLoan.sol";
import "../contracts/IVybeBorrower.sol";

contract TestVybeLoan is IVybeBorrower {
  using SafeMath for uint256;

  Vybe private _VYBE;
  VybeStake private _stake;
  VybeLoan private _loan;
  uint256 private _remaining;
  uint256 private _staked;

  function setupFlashLoan() private {
    _VYBE = new Vybe();
    _stake = new VybeStake(address(_VYBE));
    _VYBE.transferOwnership(address(_stake));
    _loan = new VybeLoan(address(_VYBE), address(_stake));
    _stake.addMelody(address(_loan));

    _staked = _VYBE.balanceOf(address(this)) / 2;
    _VYBE.approve(address(_stake), _staked);
    _stake.increaseStake(_staked);
  }

  function testFlashLoan() public {
    setupFlashLoan();
    _loan.loan(_staked);
    require(_VYBE.balanceOf(address(this)) == _remaining);
    require(_VYBE.balanceOf(address(_stake)) == _staked);
    require(_VYBE.totalSupply() == _staked.add(_remaining));
  }

  function loaned(uint256 amount, uint256 owed) override external {
    require(_VYBE.totalSupply() == _VYBE.balanceOf(address(this)));
    require(amount == _staked);
    require(owed == amount.add(amount.div(100)));
    _VYBE.approve(address(_loan), owed);
    _remaining = _VYBE.balanceOf(address(this)).sub(owed);
  }
}
