// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SkyhuntersLibrary {
    struct Agent {
        EnumerableSet.AddressSet wallets;
        EnumerableSet.AddressSet owners;
        string metadata;
        address creator;
        uint256 id;
        uint256 scorePositive;
        uint256 scoreNegative;
        uint256 active;
    }

    struct Snapshot {
        string data;
        uint256 blocktimestamp;
    }
}
