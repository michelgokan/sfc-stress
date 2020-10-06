const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');
let loadash = require('lodash');

async function executeMemWorkload(dataSize) {
    const onemb = require('./payload/onemb');

    let bigStrArray = [];
    for (let i = 0; i < dataSize; i++) {
        bigStrArray.push(loadash.cloneDeep(onemb));
    }

    return await new Promise(resolve => setTimeout(resolve, 2000));
}

if (!isMainThread) {
    let result = executeMemWorkload(workerData.paramValue);
    parentPort.postMessage(result)
} else {
    module.exports = {
        executeMemWorkload: executeMemWorkload
    };
}