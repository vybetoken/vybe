// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol"

contract VybeLP is Ownable{
    Uni private _UNI;
    Vybe private _VYBE

    event LiquidityAdded(uint256 EthAmount, uint256 VybeAmount, address Provider);
    event LiquidityRemoved(uint256 EthAmount, uint256 VybeAmount, address Provider);
    event RewardsClaimed(uint256 Reward, address Provider);

  constructor(address uniswap, address vybetoken) public Ownable(msg.sender){
     // Contract for the Vybe pool on uniswap
     _UNI = Uni(uniswap);
     _VYBE = Vybe(vybetoken);
  }

  function addLiquidity(uint256 VybeAmount, uint256 EthAmount) external {
      require(amount > 0);
      
      
    emit LiquidityAdded(EthAmount, VybeAmount, msg.sender);

  }

  function removeLiqudity(uint256 amount) external {

      emit LiquidityRemoved(EthAmount, VybeAmount, msg.sender)
  }
  function claimRewards() external {

      uint256 rewards;

      emit RewardsClaimed(rewards, msg.sender);
  }
   


}
