// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./../SkyhuntersAccessControls.sol";

contract TokenSnapshots {
    SkyhuntersAccessControls public accessControls;

    mapping(address => uint256) private _monaHoldTime;

    event MonaHoldTimes(address[] users, uint256[] timestamps);

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert SkyhuntersErrors.NotAdmin();
        }
        _;
    }

    constructor(address _accessControls) {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }

    function setMonaUsersHoldTime(
        address[] memory users,
        uint256[] memory timestamps
    ) public onlyAdmin {
        if (timestamps.length != users.length) {
            revert SkyhuntersErrors.BadUserInput();
        }

        for (uint256 i = 0; i < users.length; i++) {
            _monaHoldTime[users[i]] = timestamps[i];
        }

        emit MonaHoldTimes(users, timestamps);
    }

    function getMonaUserHoldTime(address user) public view returns (uint256) {
        return _monaHoldTime[user];
    }

    function setAccessControls(address _accessControls) public onlyAdmin {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }
}
