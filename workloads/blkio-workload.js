const fs = require('fs');

const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');

function getRandomInt(max) {
    return Math.floor(Math.random() * Math.floor(max));
}

function executeBlkioWorkload(fileSize) {
    const file_suffix = getRandomInt(99999999);
    const file_name = "/tmp/test" + file_suffix;
    const onemb = require('./payload/onemb');

    for (let i = 0; i < fileSize; i++) {
        fs.appendFileSync(file_name, onemb);
    }
    fs.unlinkSync(file_name);

    return fileSize;
}

if (!isMainThread) {
    let result = executeBlkioWorkload(workerData.paramValue);
    parentPort.postMessage(result)
} else {
    module.exports = {
        executeBlkioWorkload: executeBlkioWorkload
    };
}