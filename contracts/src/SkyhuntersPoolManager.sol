// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./SkyhuntersAccessControls.sol";
import "./SkyhuntersErrors.sol";

contract SkyhuntersPoolManager {
    SkyhuntersAccessControls public accessControls;
    mapping(address => uint256) private _poolBalance;

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

    event RewardsReceived(address sender, address token, uint256 amount);

    constructor(address _accessControls) payable {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }

    function setAccessControls(address _accessControls) public onlyAdmin {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }

    function receiveRewards(
        address token,
        uint256 rewards
    ) public onlyVerifiedContract {
        _poolBalance[token] += rewards;

        emit RewardsReceived(msg.sender, token, rewards);
    }

    function depositToPool() public onlyVerifiedContract{

    }

    receive() external payable {}

    fallback() external payable {}
}
