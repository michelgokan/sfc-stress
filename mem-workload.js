const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');

function executeMemWorkload(dataSize) {
    const onemb = require('./onemb');

    let bigStrArray = [];
    for (let i = 0; i < dataSize; i++) {
        bigStrArray.push(onemb);
    }

    return true;
}

if (!isMainThread) {
    let result = executeMemWorkload(workerData.paramValue);
    parentPort.postMessage(result)
} else {
    module.exports = {
        executeMemWorkload: executeMemWorkload
    };
}