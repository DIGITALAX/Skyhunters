// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./IPool.sol";
import "./../SkyhuntersAccessControls.sol";
import "./../SkyhuntersUserManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BasePool is IPool {
    address public poolManager;
    address public mona;
    address public devTreasury;
    uint256 private _cycleCounter;
    uint256 private _totalPoolBalance;
    SkyhuntersAccessControls public accessControls;
    SkyhuntersUserManager public userManager;

    mapping(address => uint256) public _userBalances;
    mapping(address => uint256) public _userRewards;
    mapping(uint256 => mapping(address => uint256)) public _userBalancesByCycle;
    mapping(uint256 => mapping(address => uint256)) public _userRewardsByCycle;
    mapping(uint256 => mapping(address => bool)) public _userClaimedByCycle;
    mapping(address => mapping(uint256 => bool)) private _usersByCycle;
    mapping(uint256 => address[]) private _cycleUsers;

    event Deposited(address indexed sender, uint256 amount, uint256 cycle);
    event RewardClaimed(address indexed user, uint256 amount, uint256 cycle);
    event CycleCleaned(uint256 cycle, uint256 amount);
    event CycleUserSet(address user, uint256 cycle);
    event CycleUsersSet(address[] users, uint256 cycle);

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert SkyhuntersErrors.NotAdmin();
        }
        _;
    }

    modifier onlyVerifiedContract() {
        if (!accessControls.isVerifiedContract(msg.sender)) {
            revert SkyhuntersErrors.NotVerifiedContract();
        }
        _;
    }

    constructor(
        address _accessControls,
        address payable _userManager,
        address payable _poolManager,
        address payable _devTreasury,
        address _mona
    ) {
        accessControls = SkyhuntersAccessControls(_accessControls);
        userManager = SkyhuntersUserManager(_userManager);
        poolManager = _poolManager;
        devTreasury = _devTreasury;
        _cycleCounter = 0;
        mona = _mona;
    }

    function claimCycleRewards() external override {
        if (_userBalances[msg.sender] == 0 || _userRewards[msg.sender] == 0) {
            revert SkyhuntersErrors.NoCycleRewards();
        }

        uint256 _reward = _userRewards[msg.sender];
    
        if (!IERC20(mona).transfer(msg.sender, _userBalances[msg.sender])) {
            revert SkyhuntersErrors.RewardClaimFailed();
        }

        _userClaimedByCycle[_cycleCounter][msg.sender] = true;
        _userBalances[msg.sender] = 0;
        _userRewards[msg.sender] = 0;

        emit RewardClaimed(msg.sender, _reward, _cycleCounter);
    }

    function depositToPool(uint256 amount) external override {
        _cycleCounter++;
        _totalPoolBalance += amount;
        uint256 _totalRewards = 0;

        for (uint256 i = 0; i < _cycleUsers[_cycleCounter].length; i++) {
            _totalRewards += _userRewards[_cycleUsers[_cycleCounter][i]];
        }

        for (uint256 i = 0; i < _cycleUsers[_cycleCounter].length; i++) {
            address _user = _cycleUsers[_cycleCounter][i];

            uint256 _userShare = (_userRewards[_user] * amount) / _totalRewards;
            _userBalancesByCycle[_cycleCounter][_user] = _userShare;
            _userBalances[_user] = _userShare;
        }

        emit Deposited(msg.sender, amount, _cycleCounter);
    }

    function cleanCycle(uint256 cycle) external override onlyAdmin {
        uint256 _amount = 0;

        for (uint128 i = 0; i < _cycleUsers[cycle].length; i++) {
            if (!_userClaimedByCycle[cycle][_cycleUsers[cycle][i]]) {
                _amount += _userBalancesByCycle[cycle][_cycleUsers[cycle][i]];
            }
        }

        if (IERC20(mona).balanceOf(address(this)) >= _amount) {
            IERC20(mona).transfer(devTreasury, _amount);

            emit CycleCleaned(cycle, _amount);
        } else {
            revert SkyhuntersErrors.InsufficientCycleBalance();
        }
    }

    function setCycleUser(
        address user,
        uint256 reward
    ) external override onlyVerifiedContract {
        if (!_usersByCycle[user][_cycleCounter]) {
            _cycleUsers[_cycleCounter].push(user);
        }

        _usersByCycle[user][_cycleCounter] = true;
        _userRewardsByCycle[_cycleCounter][user] = reward;
        _userRewards[user] = reward;

        emit CycleUserSet(user, _cycleCounter);
    }

    function setCycleUsers(
        address[] memory users,
        uint256[] memory rewards
    ) external override onlyVerifiedContract {
        for (uint256 i = 0; i < users.length; i++) {
            if (!_usersByCycle[users[i]][_cycleCounter]) {
                _cycleUsers[_cycleCounter].push(users[i]);
            }

            _usersByCycle[users[i]][_cycleCounter] = true;
            _userRewardsByCycle[_cycleCounter][users[i]] = rewards[i];
            _userRewards[users[i]] = rewards[i];
        }

        emit CycleUsersSet(users, _cycleCounter);
    }

    function getUserCurrentCycleRewards(
        address user
    ) external view override returns (uint256) {
        return _userRewards[user];
    }

    function getUserRewardsByCycle(
        address user,
        uint256 cycle
    ) external view override returns (uint256) {
        return _userRewardsByCycle[cycle][user];
    }

    function getUserCurrentCycleBalances(
        address user
    ) external view override returns (uint256) {
        return _userBalances[user];
    }

    function getUserBalancesByCycle(
        address user,
        uint256 cycle
    ) external view override returns (uint256) {
        return _userBalancesByCycle[cycle][user];
    }

    function getUserClaimedByCycle(
        address user,
        uint256 cycle
    ) external view override returns (bool) {
        return _userClaimedByCycle[cycle][user];
    }

    function getCycleCounter() external view override returns (uint256) {
        return _cycleCounter;
    }

    function getPoolBalance() external view override returns (uint256) {
        return _totalPoolBalance;
    }

    function getCycleUsers(
        uint256 cycle
    ) external view override returns (address[] memory) {
        return _cycleUsers[cycle];
    }

    function setAccessControls(address _accessControls) public onlyAdmin {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }

    function setUserManager(
        address payable _userManager
    ) external override onlyAdmin {
        userManager = SkyhuntersUserManager(_userManager);
    }

    function setPoolManager(
        address payable _poolManager
    ) external override onlyAdmin {
        poolManager = _poolManager;
    }

    function setMonaAddress(address _mona) external override onlyAdmin {
        mona = _mona;
    }

    function setDevTreasuryAddress(
        address _devTreasury
    ) external override onlyAdmin {
        devTreasury = _devTreasury;
    }

    function emergencyWithdraw(uint256 amount) external override onlyAdmin {
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}

    fallback() external payable {}
}
