const crypto = require('crypto');
const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');

function checksum(str, algorithm, encoding) {
    return crypto
        .createHash(algorithm || 'md5')
        .update(str, 'utf8')
        .digest(encoding || 'hex');
}

function executeCPUWorkload(workloadSize) {
    console.log("Workload size: " + workloadSize);
    for (let $i = 0; $i < workloadSize; $i++) {
        const prime_length = 100;
        const diffHell = crypto.createDiffieHellman(prime_length);
        const key = diffHell.generateKeys('base64');
        checksum(key);
    }

    return true;
}

if (!isMainThread) {
    let result = executeCPUWorkload(workerData.paramValue);
    parentPort.postMessage(result)
} else {
    module.exports = {
        executeCPUWorkload: executeCPUWorkload
    };
}