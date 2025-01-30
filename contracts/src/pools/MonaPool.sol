// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./BasePool.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./../helpers/TokenSnapshots.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract MonaPool is BasePool {
    address public uniswapV3Pool;
    TokenSnapshots public tokenSnapshots;
    INonfungiblePositionManager public positionManager;

    mapping(address => uint256) public monaBalance;
    mapping(address => uint256) public lastDepositTimestamp;
    EnumerableSet.AddressSet private monaHolders;

    constructor(
        address _accessControls,
        address payable _userManager,
        address payable _poolManager,
        address payable _devTreasury,
        address _mona,
        address _uniswapV3Pool,
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
        uniswapV3Pool = _uniswapV3Pool;
        tokenSnapshots = TokenSnapshots(_tokenSnapshots);
        positionManager = INonfungiblePositionManager(_positionManager);
    }

    function _rewardCheck(address user) internal override returns (uint256) {
        uint256 _userLiquidity = _getUniswapV3Stake(user);
        uint256 _userBalance = IERC20(mona).balanceOf(user);
        uint256 _holdTime = tokenSnapshots.getMonaUserHoldTime(user);

        uint256 _weekFactor = _holdTime >= 7 days ? 1 : _holdTime / 7 days;
        uint256 _timeFactor = _holdTime / 30 days;
        uint256 _totalFactor = (_userLiquidity + _userBalance) *
            (_timeFactor + _weekFactor);

        return (calculatedReward * _totalFactor) / (_totalFactor + 1);
    }

    function _getUniswapV3Stake(
        address user
    ) public view returns (uint256 monaAmount) {
        uint256 _balance = positionManager.balanceOf(user);
        uint256 _liquidity = 0;
        IUniswapV3Pool pool = IUniswapV3Pool(uniswapV3Pool);

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

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
            uint256 price = uint256(sqrtPriceX96) ** 2 / (2 ** 192);
            monaAmount = token0 == mona
                ? (_liquidity * price) / 1e18
                : (_liquidity * 1e18) / price;
        }

        return monaAmount;
    }

    function setTokenSnapshots(address _tokenSnapshots) public onlyAdmin {
        tokenSnapshots = TokenSnapshots(_tokenSnapshots);
    }
}
