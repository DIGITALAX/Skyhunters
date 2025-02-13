// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./SkyhuntersAccessControls.sol";
import "./SkyhuntersLibrary.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

contract SkyhuntersAgentManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private _agentCounter;
    string public symbol;
    string public name;
    SkyhuntersAccessControls public accessControls;
    mapping(uint256 => SkyhuntersLibrary.Agent) private _agents;

    event AgentCreated(address[] wallets, address creator, uint256 indexed id);
    event AgentDeleted(uint256 indexed id);
    event AgentEdited(uint256 indexed id);
    event RevokeOwner(address wallet, uint256 agentId);
    event AddOwner(address wallet, uint256 agentId);
    event RevokeAgentWallet(address wallet, uint256 agentId);
    event AddAgentWallet(address wallet, uint256 agentId);
    event AgentScored(
        address scorer,
        uint256 agentId,
        uint256 score,
        bool positive
    );
    event AgentSetActive(address wallet, uint256 agentId);
    event AgentSetInactive(address wallet, uint256 agentId);

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert SkyhuntersErrors.NotAdmin();
        }
        _;
    }

    modifier onlyAgentOwnerOrCreator(uint256 agentId) {
        if (
            !_agents[agentId].owners.contains(msg.sender) &&
            _agents[agentId].creator != msg.sender
        ) {
            revert SkyhuntersErrors.NotAgentOwner();
        }

        _;
    }

    modifier onlyAgentCreator(uint256 agentId) {
        if (_agents[agentId].creator != msg.sender) {
            revert SkyhuntersErrors.NotAgentCreator();
        }
        _;
    }

    modifier onlyVerifiedContract() {
        if (!accessControls.isVerifiedContract(msg.sender)) {
            revert SkyhuntersErrors.NotVerifiedContract();
        }
        _;
    }

    constructor(address payable _accessControls) payable {
        accessControls = SkyhuntersAccessControls(_accessControls);
        name = "SkyhuntersAgentManager";
        symbol = "SAM";
    }

    function createAgent(
        address[] memory wallets,
        address[] memory owners,
        string memory metadata
    ) external {
        _agentCounter++;

        _agents[_agentCounter].owners.add(msg.sender);

        for (uint8 i = 0; i < owners.length; i++) {
            _agents[_agentCounter].owners.add(owners[i]);
        }

        for (uint8 i = 0; i < wallets.length; i++) {
            _agents[_agentCounter].wallets.add(wallets[i]);
        }

        _agents[_agentCounter].id = _agentCounter;
        _agents[_agentCounter].metadata = metadata;
        _agents[_agentCounter].creator = msg.sender;
        _agents[_agentCounter].id = _agentCounter;

        for (uint8 i = 0; i < wallets.length; i++) {
            accessControls.addAgent(wallets[i]);
        }

        emit AgentCreated(wallets, msg.sender, _agentCounter);
    }

    function editAgent(
        string memory metadata,
        uint256 agentId
    ) external onlyAgentOwnerOrCreator(agentId) {
        _agents[agentId].metadata = metadata;

        emit AgentEdited(agentId);
    }

    function deleteAgent(
        uint256 agentId
    ) external onlyAgentOwnerOrCreator(agentId) {
        if (_agents[agentId].active > 0) {
            revert SkyhuntersErrors.AgentStillActive();
        }

        for (uint8 i = 0; i < _agents[agentId].wallets.length(); i++) {
            accessControls.removeAgent(_agents[agentId].wallets.at(i));
        }

        delete _agents[agentId];

        emit AgentDeleted(agentId);
    }

    function revokeOwner(
        address wallet,
        uint256 agentId
    ) public onlyAgentCreator(agentId) {
        _agents[agentId].owners.remove(wallet);
        emit RevokeOwner(wallet, agentId);
    }

    function addOwner(
        address wallet,
        uint256 agentId
    ) public onlyAgentCreator(agentId) {
        _agents[agentId].owners.add(wallet);
        emit AddOwner(wallet, agentId);
    }

    function revokeAgentWallet(
        address wallet,
        uint256 agentId
    ) public onlyAgentOwnerOrCreator(agentId) {
        _agents[agentId].wallets.remove(wallet);
        accessControls.removeAgent(wallet);

        emit RevokeAgentWallet(wallet, agentId);
    }

    function addAgentWallet(
        address wallet,
        uint256 agentId
    ) public onlyAgentOwnerOrCreator(agentId) {
        _agents[agentId].wallets.add(wallet);
        accessControls.addAgent(wallet);
        emit AddAgentWallet(wallet, agentId);
    }

    function scoreAgent(
        uint256 agentId,
        uint256 score,
        bool positive
    ) public onlyAgentOwnerOrCreator(agentId) {
        if (score > 1) {
            revert SkyhuntersErrors.InvalidScore();
        }

        if (positive) {
            _agents[agentId].scorePositive += score;
        } else {
            _agents[agentId].scoreNegative += score;
        }

        emit AgentScored(msg.sender, agentId, score, positive);
    }

    function setAgentActive(uint256 agentId) public onlyVerifiedContract {
        _agents[agentId].active += 1;

        emit AgentSetActive(msg.sender, agentId);
    }

    function setAgentInactive(uint256 agentId) public onlyVerifiedContract {
        _agents[agentId].active -= 1;

        emit AgentSetInactive(msg.sender, agentId);
    }

    function getAgentCounter() public view returns (uint256) {
        return _agentCounter;
    }

    function getAgentWallets(
        uint256 agentId
    ) public view returns (address[] memory) {
        return _agents[agentId].wallets.values();
    }

    function getAgentMetadata(
        uint256 agentId
    ) public view returns (string memory) {
        return _agents[agentId].metadata;
    }

    function getAgentScorePositive(
        uint256 agentId
    ) public view returns (uint256) {
        return _agents[agentId].scorePositive;
    }

    function getAgentScoreNegative(
        uint256 agentId
    ) public view returns (uint256) {
        return _agents[agentId].scoreNegative;
    }

    function getAgentOwners(
        uint256 agentId
    ) public view returns (address[] memory) {
        return _agents[agentId].owners.values();
    }

    function getAgentActive(uint256 agentId) public view returns (uint256) {
        return _agents[agentId].active;
    }

    function getAgentCreator(uint256 agentId) public view returns (address) {
        return _agents[agentId].creator;
    }

    function getIsAgentWallet(
        address wallet,
        uint256 agentId
    ) public view returns (bool) {
        return _agents[agentId].wallets.contains(wallet);
    }

    function getIsAgentOwner(
        address owner,
        uint256 agentId
    ) public view returns (bool) {
        return _agents[agentId].owners.contains(owner);
    }

    function setAccessControls(
        address payable _accessControls
    ) external onlyAdmin {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }
}
