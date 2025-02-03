// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./SkyhuntersAccessControls.sol";
import "./SkyhuntersErrors.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./pools/IPool.sol";

contract SkyhuntersPoolManager {
    SkyhuntersAccessControls public accessControls;
    string public symbol;
    string public name;
    address public mona;
    uint256 private _poolBalance;

    mapping(address => uint256) private _poolPercent;

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

    modifier onlyVerifiedPool() {
        if (!accessControls.isPool(msg.sender)) {
            revert SkyhuntersErrors.NotVerifiedPool();
        }
        _;
    }

    event RewardsReceived(address sender, address token, uint256 amount);
    event PoolPercent(address[] pools, uint256[] percents);
    event PoolsDeposited(address[] pools, uint256[] amounts);

    constructor(address _accessControls, address _mona) payable {
        accessControls = SkyhuntersAccessControls(_accessControls);
        mona = _mona;
        name = "SkyhuntersPoolManager";
        symbol = "SPM";
    }

    function receiveRewards(
        address token,
        uint256 rewards
    ) public onlyVerifiedContract {
        if (token != mona) {
            revert SkyhuntersErrors.OnlyMonaAccepted();
        }
        _poolBalance += rewards;

        emit RewardsReceived(msg.sender, token, rewards);
    }

    function depositToPools() public onlyAdmin {
        address[] memory _verifiedPools = accessControls.getVerifiedPools();
        uint256[] memory _amounts = new uint256[](_verifiedPools.length);

        for (uint8 i = 0; i < _verifiedPools.length; i++) {
            _amounts[i] =
                (_poolBalance * _poolPercent[_verifiedPools[i]]) /
                100;

            if (!IERC20(mona).transfer(_verifiedPools[i], _amounts[i])) {
                revert SkyhuntersErrors.PoolDepositFailed();
            } else {
                IPool(_verifiedPools[i]).depositToPool(_amounts[i]);
            }
        }

        _poolBalance = 0;

        emit PoolsDeposited(_verifiedPools, _amounts);
    }

    function setPoolPercents(
        address[] memory pools,
        uint256[] memory percents
    ) public onlyAdmin {
        uint256 total = 0;
        for (uint8 i = 0; i < pools.length; i++) {
            if (!accessControls.isPool(pools[i])) {
                revert SkyhuntersErrors.NotVerifiedPool();
            }

            total += percents[i];
        }

        if (total > 100) {
            revert SkyhuntersErrors.InvalidPercents();
        }

        for (uint8 i = 0; i < pools.length; i++) {
            _poolPercent[pools[i]] = percents[i];
        }

        emit PoolPercent(pools, percents);
    }

    function getPoolPercent(address pool) public view returns (uint256) {
        return _poolPercent[pool];
    }

    function getPoolBalance() public view returns (uint256) {
        return _poolBalance;
    }

    function setAccessControls(address _accessControls) public onlyAdmin {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }

    function setMonaAddress(address _mona) public onlyAdmin {
        mona = _mona;
    }

    function emergencyWithdraw(uint256 amount) external onlyAdmin {
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}

    fallback() external payable {}
}
