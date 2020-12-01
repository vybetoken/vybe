// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IOwnershipTransferrable.sol";

contract VybeLP is Ownable{
    Uni private _UNI;
    Vybe private _VYBE;
    Weth private _WETH;

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
      IWETH(WETH).deposit{value: EthAmount}()
      uint256 maxTime = block.timestamp + 30;
      require(IUniswapV2Router01(_UNI).addLiquidity(_WETH,_VYBE,ETHAmount,VybeAmount,ETHAmount,VybeAmount,msg.sender,maxTime));
      _LPLastClaim[msg.sender] = block.timestamp;
      // This is temp, really we need to check the exchange rate so find give them a fair value.
      _LPbalances[msg.sender] = VybeAmount;
      
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
