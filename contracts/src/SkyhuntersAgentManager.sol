// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.24;

import "./SkyhuntersAccessControls.sol";
import "./SkyhuntersLibrary.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SkyhuntersAgentManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private _agentCounter;
    string public symbol;
    string public name;
    SkyhuntersAccessControls public accessControls;
    mapping(uint256 => SkyhuntersLibrary.Agent) private _agents;
    mapping(address => mapping(uint256 => bool)) private _isOwner;
    mapping(address => mapping(uint256 => bool)) private _isWallet;

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
            !_isOwner[msg.sender][agentId] &&
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

        for (uint8 i = 0; i < owners.length; i++) {
            _isOwner[owners[i]][_agentCounter] = true;
        }

        for (uint8 i = 0; i < wallets.length; i++) {
            _isWallet[wallets[i]][_agentCounter] = true;
        }

        _isOwner[msg.sender][_agentCounter] = true;

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

        for (uint8 i = 0; i < _agents[agentId].agentWallets.length(); i++) {
            accessControls.removeAgent(_agents[agentId].agentWallets.at(i));

            _isWallet[_agents[agentId].agentWallets.at(i)][agentId] = false;
        }

        for (uint8 i = 0; i < _agents[agentId].owners.length(); i++) {
            _isOwner[_agents[agentId].owners.at(i)][agentId] = false;
        }

        delete _agents[agentId];

        emit AgentDeleted(agentId);
    }

    function revokeOwner(
        address wallet,
        uint256 agentId
    ) public onlyAgentCreator(agentId) {
        _agents[agentId].owners.remove(wallet);
        _isOwner[wallet][agentId] = false;
        emit RevokeOwner(wallet, agentId);
    }

    function addOwner(
        address wallet,
        uint256 agentId
    ) public onlyAgentCreator(agentId) {
        _agents[agentId].owners.add(wallet);
        _isOwner[wallet][agentId] = true;
        emit AddOwner(wallet, agentId);
    }

    function revokeAgentWallet(
        address wallet,
        uint256 agentId
    ) public onlyAgentOwnerOrCreator(agentId) {
        _agents[agentId].agentWallets.remove(wallet);
        _isWallet[wallet][agentId] = false;
        accessControls.removeAgent(wallet);

        emit RevokeAgentWallet(wallet, agentId);
    }

    function addAgentWallet(
        address wallet,
        uint256 agentId
    ) public onlyAgentOwnerOrCreator(agentId) {
        _agents[agentId].agentWallets.add(wallet);
        _isWallet[wallet][agentId] = true;
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
        return _agents[agentId].agentWallets.values();
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

    function getAgentCreator(uint256 agentId) public view returns (address) {
        return _agents[agentId].creator;
    }

    function getIsAgentWallet(
        address wallet,
        uint256 agentId
    ) public view returns (bool) {
        return _isWallet[wallet][agentId];
    }

    function getIsAgentOwner(
        address owner,
        uint256 agentId
    ) public view returns (bool) {
        return _isOwner[owner][agentId];
    }

    function setAccessControls(
        address payable _accessControls
    ) external onlyAdmin {
        accessControls = SkyhuntersAccessControls(_accessControls);
    }
}
