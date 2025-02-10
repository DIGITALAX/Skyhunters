// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./IPool.sol";
import "./../SkyhuntersAccessControls.sol";
import "./../SkyhuntersUserManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract BasePool is IPool {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public poolManager;
    address public mona;
    address public devTreasury;
    EnumerableSet.AddressSet private _activeTokens;
    uint256 private _cycleCounter;
    uint256 private _totalPoolBalance;
    uint256 private _historicalPoolBalance;
    SkyhuntersAccessControls public accessControls;
    SkyhuntersUserManager public userManager;

    mapping(address => uint256) private _userBalances;
    mapping(address => uint256) private _userRewards;
    mapping(address => mapping(address => uint256))
        private _additionalTokensUserBalances;
    mapping(uint256 => mapping(address => uint256))
        private _userBalancesByCycle;
    mapping(uint256 => mapping(address => uint256)) private _userRewardsByCycle;
    mapping(uint256 => mapping(address => mapping(address => uint256)))
        private _additionalTokensUserBalancesByCycle;
    mapping(uint256 => mapping(address => bool)) private _userClaimedByCycle;
    mapping(address => mapping(uint256 => bool)) private _usersByCycle;
    mapping(uint256 => address[]) private _cycleUsers;
    mapping(uint256 => uint256) private _totalRewardsByCycle;
    mapping(address => uint256) private _totalPoolBalanceByToken;
    mapping(address => uint256) private _historicalPoolBalanceByToken;

    event Deposited(
        address indexed sender,
        uint256 amount,
        uint256 cycle,
        uint256 totalRewards
    );
    event RewardClaimed(address indexed user, uint256 amount, uint256 cycle);
    event CycleCleaned(address token, uint256 cycle, uint256 amount);
    event CycleUserSet(address user, uint256 cycle);
    event CycleUsersSet(address[] users, uint256 cycle);
    event AdditionalTokensDeposited(address[] tokens, uint256[] amounts);
    event AdditionalTokenRewardClaimed(
        address indexed user,
        address token,
        uint256 amount,
        uint256 cycle
    );

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
        address payable _accessControls,
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
        _totalPoolBalance -= _userBalances[msg.sender];
        _userClaimedByCycle[_cycleCounter][msg.sender] = true;
        _userBalances[msg.sender] = 0;
        _userRewards[msg.sender] = 0;

        for (uint8 i = 0; i < _activeTokens.length(); i++) {
            uint256 _amount = _additionalTokensUserBalances[
                _activeTokens.at(i)
            ][msg.sender];
            if (_amount > 0) {
                if (
                    !IERC20(_activeTokens.at(i)).transfer(
                        msg.sender,
                        _additionalTokensUserBalances[_activeTokens.at(i)][
                            msg.sender
                        ]
                    )
                ) {
                    revert SkyhuntersErrors.RewardClaimFailed();
                }

                if (_amount <= _totalPoolBalanceByToken[_activeTokens.at(i)]) {
                    _totalPoolBalanceByToken[_activeTokens.at(i)] -= _amount;
                } else {
                    _totalPoolBalanceByToken[_activeTokens.at(i)] = 0;
                }

                _additionalTokensUserBalances[_activeTokens.at(i)][
                    msg.sender
                ] = 0;

                emit AdditionalTokenRewardClaimed(
                    msg.sender,
                    _activeTokens.at(i),
                    _amount,
                    _cycleCounter
                );
            }
        }

        emit RewardClaimed(msg.sender, _reward, _cycleCounter);
    }

    function depositToPool(uint256 amount) external override {
        _cycleCounter++;
        _historicalPoolBalance += amount;
        _totalPoolBalance += amount;
        uint256 _totalRewards = 0;

        for (uint256 i = 0; i < _cycleUsers[_cycleCounter].length; i++) {
            _totalRewards += _userRewards[_cycleUsers[_cycleCounter][i]];
        }

        for (uint8 i = 0; i < _cycleUsers[_cycleCounter].length; i++) {
            address _user = _cycleUsers[_cycleCounter][i];

            uint256 _userShare = (_userRewards[_user] * amount) / _totalRewards;
            _userBalancesByCycle[_cycleCounter][_user] = _userShare;
            _userBalances[_user] = _userShare;
        }

        _totalRewardsByCycle[_cycleCounter] = _totalRewards;

        emit Deposited(msg.sender, amount, _cycleCounter, _totalRewards);
    }

    function depositAdditionalPoolTokens(
        address[] memory tokens,
        uint256[] memory amounts
    ) public onlyAdmin {
        if (tokens.length != amounts.length) {
            revert SkyhuntersErrors.BadUserInput();
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            _totalPoolBalanceByToken[tokens[i]] += amounts[i];
            _historicalPoolBalanceByToken[tokens[i]] += amounts[i];

            if (!_activeTokens.contains(tokens[i])) {
                _activeTokens.add((tokens[i]));
            }
            for (uint256 j = 0; j < _cycleUsers[_cycleCounter].length; j++) {
                address _user = _cycleUsers[_cycleCounter][j];

                uint256 _userShare = (_userRewards[_user] * amounts[i]) /
                    _totalRewardsByCycle[_cycleCounter];

                _additionalTokensUserBalancesByCycle[_cycleCounter][tokens[i]][
                    _user
                ] = _userShare;

                _additionalTokensUserBalances[tokens[i]][_user] = _userShare;
            }
        }

        emit AdditionalTokensDeposited(tokens, amounts);
    }

    function cleanCycle(uint256 cycle) external override onlyAdmin {
        uint256 _amount = 0;
        address[] memory users = _cycleUsers[cycle];
        uint256 usersLength = users.length;

        for (uint128 i = 0; i < usersLength; i++) {
            address user = users[i];
            if (!_userClaimedByCycle[cycle][user]) {
                _amount += _userBalancesByCycle[cycle][user];
            }
        }

        if (!IERC20(mona).transfer(devTreasury, _amount)) {
            revert SkyhuntersErrors.TransferFailed();
        }

        emit CycleCleaned(mona, cycle, _amount);

        address[] memory activeTokens = _activeTokens.values();
        uint256 activeTokensLength = activeTokens.length;
        uint256[] memory tokenAmounts = new uint256[](activeTokensLength);
        address[] memory tokensToRemove = new address[](activeTokensLength);
        uint8 removeCount = 0;

        for (uint8 j = 0; j < activeTokensLength; j++) {
            uint256 _tokenAmount = 0;
            address token = activeTokens[j];

            for (uint128 i = 0; i < usersLength; i++) {
                address user = users[i];
                if (!_userClaimedByCycle[cycle][user]) {
                    _tokenAmount += _additionalTokensUserBalancesByCycle[cycle][
                        token
                    ][user];
                }
            }

            tokenAmounts[j] = _tokenAmount;

            if (!IERC20(token).transfer(devTreasury, _tokenAmount)) {
                revert SkyhuntersErrors.TransferFailed();
            }

            if (_tokenAmount <= _totalPoolBalanceByToken[token]) {
                _totalPoolBalanceByToken[token] -= _tokenAmount;
            } else {
                _totalPoolBalanceByToken[token] = 0;
            }

            if (_totalPoolBalanceByToken[token] == 0) {
                tokensToRemove[removeCount] = token;
                removeCount++;
            }
        }

        for (uint8 j = 0; j < removeCount; j++) {
            _activeTokens.remove(tokensToRemove[j]);
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

    function getAdditionalTokensUserBalancesByCycle(
        address user,
        address token,
        uint256 cycle
    ) external view override returns (uint256) {
        return _additionalTokensUserBalancesByCycle[cycle][token][user];
    }

    function getAdditionalTokensUserCurrentCycleBalances(
        address user,
        address token
    ) external view override returns (uint256) {
        return _additionalTokensUserBalances[token][user];
    }

    function getUserClaimedByCycle(
        address user,
        uint256 cycle
    ) external view override returns (bool) {
        return _userClaimedByCycle[cycle][user];
    }

    function getCycleUsers(
        uint256 cycle
    ) external view override returns (address[] memory) {
        return _cycleUsers[cycle];
    }

    function getCycleCounter() external view override returns (uint256) {
        return _cycleCounter;
    }

    function getPoolBalance() external view override returns (uint256) {
        return _totalPoolBalance;
    }

    function getPoolHistoricalBalance()
        external
        view
        override
        returns (uint256)
    {
        return _historicalPoolBalance;
    }

    function getActiveTokens()
        external
        view
        override
        returns (address[] memory)
    {
        return _activeTokens.values();
    }

    function getTotalRewardsByCycle(
        uint256 cycle
    ) external view override returns (uint256) {
        return _totalRewardsByCycle[cycle];
    }

    function getHistoricalPoolBalanceByToken(
        address token
    ) external view override returns (uint256) {
        return _historicalPoolBalanceByToken[token];
    }

    function getPoolBalanceByToken(
        address token
    ) external view override returns (uint256) {
        return _totalPoolBalanceByToken[token];
    }

    function setAccessControls(
        address payable _accessControls
    ) public onlyAdmin {
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

    function emergencyWithdraw(
        uint256 amount,
        uint256 gasAmount
    ) external onlyAdmin {
        (bool success, ) = payable(msg.sender).call{
            value: amount,
            gas: gasAmount
        }("");
        if (!success) {
            revert SkyhuntersErrors.TransferFailed();
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
