// const req           = require("express");
// const express       = require("express");
// const addresses = "http://127.0.0.1:30005/workload/mem,http://127.0.0.1:30005/workload/cpu";
const addresses  = process.env.NEXT_SERVICES_ADDRESSES;
const addressesCount = addresses.split(',').length;
const cpuWorkload = require('./cpu-workload');
const netWorkload = require('./net-workload');
const memWorkload = require('./mem-workload');
const blkioWorkload = require('./blkio-workload');
const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');

function getParameter(req, name, defaultValue = 1) {
    let param;
    if (req === undefined || req.params === undefined || req.params[name] === undefined)
        param = defaultValue;
    else
        param = req.params[name];

    return param;
}

function generatePromises(paramValue, threadsCount, filePath, func) {
    let promises = [];
    if (threadsCount === 1) {
        promises.push(new Promise((resolve, reject) => {
            func(paramValue);
            resolve({paramValue: paramValue, threadsCount: threadsCount});
        }));
    } else {
        for (let i = 0; i < threadsCount; i++) {
            let worker = new Worker(filePath, {workerData: {paramValue: paramValue}});
            promises.push(new Promise((resolve, reject) => {
                worker.on('exit', () => {
                    resolve({paramValue: paramValue, threadsCount: threadsCount});
                });
                worker.on('error', (err) => {
                    reject(err)
                });
            }));
        }
    }

    return promises;
}

function getReturnPromises(promises, req, sendToNext) {
    let allPromises = Promise.all(promises);
    if (sendToNext) {
        return allPromises.then((response) => {
            try {
                module.exports.networkIntensiveWorkload(req, false, true);
            } catch (e) {
                return Promise.reject(e);
            }
            return response;
        });
    } else {
        return allPromises;
    }
}

module.exports = {
    networkIntensiveWorkload: function (req = undefined, isPromised = false, isEmptyRequest = false) {
        let payloadSize = isEmptyRequest ? 0 : getParameter(req, 'payloadSize');

        if (addresses === "") return 0;

        if (!isPromised) {
            console.log("/net called!");
            let result = netWorkload.executeNetWorkload(payloadSize, req, isPromised);
            return "Transmitted " + payloadSize + "MB x " + addressesCount + " = " + payloadSize * addressesCount + "MB of data from " + req.protocol + "://" + req.get('host') + req.originalUrl + " to [" + addresses + "]  using 1 thread!"
        } else {
            let result = netWorkload.executePromisedNetWorkload(payloadSize);
            return result;
        }
    },
    CPUIntensiveWorkload: function (req = undefined) {
        console.log("/cpu called!");
        let workloadSize = getParameter(req, 'workloadSize'),
            threadsCount = getParameter(req, 'threadsCount'),
            sendToNext = getParameter(req, 'sendToNext', false);

        if (workloadSize === 0 || threadsCount === 0) return 0;

        let promises = generatePromises(workloadSize, threadsCount, "./cpu-workload.js", cpuWorkload.executeCPUWorkload);
        return getReturnPromises(promises, req, sendToNext);
    },
    memoryIntensiveWorkload: function (req = undefined) {
        console.log("/mem called!");
        let dataSize = getParameter(req, 'dataSize'),
            threadsCount = getParameter(req, 'threadsCount'),
            sendToNext = getParameter(req, 'sendToNext', false);

        if (dataSize === 0 || threadsCount === 0) return 0;

        let promises = generatePromises(dataSize, threadsCount, "./mem-workload.js", memWorkload.executeMemWorkload)
        return getReturnPromises(promises, req, sendToNext);
    },
    blkioIntensiveWorkload: function (req = undefined) {
        console.log("/blkio called!");
        let fileSize = getParameter(req, 'fileSize'),
            threadsCount = getParameter(req, 'threadsCount'),
            sendToNext = getParameter(req, 'sendToNext', false);

        if (fileSize === 0 || threadsCount === 0) return 0;

        let promises = generatePromises(fileSize, threadsCount, "./blkio-workload.js", blkioWorkload.executeBlkioWorkload)
        return getReturnPromises(promises, req, sendToNext);
    },
    combinedWorkload: function (req) {
        $a = this.CPUIntensiveWorkload(req);
        $b = this.memoryIntensiveWorkload(req);
        $c = this.blkioIntensiveWorkload(req);
        $d = this.networkIntensiveWorkload(req);

        return "OK";
    }
}
;
