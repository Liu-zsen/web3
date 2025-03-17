// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./IBank.sol";

/**
    编写一个 Bank 合约，实现功能：
    可以通过钱包直接给 Bank 合约地址存款
    在 Bank 合约记录每个地址的存款金额
    编写 withdraw() 方法，仅管理员可以通过该方法提取资金。
    用数组记录存款金额的前 3 名用户
**/
contract Bank is IBank{
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
    function deposit() public payable virtual{
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

        // 如果存款人已经在 top 3 中，直接返回
        // 如果当前存款人的余额大于 topDepositors[i] 的余额
        for (uint256 i = 0; i < 3; i++) {
            if (topDepositors[i] == depositor) return;

            if (depositorBalance > balances[topDepositors[i]]) {
                // 将数组从 i 开始向后移位，为新存款人腾出位置
                for (uint256 j = 2; j > i; j--) {
                    topDepositors[j] = topDepositors[j - 1];
                }
                // 将新存款人插入到正确的位置
                topDepositors[i] = depositor;
                return;
            }
        }
    }

    // 查询前 3 名存款用户。
    function getTopDepositors() external view returns (address[3] memory) {
        return topDepositors;
    }

    // 将管理员地址设置为 Admin 合约地址。
    function transferAdmin(address newAdmin) external override onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be the zero address");
        admin = newAdmin;
    }
}