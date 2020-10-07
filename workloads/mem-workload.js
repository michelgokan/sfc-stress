const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');
// let loadash = require('lodash');
const execSync = require('child_process').execSync;

async function executeMemWorkload(dataSize) {
    // const onemb = require('./payload/onemb');

    // let bigStrArray = [];
    // for (let i = 0; i < dataSize; i++) {
    return execSync('stress-ng --vm-bytes 4294967296 --vm 1 --vm-ops 100000', {stdio: 'pipe'});
    // return cmd.get('stress-ng --vm-bytes 4294967296 --vm 1 --vm-ops 100000');
    // bigStrArray.push(loadash.cloneDeep(onemb));
    // }

    // return await new Promise(resolve => setTimeout(resolve, 2000));
}

if (!isMainThread) {
    let result = executeMemWorkload(workerData.paramValue);
    parentPort.postMessage(result)
} else {
    module.exports = {
        executeMemWorkload: executeMemWorkload
    };
}