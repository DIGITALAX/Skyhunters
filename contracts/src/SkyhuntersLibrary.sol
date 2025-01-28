// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.24;

contract SkyhuntersLibrary {
    struct Agent {
        address[] agentWallets;
        address[] owners;
        string metadata;
        address creator;
        uint256 id;
        uint256 scorePositive;
        uint256 scoreNegative;
        uint256 active;
    }
}
