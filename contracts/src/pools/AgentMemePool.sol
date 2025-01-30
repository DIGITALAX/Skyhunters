// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./IPool.sol";

contract AgentMemePool is IPool {
    address public owner;
    uint256 public totalPoolBalance;
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public rewardsRating;

    event Deposited(address indexed sender, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el owner puede ejecutar esto");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function depositToPool(uint256 amount) external override {
        totalPoolBalance += amount;
        emit Deposited(msg.sender, amount);
    }

    function getUserRewards(
        address user
    ) external view override returns (uint256) {
        uint256 userScore = rewardsRating[user];
        return (totalPoolBalance * userScore) / 100;
    }

    function claimRewards() external override {
        uint256 userScore = rewardsRating[msg.sender];
        require(userScore > 0, "No tienes acceso a recompensas");

        uint256 reward = (totalPoolBalance * userScore) / 100;
        require(reward > 0, "Sin recompensas disponibles");

        totalPoolBalance -= reward;
        rewardsRating[msg.sender] = 0; 
        payable(msg.sender).transfer(reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function setRewardsRating(address user, uint256 score) external onlyOwner {
        require(score <= 100, "Puntaje fuera de rango");
        rewardsRating[user] = score;
    }

    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount <= totalPoolBalance, "Fondos insuficientes");
        totalPoolBalance -= amount;
        payable(owner).transfer(amount);
    }

    receive() external payable {
        totalPoolBalance += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}
