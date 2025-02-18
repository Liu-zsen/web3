// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./tokenBank.sol";

// 目标合约需要实现的接口
interface ITokenReceiver {
    function tokensReceived(address sender, uint256 amount) external returns (bool);
}

/**
扩展 ERC20 合约 ，添加一个有hook 功能的转账函数，如函数名为：transferWithCallback,
在转账时，如果目标地址是合约地址的话，调用目标地址的 tokensReceived() 方法。
**/
contract ERC20WithCallback is MyToken {
    constructor(uint256 initialSupply) MyToken(initialSupply) { }
    // 带回调的转账函数
    function transferWithCallback(address recipient, uint256 amount) external returns (bool) {
        // 转账
        bool success = transfer(recipient, amount);
        require(success, "Transfer failed");

        // 如果目标地址是合约，调用其 tokensReceived 方法
        if (isContract(recipient)) {
            bool callbackSuccess = ITokenReceiver(recipient).tokensReceived(msg.sender, amount);
            require(callbackSuccess, "Callback failed");
        }
        return true;
    }

    // 检查地址是否为合约
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

/**
继承 TokenBank 编写 TokenBankV2，支持存入扩展的 ERC20 Token，
用户可以直接调用 transferWithCallback 将 扩展的 ERC20 Token 存入到 TokenBankV2 中
**/
contract TokenBankV2 is TokenBank ,ITokenReceiver {
    // 初始化时设置 Token 合约地址 并调用 TokenBank 的构造函数
    constructor(address _tokenAddress) TokenBank(_tokenAddress) {
        tokenAddress = _tokenAddress;
    }
    
    function tokensReceived(address sender, uint256 amount) external override returns (bool) {
        require(msg.sender == address(tokenAddress),"Invaild Token");
        // 记录用户的存款
        balances[tokenAddress][sender] += amount;
        return true;
    }
}



