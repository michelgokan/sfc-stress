const crypto = require('crypto');
const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');

function checksum(str, algorithm, encoding) {
    return crypto
        .createHash(algorithm || 'md5')
        .update(str, 'utf8')
        .digest(encoding || 'hex');
}

function executeCPUWorkload(workloadSize) {
    for (let $i = 0; $i < workloadSize; $i++) {
        const prime_length = 100;
        console.log("Before calling createDiffieHellman with prime_length= " + prime_length);
        const diffHell = crypto.createDiffieHellman(prime_length);
        console.log("Before calling generateKeys - diffHell= " + diffHell);
        const key = diffHell.generateKeys('base64');
        console.log("Before calling checksum - key= " + key);
        const chksum = checksum(key);
        console.log("After calling checksum - checksum= " + chksum);
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