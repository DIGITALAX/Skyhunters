// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./IPool.sol";
import "./../SkyhuntersAccessControls.sol";
import "./../SkyhuntersUserManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MonaTokenPool is IPool {
    address public poolManager;
    address public mona;
    address public devTreasury;
    uint256 private _cycleCounter;
    uint256 private _totalPoolBalance;
    SkyhuntersAccessControls public accessControls;
    SkyhuntersUserManager public userManager;

    mapping(address => uint256) public _userBalance;
    mapping(address => uint256) public _userRewards;
    mapping(uint256 => mapping(address => uint256)) public _userBalanceByCycle;
    mapping(uint256 => mapping(address => uint256)) public _userRewardsByCycle;
    mapping(uint256 => mapping(address => bool)) public _userClaimedByCycle;

    event Deposited(address indexed sender, uint256 amount, uint256 cycle);
    event RewardClaimed(address indexed user, uint256 amount, uint256 cycle);
    event CycleCleaned(uint256 cycle, uint256 amount);

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert SkyhuntersErrors.NotAdmin();
        }
        _;
    }

    constructor(
        address _accessControls,
        address payable _userManager,
        address payable _poolManager,
        address _mona,
        address payable _devTreasury
    ) {
        accessControls = SkyhuntersAccessControls(_accessControls);
        userManager = SkyhuntersUserManager(_userManager);
        poolManager = _poolManager;
        devTreasury = _devTreasury;
        _cycleCounter = 0;
        mona = _mona;
    }

    function claimCycleRewards() public {
        if (_userBalance[msg.sender] == 0) {
            revert SkyhuntersErrors.NoCycleRewards();
        }

        uint256 _reward = _userBalance[msg.sender];

        if (!IERC20(mona).transfer(msg.sender, _reward)) {
            revert SkyhuntersErrors.RewardClaimFailed();
        }

        _userClaimedByCycle[_cycleCounter][msg.sender] = true;
        _userBalance[msg.sender] = 0;
        _userRewards[msg.sender] = 0;

        emit RewardClaimed(msg.sender, _reward, _cycleCounter);
    }

    function depositToPool(uint256 amount) external override {
        _cycleCounter++;
        _totalPoolBalance += amount;

        _cycleRewardsCalc();

        emit Deposited(msg.sender, amount, _cycleCounter);
    }

    function cleanCycle(uint256 cycle) public onlyAdmin {
        address[] memory _cycleUsers = userManager.getCycleUsers(cycle);
        uint256 _amount = 0;

        for (uint128 i = 0; i < _cycleUsers.length; i++) {
            if (!_userClaimedByCycle[cycle][_cycleUsers[i]]) {
                _amount += _userBalanceByCycle[cycle][_cycleUsers[i]];
            }
        }

        if (IERC20(mona).balanceOf(address(this)) >= _amount) {
            IERC20(mona).transfer(devTreasury, _amount);

            emit CycleCleaned(cycle, _amount);
        } else {
            revert SkyhuntersErrors.InsufficientCycleBalance();
        }
    }

    function _cycleRewardsCalc() internal {
        // based on mona + staking of mona
    }

    function getUserCurrentCycleRewards(
        address user
    ) external view returns (uint256) {
        return _userRewards[user];
    }

    function getUserRewardsByCycle(
        address user,
        uint256 cycle
    ) external view returns (uint256) {
        return _userRewardsByCycle[cycle][user];
    }

    function getUserCurrentCycleBalance(
        address user
    ) external view returns (uint256) {
        return _userBalance[user];
    }

    function getUserBalanceByCycle(
        address user,
        uint256 cycle
    ) external view returns (uint256) {
        return _userBalanceByCycle[cycle][user];
    }

    function getUserClaimedByCycle(
        address user,
        uint256 cycle
    ) external view returns (bool) {
        return _userClaimedByCycle[cycle][user];
    }

    function getCycleCounter() public view returns (uint256) {
        return _cycleCounter;
    }

    function getPoolBalance() public view returns (uint256) {
        return _totalPoolBalance;
    }

    function setAccessControls(address _accessControls) public onlyAdmin {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }

    function setUserManager(address payable _userManager) public onlyAdmin {
        userManager = SkyhuntersUserManager(_userManager);
    }

    function setPoolManager(address payable _poolManager) public onlyAdmin {
        poolManager = _poolManager;
    }

    function setMonaAddress(address _mona) public onlyAdmin {
        mona = _mona;
    }

    function setDevTreasuryAddress(address _devTreasury) public onlyAdmin {
        devTreasury = _devTreasury;
    }

    function emergencyWithdraw(uint256 amount) external onlyAdmin {
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}

    fallback() external payable {}
}
