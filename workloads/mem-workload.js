const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');
const crypto = require("crypto");

function getRandomInt(max) {
    return Math.floor(Math.random() * Math.floor(max));
}

async function executeMemWorkload(dataSize) {
    let bigStrArray = [];
    for (let i = 0; i < dataSize; i++) {
        bigStrArray.push(crypto.randomBytes(1024 * 1024 / 2).toString('hex'));
    }

    return true; //await new Promise(resolve => setTimeout(resolve, 2000));
}

// async function executeMemWorkload(dataSize) {
//     let bigStrArray = [];
//     for (let i = 0; i < dataSize; i++) {
//         bigStrArray.push(0)
//     }
//
//     for (let j = 0; j < 100; j++) {
//         for (let i = 0; i < dataSize; i++) {
//             let _index = getRandomInt(dataSize);
//             if (bigStrArray[_index] === 0)
//                 bigStrArray[_index] = crypto.randomBytes(1024 * 1024).toString('hex');
//         }
//     }
//
//     return true; //await new Promise(resolve => setTimeout(resolve, 2000));
// }

if (!isMainThread) {
    let result = executeMemWorkload(workerData.paramValue);
    parentPort.postMessage(result)
} else {
    module.exports = {
        executeMemWorkload: executeMemWorkload
    };
}