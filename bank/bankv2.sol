// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./IBankv2.sol";

// 在bank合约基础增加可迭代的链表保存存款金额
contract Bank is IBank {
    address public admin;
    mapping(address => uint256) public balances;
    
    // 链表节点结构体
    struct Node {
        uint256 balance;  // 用户的存款余额
        address prev;     // 前一个节点的地址
        address next;     // 后一个节点的地址
    }
    
    // 用户地址到节点的映射
    mapping(address => Node) public nodes;
    address public head;  // 链表头部，指向存款最多的用户
    uint256 public topCount;  // 当前链表中的用户数量

    constructor() {
        admin = msg.sender;
        // 初始化链表为空
        head = address(0);  
        topCount = 0;
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

    // 更新前 10 名存款用户的链表
    function updateTopDepositors(address user) internal {
        // 如果用户已在链表中，先移除
        if (nodes[user].prev != address(0) || nodes[user].next != address(0) || head == user) {
            removeFromList(user);
        }

        // 找到插入位置
        address current = head;
        address previous = address(0);
        while (current != address(0) && balances[user] <= nodes[current].balance) {
            previous = current;
            current = nodes[current].next;
        }

        // 在 previous 之后插入用户
        insertAfter(previous, user, current);

        // 如果链表超过 10 个用户，移除最后一个（存款最小的）
        if (topCount > 10) {
            address last = getLast();
            removeFromList(last);
        }
    }

    // 从链表中移除用户
    function removeFromList(address user) internal {
        // 更新前一个节点的 next 指针
        if (nodes[user].prev != address(0)) {
            nodes[nodes[user].prev].next = nodes[user].next;
        } else {
            // 如果用户是头部，更新 head
            head = nodes[user].next;
        }

        // 更新后一个节点的 prev 指针
        if (nodes[user].next != address(0)) {
            nodes[nodes[user].next].prev = nodes[user].prev;
        }

        // 重置用户的节点信息
        nodes[user].prev = address(0);
        nodes[user].next = address(0);
        topCount--;
    }

    // 在指定位置插入用户
    function insertAfter(address previous, address user, address next) internal {
        nodes[user].prev = previous;
        nodes[user].next = next;
        nodes[user].balance = balances[user];  // 记录当前余额

        // 如果不是插入到头部，更新前一个节点的 next
        if (previous != address(0)) {
            nodes[previous].next = user;
        } else {
            head = user;
        }

        // 如果不是插入到尾部，更新后一个节点的 prev
        if (next != address(0)) {
            nodes[next].prev = user;
        }

        topCount++;
    }

    // 获取链表最后一个用户（存款最小的用户）
    function getLast() internal view returns (address) {
        address current = head;
        while (current != address(0) && nodes[current].next != address(0)) {
            current = nodes[current].next;
        }
        return current;
    }

    // 查询前 10 名存款用户
    function getTopDepositors() external view returns (address[10] memory) {
        address[10] memory topUsers;
        address current = head;
        uint256 count = 0;

        // 从头部遍历链表，最多 10 个用户
        while (current != address(0) && count < 10) {
            topUsers[count] = current;
            current = nodes[current].next;
            count++;
        }

        return topUsers;  // 未填充的部分默认为 address(0)
    }

    // 转移管理员权限
    function transferAdmin(address newAdmin) external override onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be the zero address");
        admin = newAdmin;
    }
}