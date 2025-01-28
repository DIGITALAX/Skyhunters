// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.24;

import "./SkyhuntersAccessControls.sol";
import "./SkyhuntersLibrary.sol";
import "./SkyhuntersErrors.sol";
import "./SkyhuntersAgentManager.sol";

contract SkyhuntersAgentActivity {
    address public market;
    SkyhuntersAccessControls public accessControls;
    SkyhuntersAgentManager public agentManager;
    mapping(uint256 => mapping(address => uint256))
        private _agentCurrentBalance;
    mapping(uint256 => mapping(address => uint256))
        private _agentBalanceHistory;

    event BalanceUpdated(
        address token,
        address verifiedContract,
        uint256 agentId,
        uint256 amount
    );

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

    constructor(
        address payable _accessControls,
        address _agentManager
    ) payable {
        accessControls = SkyhuntersAccessControls(_accessControls);
        agentManager = SkyhuntersAgentManager(_agentManager);
    }

    function addCurrentBalance(
        address token,
        uint256 agentId,
        uint256 amount
    ) external onlyVerifiedContract {
        _agentCurrentBalance[agentId][token] += amount;

        emit BalanceUpdated(
            token,
            msg.sender,
            agentId,
            _agentCurrentBalance[agentId][token]
        );
    }

    function subtractCurrentBalance(
        address token,
        uint256 agentId,
        uint256 amount
    ) external onlyVerifiedContract {
        if (amount > _agentCurrentBalance[agentId][token]) {
            revert SkyhuntersErrors.InvalidAmount();
        }

        _agentCurrentBalance[agentId][token] -= amount;

        emit BalanceUpdated(
            token,
            msg.sender,
            agentId,
            _agentCurrentBalance[agentId][token]
        );
    }

    function getAgentBalanceHistory(
        address token,
        uint256 agentId
    ) public view returns (uint256) {
        return _agentBalanceHistory[agentId][token];
    }

    function getAgentCurrentBalance(
        address token,
        uint256 agentId
    ) public view returns (uint256) {
        return _agentCurrentBalance[agentId][token];
    }

    function setAccessControls(
        address payable _accessControls
    ) external onlyAdmin {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }

    function setAgentManager(address _agentManager) external onlyAdmin {
        agentManager = SkyhuntersAgentManager(_agentManager);
    }
}
