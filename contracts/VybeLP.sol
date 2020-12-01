// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol"

contract VybeLP is Ownable{
    Uni private _uni;
    Vybe private _vybe

  constructor(address uniswap) public Ownable(msg.sender){
     // Contract for the Vybe pool on uniswap
     _uni = Uni(uniswap);


  }
   


}
