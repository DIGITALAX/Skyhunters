// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

interface IPool {
    function depositToPool(uint256 amount) external;
    function claimRewards() external;
    function getUserRewards(address user) external view returns (uint256);
}