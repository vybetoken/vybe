// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./Vybe.sol";
import "./VybeLoan.sol";
import "./IVybeBorrower.sol";

contract VybeFlashLoan is IVybeBorrower {
  using SafeMath for uint256;

    address deployedVybeContract = address(0x3A1c1d1c06bE03cDDC4d3332F7C20e1B37c97CE9);
    address deployedVybeLoanContract = address(0x382EE41496E0Bb88F046F2C0D1Cf894F8D272BD5);

    Vybe private _VYBE;
    VybeLoan private _loan;

    // update amount value with your loan amount
    uint256 private _loanAmount = 100;

    constructor() {
        // create vybe instance
        _VYBE = Vybe(deployedVybeContract);
        // create loan instance
        _loan = VybeLoan(deployedVybeLoanContract);
    }

    function executeLoan() external {
        // Trigger loan
        _loan.loan(_testLoanAmount);
    }

    function loaned(uint256 amount, uint256 owed) override external {
        // Add custom logic here to generate >1% profit

        // approve loan
        _VYBE.approve(address(_loan), owed);
    }
}
