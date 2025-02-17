// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../bank/bank.sol";
/**
 * 
在 该挑战 的 Bank 合约基础之上，编写 IBank 接口及BigBank 合约，使其满足 Bank 实现 IBank， BigBank 继承自 Bank ， 同时 BigBank 有附加要求：
要求存款金额 >0.001 ether（用modifier权限控制）
BigBank 合约支持转移管理员
编写一个 Admin 合约， Admin 合约有自己的 Owner ，同时有一个取款函数 adminWithdraw(IBank bank) , adminWithdraw 中会调用 IBank 接口的 withdraw 方法从而把 bank 合约内的资金转移到 Admin 合约地址。
BigBank 和 Admin 合约 部署后，把 BigBank 的管理员转移给 Admin 合约地址，模拟几个用户的存款，然后
Admin 合约的Owner地址调用 adminWithdraw(IBank bank) 把 BigBank 的资金转移到 Admin 地址。
**/
contract BigBank is Bank {
    modifier minDeposit() {
        require(msg.value > 0.001 ether, "Deposit must be greater than 0.001 ether");
        _;
    }

    function deposit() public payable override minDeposit {
        // 调用父类的 deposit 方法
        super.deposit(); 
    }

}

/**
 * @title 调用 Admin 合约的 adminWithdraw 方法
 * 
    Admin 合约的 owner 调用 adminWithdraw，传入 BigBank 合约地址。
    Admin 合约会调用 BigBank 的 withdraw 方法，将资金转移到 Admin 合约。    
 */
contract Admin {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function adminWithdraw(IBank bank) external onlyOwner {
        uint256 bankBalance = address(bank).balance;
        require(bankBalance > 0, "Bank contract has no balance");

        // 调用 IBank 的 withdraw 方法，将资金转移到 Admin 合约
        bank.withdraw(bankBalance);
    }

    // 接收 ETH 的 fallback 函数
    receive() external payable {}
}