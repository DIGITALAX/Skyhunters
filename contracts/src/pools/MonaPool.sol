// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./BasePool.sol";
import "./../helpers/TokenSnapshots.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

contract MonaPool is BasePool {
    TokenSnapshots public tokenSnapshots;
    INonfungiblePositionManager public positionManager;

    mapping(uint256 => uint256) private _monaPriceSnapshots;

    constructor(
        address _accessControls,
        address payable _userManager,
        address payable _poolManager,
        address payable _devTreasury,
        address _mona,
        address _positionManager,
        address _tokenSnapshots
    )
        BasePool(
            _accessControls,
            _userManager,
            _poolManager,
            _devTreasury,
            _mona
        )
    {
        tokenSnapshots = TokenSnapshots(_tokenSnapshots);
        positionManager = INonfungiblePositionManager(_positionManager);
    }

    function _rewardCheck(address user) internal override returns (uint256) {
        uint256 _userLiquidity = _getUniswapV3Stake(user);
        uint256 _userBalance = IERC20(mona).balanceOf(user);
        uint256 _holdTime = tokenSnapshots.getMonaUserHoldTime(user);

        uint256 _weekFactor = _holdTime >= 7 days ? 1 : _holdTime / 7 days;
        uint256 _timeFactor = _holdTime / 30 days;

        return (_userLiquidity + _userBalance) * (_timeFactor + _weekFactor);
    }

    function _getUniswapV3Stake(
        address user
    ) public view returns (uint256 monaAmount) {
        uint256 _balance = positionManager.balanceOf(user);
        uint256 _liquidity = 0;
        uint256 _price = _monaPriceSnapshots[_cycleCounter];

        for (uint256 i = 0; i < _balance; i++) {
            uint256 tokenId = positionManager.tokenOfOwnerByIndex(user, i);
            (
                ,
                ,
                address token0,
                address token1,
                ,
                ,
                ,
                uint128 liquidityAmount,
                ,
                ,
                ,

            ) = positionManager.positions(tokenId);

            if (token0 == mona || token1 == mona) {
                _liquidity += liquidityAmount;
            }
        }

        if (_liquidity > 0) {
            monaAmount = token0 == mona
                ? (_liquidity * _price) / 1e18
                : (_liquidity * 1e18) / _price;
        }

        return monaAmount;
    }

    function setTokenSnapshots(address _tokenSnapshots) public onlyAdmin {
        tokenSnapshots = TokenSnapshots(_tokenSnapshots);
    }

    function getMonaPriceSnapshot(uint256 cycle) public view returns (uint256) {
        return _monaPriceSnapshots[cycle];
    }
}
