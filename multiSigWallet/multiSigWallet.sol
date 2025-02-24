// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    address[] public owners;
    uint256 public requiredSignatures;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    mapping(uint256 => mapping(address => bool)) public confirmations;
    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not an owner");
        _;
    }
    // 在部署时指定 owners（多签持有人）和 requiredSignatures（门槛）。
    // _owners: ["0x123...", "0x456...", "0x789..."] ; _requiredSignatures（多签门槛: 2/3 就填 2）。
    constructor(address[] memory _owners, uint256 _requiredSignatures) {
        require(_owners.length > 0, "Owners required");
        require(
            _requiredSignatures > 0 && _requiredSignatures <= _owners.length,
            "Invalid required signatures"
        );
        owners = _owners;
        requiredSignatures = _requiredSignatures;
    }

    function isOwner(address account) public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == account) {
                return true;
            }
        }
        return false;
    }
    // 提交交易提案: 由持有人调用，创建一个待执行交易
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner {
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                confirmations: 0
            })
        );
    }
    // 确认提案: 只有持有者调用 confirmTransaction 提交交易确认。 其他持有人可以对交易提案进行确认，达到门槛后可执行
    function confirmTransaction(uint256 _txIndex) public onlyOwner {
        require(_txIndex < transactions.length, "Invalid transaction index");
        require(!transactions[_txIndex].executed, "Transaction already executed");
        require(!confirmations[_txIndex][msg.sender], "Already confirmed");

        confirmations[_txIndex][msg.sender] = true;
        transactions[_txIndex].confirmations++;
    }

    // 达到多签⻔槛: 任何人都可以执行交易，只要确认数满足 requiredSignatures
    function executeTransaction(uint256 _txIndex) public {
        require(_txIndex < transactions.length, "Invalid transaction index");
        Transaction storage transaction = transactions[_txIndex];

        require(!transaction.executed, "Transaction already executed");
        require(transaction.confirmations >= requiredSignatures, "Not enough confirmations");

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction execution failed");
    }

    receive() external payable {}
}
