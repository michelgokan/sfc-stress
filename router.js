const name = process.env.NAME;
const express = require('express');
const router = express.Router();
const workloads = require("./workloads/workloads");

const setRouter = (app) => {
    router.all('*/cpu/:workloadSize?/:threadsCount?/:sendToNext?/:payloadSize?/:isPromised?', (req, res) => {
        req.setTimeout(2147483647);
        res.setTimeout(2147483647);

        workloads.CPUIntensiveWorkload(req).then(function (responses) {
            const paramValue = responses[0].paramValue != undefined ? responses[0].paramValue : responses[0][0][0].paramValue;
            const threadsCount = responses[0].threadsCount != undefined ? responses[0].threadsCount : responses[0][0][0].threadsCount;
            let htmlToSend = name + ": Executed " + paramValue + " Diffie-Hellman checksums in " + threadsCount + " thread(s)!";
            if(responses.length == 2 && responses[1].length > 0)
                htmlToSend += "<br />[" + responses[1].join() + "]";
            res.send(htmlToSend);
        }).catch(err => {
            res.send(err.toString());
        });
    });
    router.all('*/mem/:dataSize?/:threadsCount?/:sendToNext?/:payloadSize?/:isPromised?', (req, res) => {
        req.setTimeout(2147483647);
        res.setTimeout(2147483647);
        workloads.memoryIntensiveWorkload(req).then(function (responses) {
            res.send(name + ": Stored and released " + responses[0].paramValue + " x " + responses[0].threadsCount + "=" + responses[0].paramValue * responses[0].threadsCount + "MB of data in RAM using " + responses[0].threadsCount + " thread(s)!");
        }).catch(err => {
            res.send(err.toString());
        });
    });
    router.all('*/blkio/:fileSize?/:threadsCount?/:sendToNext?/:payloadSize?/:isPromised?', (req, res) => {
        req.setTimeout(2147483647);
        res.setTimeout(2147483647);
        workloads.blkioIntensiveWorkload(req).then(function (responses) {
            res.send(name + ": Wrote and removed " + responses[0].paramValue + "MB x " + responses[0].threadsCount + " files = " + responses[0].paramValue * responses[0].threadsCount + "MB of data in the storage using " + responses[0].threadsCount + " thread(s)!");
        }).catch(err => {
            res.send(err.toString());
        });
    });
    router.all('*/net/:payloadSize?/:isPromised?', (req, res) => {
        req.setTimeout(2147483647);
        res.setTimeout(2147483647);
        let networkIntensiveWorkloadResults = workloads.networkIntensiveWorkload(req);
        if (networkIntensiveWorkloadResults[0] == true) {
            Promise.all(networkIntensiveWorkloadResults[1]).then(function (responses) {
                res.send(responses);
            }).catch(err => {
                res.send(err.toString());
            });
        } else {
            res.send("OK");
        }
    });
    router.all('*/x/:workloadSize?/:dataSize?/:fileSize?/:payloadSize?/:sendToNext?/:isPromised?', (req, res) => {
        req.setTimeout(2147483647);
        res.setTimeout(2147483647);

        let results = workloads.runAll(req),
            sendToNext = results[0], promises = results[1];

        if (sendToNext == true) {
            Promise.all(promises).then((responses) => {
                let networkIntensiveWorkloadResults = workloads.networkIntensiveWorkload(req);
                if (networkIntensiveWorkloadResults[0] == true) {
                    Promise.all(networkIntensiveWorkloadResults[1]).then((value) => {
                        res.send(value);
                    }).catch(err => {
                        res.send(err.toString());
                    });
                } else {
                    res.send(name + ": OK");
                }
            }).catch(err => {
                res.send(err.toString());
            });
        } else {
            res.send(name + ": OK");
        }
    });

    router.get('*/', (req, res) => {
        req.setTimeout(2147483647);
        res.setTimeout(2147483647);

        const showdown = require('showdown');
        const fs = require('fs');
        const converter = new showdown.Converter();
        const text = fs.readFileSync('./README.md', 'utf8');
        res.send(converter.makeHtml(text));
    });

    app.use('/', router);
}

module.exports = {setRouter: setRouter};