const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');
const addresses = "http://127.0.0.1:30005/workload/mem,http://127.0.0.1:30005/workload/cpu";
// const addresses  = process.env.NEXT_SERVICES_ADDRESSES;
const http = require("http")
const urlToOptions = require("url-to-options");
const url = require("url");

function getRequestOptions(address, payloadSize) {
    let url_object = new url.URL(address);
    let options = urlToOptions(url_object);
    options.method = "POST";
    options.headers = {
        'Keep-Alive': "max=" + payloadSize
    };
    return options;
}

function sendRequest(address, payloadSize) {
    let options = getRequestOptions(address, payloadSize);
    const req = http.request(options);
    const onemb = require('./onemb');

    for (let i = 0; i < payloadSize; i++) {
        req.write(JSON.stringify({
            data: onemb
        }));
    }

    req.end();

    return req;
}

function promisedSendRequest(address, payloadSize) {
    return new Promise(function (resolve, reject) {
        try {
            let options = getRequestOptions(address, payloadSize);

            const req = http.request(options, (res) => {
                // console.log(`statusCode: ${res.statusCode}`);
                let body = [];
                res.on('data', (chunk) => {
                    console.log(chunk);
                    body.push(chunk);
                });
                res.on('end', function () {
                    let result = Buffer.concat(body).toString();
                    resolve(result);
                });
            });
            req.on('error', (error) => {
                reject(error);
            });

            if(payloadSize !== 0) {
                const data = require('./onemb');

                for (let i = 0; i < payloadSize; i++) {
                    req.write(JSON.stringify({
                        data: data
                    }));
                }
                req.shouldKeepAlive = true;
            }
            req.end();
        } catch (e) {
            reject(e);
        }
    });
}

function executeNetWorkload(payloadSize, req, isPromised = false) {
    let splittedAddresses = addresses.split(",");
    let requests = [];
    for (let address of splittedAddresses) {
        // promises.push(sendRequest(address))
        try {
            if (!isPromised) {
                requests.push(sendRequest(address, payloadSize));
            } else {
                requests.push(promisedSendRequest(address, payloadSize));
            }
        } catch (e) {
            return e;
        }
    }

    // return "Transmitted " + payloadSize + "MB x " + splittedAddresses.length + " destinations = " + payloadSize * splittedAddresses.length + "MB of data from " + req.protocol + "://" + req.get('host') + req.originalUrl + " to [" + addresses + "]  using 1 thread!"
    // return 1;
    return requests;
}

function executePromisedNetWorkload(payloadSize) {
    let splittedAddresses = addresses.split(",");
    let promises = [];
    for (let address of splittedAddresses) {
        promises.push(promisedSendRequest(address, payloadSize));
    }

    return Promise.all(promises);
}

if (!isMainThread) {
    let result = executeNetWorkload(workerData.paramValue);
    parentPort.postMessage(result)
} else {
    module.exports = {
        executeNetWorkload: executeNetWorkload,
        executePromisedNetWorkload: executePromisedNetWorkload
    };
}