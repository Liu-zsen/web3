// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    编写一个 Bank 合约，实现功能：
    可以通过 Metamask 等钱包直接给 Bank 合约地址存款
    在 Bank 合约记录每个地址的存款金额
    编写 withdraw() 方法，仅管理员可以通过该方法提取资金。
    用数组记录存款金额的前 3 名用户
**/
contract Bank {
    address public admin;
    mapping(address => uint256) public balances;
    address[3] public topDepositors;

    constructor() {
        admin = msg.sender;
    }

    receive() external payable {
        deposit();
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    // 用户可以通过 deposit() 函数向合约地址发送 ETH
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        updateTopDepositors(msg.sender);
    }

    // 仅限管理员提取资金
    function withdraw(uint256 amount) external onlyAdmin {
        // 合同余额不足 
        require(amount <= address(this).balance, "Insufficient contract balance");

        payable(admin).transfer(amount);
    }

    // 更新前 3 名的存款逻辑
    function updateTopDepositors(address depositor) internal {
        uint256 depositorBalance = balances[depositor];

        for (uint256 i = 0; i < 3; i++) {
            if (topDepositors[i] == depositor) return;

            if (depositorBalance > balances[topDepositors[i]]) {
                // 移动数组并插入新的存款
                for (uint256 j = 2; j > i; j--) {
                    topDepositors[j] = topDepositors[j - 1];
                }
                topDepositors[i] = depositor;
                return;
            }
        }
    }

    // 查询前 3 名存款用户。
    function getTopDepositors() external view returns (address[3] memory) {
        return topDepositors;
    }
}