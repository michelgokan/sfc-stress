const addresses = process.env.NEXT_SERVICES_ADDRESSES;
const cpuWorkload = require('./cpu-workload');
const netWorkload = require('./net-workload');
const memWorkload = require('./mem-workload');
const blkioWorkload = require('./blkio-workload');
const helper = require('./helper');

module.exports = {
    networkIntensiveWorkload: function (req = undefined, isEmptyRequest = false, optionalPayloadSize = undefined) {
        let isPromised = helper.getParameter(req, 'isPromised', false);

        let payloadSize;
        if (isEmptyRequest)
            payloadSize = 0;
        else if (optionalPayloadSize === undefined || optionalPayloadSize === -1)
            payloadSize = helper.getParameter(req, 'payloadSize', 1);
        else
            payloadSize = optionalPayloadSize;

        if (!helper.isAddressesAvailable(addresses))
            return Promise.reject("Nothing executed!");
        else {
            let result = netWorkload.executeNetWorkload(payloadSize, req, isPromised);
            return [isPromised, result];
        }
    },
    CPUIntensiveWorkload: function (req = undefined, sendToNext = undefined) {
        let workloadSize = helper.getParameter(req, 'workloadSize'),
            threadsCount = helper.getParameter(req, 'threadsCount'),
            payloadSize = helper.getParameter(req, 'payloadSize', -1);

        sendToNext = sendToNext == undefined ? helper.getParameter(req, 'sendToNext', false) > 0 : sendToNext;

        if (workloadSize == 0 || threadsCount == 0) return Promise.reject("Nothing executed!");

        let promises = helper.generatePromises(workloadSize, threadsCount, "./workloads/cpu-workload.js", cpuWorkload.executeCPUWorkload);
        return helper.getReturnPromises(promises, req, sendToNext, payloadSize, this.networkIntensiveWorkload);
    },
    memoryIntensiveWorkload: function (req = undefined, sendToNext = undefined) {
        let dataSize = helper.getParameter(req, 'dataSize'),
            threadsCount = helper.getParameter(req, 'threadsCount'),
            payloadSize = helper.getParameter(req, 'payloadSize', -1);

        sendToNext = sendToNext == undefined ? helper.getParameter(req, 'sendToNext', false) > 0 : sendToNext;

        if (dataSize == 0 || threadsCount == 0) return Promise.reject("Nothing executed!");

        let promises = helper.generatePromises(dataSize, threadsCount, "./workloads/mem-workload.js", memWorkload.executeMemWorkload)
        return helper.getReturnPromises(promises, req, sendToNext, payloadSize, this.networkIntensiveWorkload);
    },
    blkioIntensiveWorkload: function (req = undefined, sendToNext = undefined) {
        let fileSize = helper.getParameter(req, 'fileSize'),
            threadsCount = helper.getParameter(req, 'threadsCount'),
            payloadSize = helper.getParameter(req, 'payloadSize', -1);

        sendToNext = sendToNext == undefined ? helper.getParameter(req, 'sendToNext', false) > 0 : sendToNext;

        if (fileSize == 0 || threadsCount == 0) return Promise.reject("Nothing executed!");

        let promises = helper.generatePromises(fileSize, threadsCount, "./workloads/blkio-workload.js", blkioWorkload.executeBlkioWorkload)
        return helper.getReturnPromises(promises, req, sendToNext, payloadSize, this.networkIntensiveWorkload);
    },
    runAll: function (req) {
        let sendToNext = helper.getParameter(req, 'sendToNext', false) > 0,
            cpu = this.CPUIntensiveWorkload(req, false),
            mem = this.memoryIntensiveWorkload(req, false),
            blkio = this.blkioIntensiveWorkload(req, false);

        return [sendToNext, [cpu, mem, blkio]];
    }
};
