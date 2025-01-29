// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;
import "./SkyhuntersAccessControls.sol";

interface VerifiedContractInterface {
    function handleRewardsCalc() external;
}

contract SkyhuntersRewards {
    SkyhuntersAccessControls public accessControls;

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert SkyhuntersErrors.NotAdmin();
        }
        _;
    }

    event RewardsCalculated(address wallet);

    constructor(address payable _accessControls) payable {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }

    function calculateRewards() public onlyAdmin {
        address[] memory _contracts = accessControls.getVerifiedContracts();

        for (uint8 i = 0; i < _contracts.length; i++) {
            VerifiedContractInterface(_contracts[i]).handleRewardsCalc();
        }

        emit RewardsCalculated(msg.sender);
    }

    function setAccessControls(
        address payable _accessControls
    ) external onlyAdmin {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }
}
