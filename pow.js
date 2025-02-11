// crypto : node 内置计算sha256 Hash的方法
const crypto = require('crypto');

function powProofOfWork(prefixZeros) {
    // 记录开始时间
    const startTime = Date.now();
    // 从0 开始递增 尝试不同的 nonce值
    let nonce = 0;
    while (true) {
        const inputString = "Jason" + nonce;
        const hashValue = crypto.createHash('sha256').update(inputString).digest('hex');
        // 检查哈希是否以指定数量的 0 开头
        if (hashValue.startsWith('0'.repeat(prefixZeros))) {
            const endTime = Date.now();
            console.log(`查找以 ${prefixZeros} 开头的哈希值:`);
            console.log(`花费时间: ${(endTime - startTime) / 1000} seconds`);
            console.log(`Input string: ${inputString}`);
            console.log(`Hash value: ${hashValue}`);
            console.log();
            break;
        }
        nonce++;
    }
}

// 查找以 4 个 0 开头的哈希值
powProofOfWork(4);

// 查找以 5 个 0 开头的哈希值
powProofOfWork(5);