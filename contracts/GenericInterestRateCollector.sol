// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

require("./IInterestRateCollector.sol");

contract GenericInterestRateCollector is IInterestRateCollector {
  uint256 constant UINT256_MAX = ~uint256(0);

  address public _owner;

  struct Call {
    address contractAddr;
    bytes data;
  }
  Call[] public start;
  Call[] public end;

  bool public started;
  bool public ended;

  // setup has any token approvals/deposit commands
  // finish has the withdraw commands
  // doesn't take in the objects to make JS in interactions easier
  // this is catering to less-skilled developers, but that's good to maintain an accessible ecosystem
  constructor(address owner, address token, address[] memory setupAddrs, bytes[] memory setup, bytes[] memory finishAddrs, bytes[] memory finish) {
    require(setupAddrs.length == setup.length);
    require(finishAddrs.length == finish.length);

    _owner = owner;
    IERC20(token).approve(_owner, UINT256_MAX);

    start = new Call[](setup.length);
    for (uint s = 0; s < setup.length; s++) {
      start[s] = Call(setupAddrs[s], setup[s]);
    }

    end = new Call[](finish.length);
    for (uint s = 0; s < finish.length; s++) {
      end[s] = Call(finishAddrs[s], finish[s]);
    }
  }

  function start() external {
    require(msg.sender == _owner);
    require(!started);
    started = true;

    for (uint c = 0; c < start.length; c++) {
      start[c].contractAddr.call(start[c].data);
    }
  }

  function end() external override {
    require(msg.sender == _owner);
    require(!ended);
    ended = true;

    for (uint c = 0; c < end.length; c++) {
      end[c].contractAddr.call(end[c].data);
    }
  }
}
