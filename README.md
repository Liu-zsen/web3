## Try to Hack Vault 

Read the smart contract `Vault.sol`, try to steal all eth from the vault.

You can write a hacker contract and add some code to pass the `forge test` .

### Tips 
you need understand following knowledge points:
1. reentrance 
2. ABI encoding
3. delegatecall
 

### Anvil

```shell
$ anvil
```

### Deploy

```shell
forge script script/Vault.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

## test

```
forge test -vvv
```

## 分析
```
    分析一下这个智能合约系统和可能的攻击方式。
    这个系统包含两个主要合约：
    VaultLogic - 包含所有者管理逻辑
    Vault - 主要的资金存储合约，使用 delegatecall 调用 VaultLogic
    通过分析，我发现几个关键点：
    Vault 合约使用 delegatecall 调用 VaultLogic，这可能导致状态变量布局问题
    VaultLogic 和 Vault 的状态变量布局不一致，这是一个潜在的漏洞
    要提取资金，需要先成为 owner 并调用 openWithdraw
    攻击思路：
    利用 delegatecall 和状态变量布局不一致的漏洞来修改 owner
    成为 owner 后开启提款
    提取所有资金

```
## 攻击原理
```
    漏洞点：
        Vault 合约通过 delegatecall 调用 VaultLogic 合约
        两个合约的状态变量布局不同：
        VaultLogic: owner, password
        Vault: owner, logic, deposites, canWithdraw
        当通过 delegatecall 调用 changeOwner 时，实际上会修改 Vault 合约的状态变量
    攻击步骤：
        创建 AttackVault 合约，在构造函数中：
            构造一个任意的 password (因为在 delegatecall 时，会读取 Vault 合约的 logic 变量作为 password)
            调用 changeOwner 函数，通过 delegatecall 将攻击者地址设为新的 owner
        成为 owner 后：
            调用 openWithdraw 开启提款
            存入一些资金（因为 withdraw 函数检查 deposites 余额）
            调用 withdraw 提取所有资金
    为什么这个攻击有效：
        delegatecall 在目标合约的上下文中执行代码
        状态变量布局不一致导致 password 检查可以被绕过
        一旦成为 owner，就可以开启提款并提取所有资金
    你现在可以运行 forge test 来验证这个攻击是否成功。测试应该能通过，因为我们成功清空了合约中的所有资金。

```