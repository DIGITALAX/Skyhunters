// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./SkyhuntersAccessControls.sol";
import "./SkyhuntersErrors.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./pools/IPool.sol";
// import {UniversalRouter} from "universal-router/contracts/UniversalRouter.sol";
// import {Commands} from "universal-router/contracts/libraries/Commands.sol";
// import {IPoolManager} from "v4-core/PoolManager.sol";
// import {IV4Router} from "v4-periphery/src/V4Router.sol";
// import {Actions} from "v4-periphery/src/libraries/Actions.sol";
// import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

contract SkyhuntersPoolManager {
    // using StateLibrary for IPoolManager;

    // UniversalRouter public immutable router;
    // IPoolManager public immutable poolManager;
    // IPermit2 public immutable permit2;
    SkyhuntersAccessControls public accessControls;
    string public symbol;
    string public name;
    address public mona;
    address public grass;

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

    event PoolPercent(address[] pools, uint256[] percents);
    event PoolsDeposited(address[] pools, uint256[] amounts);

    constructor(
        address payable _accessControls,
        address _mona,
        address _grass,
        address _router,
        address _poolManager,
        address _permit2
    ) payable {
        accessControls = SkyhuntersAccessControls(_accessControls);
        // router = UniversalRouter(_router);
        // poolManager = IPoolManager(_poolManager);
        // permit2 = IPermit2(_permit2);
        mona = _mona;
        grass = _grass;
        name = "SkyhuntersPoolManager";
        symbol = "SPM";
    }

    function depositToPools() public onlyAdmin {
        address[] memory _verifiedPools = accessControls.getVerifiedPools();
        uint256[] memory _amounts = new uint256[](_verifiedPools.length);

        _handleSwap();

        uint256 _monaBalance = IERC20(mona).balanceOf(address(this));

        for (uint8 i = 0; i < _verifiedPools.length; i++) {
            _amounts[i] =
                (_monaBalance * _poolPercent[_verifiedPools[i]]) /
                100;

            if (!IERC20(mona).transfer(_verifiedPools[i], _amounts[i])) {
                revert SkyhuntersErrors.PoolDepositFailed();
            } else {
                IPool(_verifiedPools[i]).depositToPool(_amounts[i]);
            }
        }
        emit PoolsDeposited(_verifiedPools, _amounts);
    }

    function _handleSwap() internal {
        address[] memory _tokens = accessControls.getAcceptedTokens();

        for (uint8 i = 0; i < _tokens.length; i++) {
            uint256 _amount = IERC20(_tokens[i]).balanceOf(address(this));

            if (_tokens[i] != mona && _amount > 0) {
                // address _currency0 = _tokens[i];
                // address _currency1 = Currency.wrap(mona);
                // if (_tokens[i] == grass) {
                //     _currency0 = Currency.wrap(address(0));
                // }

                // PoolKey memory key = PoolKey({
                //     currency0: _currency0,
                //     currency1: _currency1,
                //     fee: 3000,
                //     tickSpacing: 60,
                //     hooks: IHooks(address(0))
                // });

                // IERC20(_tokens[i]).approve(address(permit2), type(uint256).max);
                // permit2.approve(
                //     _tokens[i],
                //     address(router),
                //     uint160(_amount),
                //     uint48(block.timestamp + 1 days)
                // );

                // bytes memory _commands = abi.encodePacked(
                //     uint8(Commands.V4_SWAP)
                // );

                // bytes memory _actions = abi.encodePacked(
                //     uint8(Actions.SWAP_EXACT_IN_SINGLE),
                //     uint8(Actions.SETTLE_ALL),
                //     uint8(Actions.TAKE_ALL)
                // );

                // bytes[] memory _params = new bytes[](3);
                // bytes[] memory _inputs = new bytes[](1);

                // _params[0] = abi.encode(
                //     IV4Router.ExactInputSingleParams({
                //         poolKey: key,
                //         zeroForOne: true,
                //         amountIn: uint128(_amount),
                //         amountOutMinimum: 0,
                //         sqrtPriceLimitX96: uint160(0),
                //         hookData: bytes("")
                //     })
                // );
                // _params[1] = abi.encode(key.currency0, _amount);
                // _params[2] = abi.encode(key.currency1, 0);

                // _inputs[0] = abi.encode(_actions, _params);

                // router.execute(_commands, _inputs, block.timestamp);
            }
        }
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

    function getPoolTokenBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function setAccessControls(
        address payable _accessControls
    ) public onlyAdmin {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }

    function setMonaAddress(address _mona) public onlyAdmin {
        mona = _mona;
    }

    function setGrassAddress(address _grass) public onlyAdmin {
        grass = _grass;
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
