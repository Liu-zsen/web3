
// 题目: 实践非对称加密 RSA
// 先生成一个公私钥对
// 用私钥对符合 POW 4 个 0 开头的哈希值的 “昵称 + nonce” 进行私钥签名
// 用公钥验证

const crypto = require('crypto');

// 1. 生成 RSA 公私钥对
const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048, // 密钥长度
    publicKeyEncoding: {
        type: 'spki', // 公钥格式
        format: 'pem' // 编码格式
    },
    privateKeyEncoding: {
        type: 'pkcs8', // 私钥格式
        format: 'pem' // 编码格式
    }
});

console.log("公钥:");
console.log(publicKey);
console.log("私钥:");
console.log(privateKey);

// 2. 实现 POW 算法，找到符合 4 个 0 开头的哈希值
function powProofOfWork(prefixZeros) {
    let nonce = 0;
    while (true) {
        const inputString = "Jason" + nonce;
        const hashValue = crypto.createHash('sha256').update(inputString).digest('hex');
        if (hashValue.startsWith('0'.repeat(prefixZeros))) {
            console.log(`查找以 ${prefixZeros} 个0开头的哈希值:`);
            console.log(`Input string: ${inputString}`);
            console.log(`Hash value: ${hashValue}`);
            return inputString; // 返回符合条件的字符串
        }
        nonce++;
    }
}

// 找到符合 POW 条件的字符串
const powString = powProofOfWork(4);

// 3. 使用私钥对字符串进行签名
const signer = crypto.createSign('sha256');
signer.update(powString);
const signature = signer.sign(privateKey, 'hex'); // 生成签名

console.log("签名:");
console.log(signature);

// 4. 使用公钥验证签名
const verifier = crypto.createVerify('sha256');
verifier.update(powString);
const isVerified = verifier.verify(publicKey, signature, 'hex'); // 验证签名

console.log("签名验证结果:");
console.log(isVerified ? "验证成功" : "验证失败");