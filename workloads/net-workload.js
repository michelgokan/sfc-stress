const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');
const addresses = process.env.NEXT_SERVICES_ADDRESSES;
const name = process.env.NAME === undefined ? "undefined" : process.env.NAME;
const http = require("http");
const helper = require("./helper");
const urlToOptions = require("url-to-options");
const url = require("url");
const FormData = require('form-data');
const fs = require('fs');
const now = require('nano-time');

function getRequestOptions(address, payloadSize) {
    let url_object = new url.URL(address);
    let options = urlToOptions(url_object);
    options.method = "POST";
    return options;
}

// payloadSize is in MB
function getForm(payloadSize) {
    const form = new FormData();
    if (payloadSize) {
        const readStream = fs.createReadStream('./workloads/payload/100MB.zip', {start: 0, end: payloadSize * 1000 * 1000});
        console.log("Read from byte 0 to byte " + payloadSize);
        form.append('data', readStream);
    } else {
        console.log("No payload size specified");
    }

    return form;
}

function sendRequest(address, payloadSize) {
    console.log("Calling sendRequest");
    let options = getRequestOptions(address, payloadSize);
    const form = getForm(payloadSize);
    options.headers = form.getHeaders();
    const req = http.request(options).setTimeout(9999999999999999999999999999999999);

    // req.on('connect', (res, socket, head) => {
    //     console.log(`CONNECT - ${name} connected to ${address} at {${now()}}`);
    // });

    req.on('error', (error) => {
        if (error.code !== "EPIPE") {
            console.error(error);
            throw error;
        } else {
            // console.error("EPIPE Error! Looks harmless :-)");
        }
    });
    req.on('finish', () => {
        console.log(`SENT - ${name} sent a ${req.method} request to ${address} at {${now()}}`);
    });

    // req.on('end', () => {
    //     console.log(`END - ${name} sent a ${req.method} request to ${address} at {${now()}}`);
    // });

    form.pipe(req);
    return req;
}

function promisedSendRequest(address, payloadSize) {
    return new Promise(function (resolve, reject) {
        try {
            let options = getRequestOptions(address, payloadSize);
            const form = getForm(payloadSize);
            options.headers = form.getHeaders();
            const req = http.request(options, (res) => {
                let body = [];
                res.on('data', (chunk) => {
                    body.push(chunk);
                }).setTimeout(2147483647);
                res.on('end', function () {
                    let result = Buffer.concat(body).toString();
                    console.log("Received " + res.method + " response from " + address + " [REQUEST END]");
                    resolve(result);
                });
                res.on('error', (e) => {
                    reject(e);
                });
            });

            form.pipe(req);
            req.on('error', (error) => {
                reject(error);
            });
            req.on('finish', () => console.log("SENT - " + name + " sent a " + req.method + " request to " + address));
        } catch (e) {
            reject(e);
        }
    });
}

function executeNetWorkload(payloadSize, req, isPromised = false) {
    let splittedAddresses = [];

    if (helper.isAddressesAvailable(addresses))
        splittedAddresses = addresses.split(",");

    let requests = [];
    for (let address of splittedAddresses) {
        try {
            if (!isPromised) {
                console.log("sendRequest("+address+","+payloadSize+")")
                requests.push(sendRequest(address, payloadSize));
            } else {
                console.log("promisedSendRequest("+address+","+payloadSize+")")
                requests.push(promisedSendRequest(address, payloadSize));
            }
        } catch (e) {
            return e;
        }
    }

    return requests;
}

function executePromisedNetWorkload(payloadSize) {
    let splittedAddresses = []
    if (helper.isAddressesAvailable(addresses))
        splittedAddresses = addresses.split(",");

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
    };
}