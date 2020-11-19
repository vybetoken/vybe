// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IInterestRateCollector {
  function manager() external view returns (address);
  function token() external view returns (address);
  function start() external;
  function end() external;
}
