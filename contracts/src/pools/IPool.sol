// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

interface IPool {
    function claimCycleRewards() external;

    function depositToPool(uint256 amount) external;

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

    function getCycleUsers(
        uint256 cycle
    ) external view returns (address[] memory);

    function setAccessControls(address _accessControls) external;

    function setUserManager(address payable _userManager) external;

    function setPoolManager(address payable _poolManager) external;

    function setMonaAddress(address _mona) external;

    function setDevTreasuryAddress(address _devTreasury) external;

    function emergencyWithdraw(uint256 amount) external;

    function setCycleUser(address user) external;
}
