// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./../SkyhuntersAccessControls.sol";
import "./../SkyhuntersLibrary.sol";

contract TokenSnapshots {
    SkyhuntersAccessControls public accessControls;
    mapping(address => mapping(uint256 => SkyhuntersLibrary.Snapshot))
        private _snapshots;

    event SnapshotSet(string data, address verifiedContract, uint256 cycle);

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert SkyhuntersErrors.NotAdmin();
        }
        _;
    }

    constructor(address _accessControls) {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }

    function setSnapshot(
        string memory data,
        address verifiedContract,
        uint256 cycle
    ) public onlyAdmin {
        _snapshots[verifiedContract][cycle] = SkyhuntersLibrary.Snapshot({
            blocktimestamp: block.timestamp,
            data: data
        });

        emit SnapshotSet(data, verifiedContract, cycle);
    }

    function getSnapshotTimestamp(
        address verifiedContract,
        uint256 cycle
    ) public view returns (uint256) {
        return _snapshots[verifiedContract][cycle].blocktimestamp;
    }

    function getSnapshotData(
        address verifiedContract,
        uint256 cycle
    ) public view returns (string memory) {
        return _snapshots[verifiedContract][cycle].data;
    }

    function setAccessControls(address _accessControls) public onlyAdmin {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }
}
