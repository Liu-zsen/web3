// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBank {
    // 存款
    function deposit() external payable;
    // 取款
    function withdraw(uint256 amount) external;

    // 前三存款排名
    function getTopDepositors() external view returns (address[10] memory);

    // 将管理员地址设置为 Admin 合约地址。
    function transferAdmin(address newAdmin) external;
}