// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

interface IPool {
    function depositToPool(uint256 amount) external;

    function claimCycleRewards() external;

    function cleanCycle(uint256 cycle) external;

    function getUserCurrentCycleRewards(
        address user
    ) external view returns (uint256);

    function getUserRewardsByCycle(
        address user,
        uint256 cycle
    ) external view returns (uint256);

    function getUserCurrentCycleBalance(
        address user
    ) external view returns (uint256);

    function getUserBalanceByCycle(
        address user,
        uint256 cycle
    ) external view returns (uint256);

    function getUserClaimedByCycle(
        address user,
        uint256 cycle
    ) external view returns (bool);

    function getCycleCounter() external view returns (uint256);

    function getPoolBalance() external view returns (uint256);
}
