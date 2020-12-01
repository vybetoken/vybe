// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IOwnershipTransferrable.sol";

contract VybeLP is Ownable{
    Uni private _UNI;
    Vybe private _VYBE

    event LiquidityAdded(uint256 EthAmount, uint256 VybeAmount, address Provider);
    event LiquidityRemoved(uint256 EthAmount, uint256 VybeAmount, address Provider);
    event RewardsClaimed(uint256 Reward, address Provider);

    mapping (address => uint256) _LPbalances;
    mapping (address => uint256) _LPLastClaim;

  constructor(address uniswapPool, address vybetoken, address WethContract) public Ownable(msg.sender){
     // Contract for the Vybe pool on uniswap
     _UNI = Uni(uniswapPool);
     _VYBE = Vybe(vybetoken);
     _WETH = Weth(WethContract)
  }

  function addLiquidity(uint256 EthAmount, uint256 VybeAmount) external {
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
