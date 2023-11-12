const {Worker, isMainThread, parentPort, workerData} = require('worker_threads');
const nextAddressesJSON = process.env.NEXT_SERVICES_ADDRESSES;
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
        let end_byte = payloadSize * 1024 * 1024;
        const readStream = fs.createReadStream('./workloads/payload/1GB.zip', {start: 0, end: end_byte});
        console.log("Read from byte 0 to byte " + end_byte);
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
    options.agent = new http.Agent({
        // keepAlive: false
        keepAliveMsecs: 2147483647
    });
    const req = http.request(options).setTimeout(2147483647);

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

function promisedSendRequest(address, payloadSize, originalReq) {
    return new Promise(function (resolve, reject) {
        try {
            let options = getRequestOptions(address, payloadSize);
            const form = getForm(payloadSize);
            options.headers = form.getHeaders();
            options.agent = new http.Agent({
                // keepAlive: false
                keepAliveMsecs: 2147483647
            });
            const req = http.request(options, (res) => {
                let body = [];
                res.on('data', (chunk) => {
                    body.push(chunk);
                }).setTimeout(2147483647);
                res.on('end', function () {
                    let bodyString = Buffer.concat(body).toString();
                    let is_json = false;

                    // Check if bodyString is a valid JSON (any type of json is acceptable)
                    try {
                        JSON.parse(bodyString);
                        is_json = true;
                    } catch (e) {
                    }

                    const durationInMilliseconds = (now() - originalReq.app.locals.start_time) / 1e6;
                    console.log(`Received ${res.method} response from ${address} at {${now()}} [REQUEST END] ${durationInMilliseconds.toLocaleString()}ms`);
                    let result =
                        "[{\"" + Buffer.concat(body).toString() +
                        "\": { \"duration\": \"" + durationInMilliseconds.toLocaleString() +
                        "ms\","
                    if(!is_json) {
                        result += " \"subRequests\": []}]";
                    } else {
                        result += " \"subRequests\": " + JSON.stringify(bodyString) + "}]";
                    }

                    if(res.method == null)
                        resolve(result);
                });
                res.on('error', (e) => {
                    reject(e);
                });
            }).setTimeout(2147483647);

            form.pipe(req);

            req.on('socket', () => {
                originalReq.app.locals.connect_time = now();
                console.log("Request connected at {" + originalReq.app.locals.connect_time + "}");
            });

            req.on('error', (error) => {
                console.log("ERROR " + error.code + " OCCURRED WHEN SENDING DATA!")
                console.log(error.message)
                console.log(error)
                reject(error);
            });
            req.on('finish', () => {
                const execDurationInMilliseconds = (now() - originalReq.app.locals.start_time) / 1e6;
                const sendingDurationInMilliseconds = (now() - originalReq.app.locals.connect_time) / 1e6;
                console.log(`SENT - ${name} sent a  ${req.method} request to ${address} at {${now()}} (duration from the beginning is ${execDurationInMilliseconds.toLocaleString()}ms - sending duration is ${sendingDurationInMilliseconds.toLocaleString()}ms)`);
            });
        } catch (e) {
            reject(e);
        }
    });
}

function getNextServiceAddress(addressesJSON, path) {
    let jsonObj = JSON.parse(addressesJSON);

    for (let pattern in jsonObj)
        if(RegExp(pattern).test(path))
            return jsonObj[pattern];

    return "";
}

function getSplittedAddresses(addressesJSON, req){
    let splittedAddresses = [];

    if (helper.isAddressesJSONAvailable(addressesJSON))
        splittedAddresses = getNextServiceAddress(addressesJSON, req.path).split(",");

    return splittedAddresses;
}

function executeNetWorkload(payloadSize, req, isPromised = false) {
    let splittedAddresses = getSplittedAddresses(nextAddressesJSON, req);
    let requests = [];

    for (let address of splittedAddresses) {
        try {
            if (!isPromised || isPromised === "0") {
                console.log("sendRequest(" + address + "," + payloadSize + ")")
                requests.push(sendRequest(address, payloadSize));
            } else {
                console.log("promisedSendRequest(" + address + "," + payloadSize + ")")
                requests.push(promisedSendRequest(address, payloadSize, req));
            }
        } catch (e) {
            return e;
        }
    }

    return requests;
}

if (!isMainThread) {
    let result = executeNetWorkload(workerData.paramValue);
    parentPort.postMessage(result)
} else {
    module.exports = {
        executeNetWorkload: executeNetWorkload,
    };
}