// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IBank.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract Bank is IBank, AutomationCompatibleInterface {
    address public admin;
    mapping(address => uint256) public balances;
    address[3] public topDepositors;
    
    // Chainlink Automation 相关变量
    uint256 public constant THRESHOLD = 0.2 ether; // 可自定义的阈值
    address public owner; // 接收转移资金的地址
    
    constructor(address _owner) {
        admin = msg.sender;
        owner = _owner;
    }

    receive() external payable {
        deposit();
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function deposit() public payable virtual {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external onlyAdmin {
        require(amount <= address(this).balance, "Insufficient contract balance");
        payable(admin).transfer(amount);
    }


    function getTopDepositors() external view returns (address[3] memory) {
        return topDepositors;
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be the zero address");
        admin = newAdmin;
    }

    // Chainlink Automation 检查函数
    function checkUpkeep(bytes calldata /* checkData */) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory performData) 
    {
        upkeepNeeded = address(this).balance > THRESHOLD;
        performData = abi.encode(address(this).balance / 2);
        return (upkeepNeeded, performData);
    }

    // Chainlink Automation 执行函数
    function performUpkeep(bytes calldata performData) external override {
        // 再次检查余额以确保安全性
        if (address(this).balance > THRESHOLD) {
            uint256 amountToTransfer = abi.decode(performData, (uint256));
            // 确保不超过当前余额
            if (amountToTransfer > address(this).balance) {
                amountToTransfer = address(this).balance;
            }
            // 转移一半存款给 owner
            payable(owner).transfer(amountToTransfer);
        }
    }
}