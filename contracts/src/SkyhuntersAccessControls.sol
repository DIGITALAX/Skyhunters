// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./SkyhuntersErrors.sol";

contract SkyhuntersAccessControls {
    address public agentsContract;

    mapping(address => bool) private _admins;
    mapping(address => bool) private _verifiedContracts;
    mapping(address => bool) private _agents;

    modifier onlyAdmin() {
        if (!_admins[msg.sender]) {
            revert SkyhuntersErrors.NotAdmin();
        }
        _;
    }

    modifier onlyAgentOrAdmin() {
        if (!_admins[msg.sender] && !_agents[msg.sender]) {
            revert SkyhuntersErrors.NotAgentOrAdmin();
        }
        _;
    }

    modifier onlyAgentContractOrAdmin() {
        if (msg.sender != agentsContract && !_admins[msg.sender]) {
            revert SkyhuntersErrors.OnlyAgentContract();
        }
        _;
    }

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event VerifiedContractAdded(address indexed admin);
    event VerifiedContractRemoved(address indexed admin);
    event AgentAdded(address indexed agent);
    event AgentRemoved(address indexed agent);

    constructor() {
        _admins[msg.sender] = true;
    }

    function addAdmin(address admin) external onlyAdmin {
        if (_admins[admin]) {
            revert SkyhuntersErrors.AdminAlreadyExists();
        }
        _admins[admin] = true;
        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) external onlyAdmin {
        if (!_admins[admin]) {
            revert SkyhuntersErrors.AdminDoesntExist();
        }

        if (admin == msg.sender) {
            revert SkyhuntersErrors.CannotRemoveSelf();
        }

        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    function addVerifiedContract(address verifiedContract) external onlyAdmin {
        if (_verifiedContracts[verifiedContract]) {
            revert SkyhuntersErrors.ContractAlreadyExists();
        }
        _verifiedContracts[verifiedContract] = true;
        emit VerifiedContractAdded(verifiedContract);
    }

    function removeVerifiedContract(
        address verifiedContract
    ) external onlyAdmin {
        if (!_verifiedContracts[verifiedContract]) {
            revert SkyhuntersErrors.ContractDoesntExist();
        }

        _verifiedContracts[verifiedContract] = false;
        emit VerifiedContractRemoved(verifiedContract);
    }

    function addAgent(address agent) external onlyAgentContractOrAdmin {
        if (_agents[agent]) {
            revert SkyhuntersErrors.AgentAlreadyExists();
        }
        _agents[agent] = true;
        emit AgentAdded(agent);
    }

    function removeAgent(address agent) external onlyAgentContractOrAdmin {
        if (!_agents[agent]) {
            revert SkyhuntersErrors.AgentDoesntExist();
        }

        _agents[agent] = false;
        emit AgentRemoved(agent);
    }

    function setAgentsContract(address _agentsContract) public onlyAdmin {
        agentsContract = _agentsContract;
    }

    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    function isVerifiedContract(
        address verifiedContract
    ) public view returns (bool) {
        return _verifiedContracts[verifiedContract];
    }

    function isAgent(address _address) public view returns (bool) {
        return _agents[_address];
    }
}
