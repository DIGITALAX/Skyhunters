// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./BasePool.sol";

contract MonaPool is BasePool {
    constructor(
        address _accessControls,
        address payable _userManager,
        address payable _poolManager,
        address payable _devTreasury,
        address _mona
    )
        BasePool(
            _accessControls,
            _userManager,
            _poolManager,
            _devTreasury,
            _mona
        )
    {}
}
