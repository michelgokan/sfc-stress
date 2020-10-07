const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');
const crypto = require("crypto");

async function executeMemWorkload(dataSize) {
    const onemb = require('./payload/onemb');

    let bigStrArray = [];
    for (let i = 0; i < dataSize; i++) {
        bigStrArray.push(crypto.randomBytes(i * 1024).toString('hex'));
    }

    return true; //await new Promise(resolve => setTimeout(resolve, 2000));
}

if (!isMainThread) {
    let result = executeMemWorkload(workerData.paramValue);
    parentPort.postMessage(result)
} else {
    module.exports = {
        executeMemWorkload: executeMemWorkload
    };
}