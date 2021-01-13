const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');

module.exports = {
    getParameter: function (req, name, defaultValue = 1) {
        let param;
        if (req === undefined || req.params === undefined || req.params[name] === undefined)
            param = defaultValue;
        else
            param = req.params[name];

        return param;
    },
    generatePromises: function (paramValue, threadsCount, filePath, func) {
        let promises = [];
        if (parseInt(threadsCount) === 1) {
            promises.push(new Promise((resolve, reject) => {
                Promise.resolve(func(paramValue)).then(function (value) {
                    resolve({paramValue: paramValue, threadsCount: threadsCount});
                });
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
    },
    getReturnPromises: function (promises, req, sendToNext, payloadSize, sendToNextFunc) {
        let allPromises = Promise.all(promises);
        if (sendToNext) {
            return allPromises.then((response) => {
                let result;
                try {
                    result = sendToNextFunc(req, payloadSize < 1, payloadSize);
                } catch (e) {
                    return Promise.reject(e);
                }
                if (Array.isArray(result) && result.length == 2) {
                    let promiseArray = [[response], result[1]];
                    return Promise.all(
                        promiseArray.map(function (innerPromiseArray) {
                            return Promise.all(innerPromiseArray);
                        })
                    );
                } else {
                    return response;
                }
            });
        } else {
            return allPromises;
        }
    },
    getDurationInMilliseconds: function (start) {
        const NS_PER_SEC = 1e9;
        const NS_TO_MS = 1e6;
        const diff = process.hrtime(start);

        return (diff[0] * NS_PER_SEC + diff[1]) / NS_TO_MS;
    },
    isAddressesJSONAvailable: function (addresses) {
        return addresses !== undefined && addresses != null && addresses.trim() !== "";
    }
}