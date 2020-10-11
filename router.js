const name = process.env.NAME;
const express = require('express');
const router = express.Router();
const workloads = require("./workloads/workloads");

const setRouter = (app) => {
    router.all('*/cpu/:workloadSize?/:threadsCount?/:sendToNext?/:payloadSize?', (req, res) =>
        workloads.CPUIntensiveWorkload(req).then(function (responses) {
            res.send(name + ": Executed " + responses[0].paramValue + " Diffie-Hellman checksums in " + responses[0].threadsCount + " thread(s)!");
        }).catch(err => {
            res.send(err.toString());
        }));
    router.all('*/mem/:dataSize?/:threadsCount?/:sendToNext?/:payloadSize?', (req, res) =>
        workloads.memoryIntensiveWorkload(req).then(function (responses) {
            res.send(name + ": Stored and released " + responses[0].paramValue + " x " + responses[0].threadsCount + "=" + responses[0].paramValue * responses[0].threadsCount + "MB of data in RAM using " + responses[0].threadsCount + " thread(s)!");
        }).catch(err => {
            res.send(err.toString());
        }));
    router.all('*/blkio/:fileSize?/:threadsCount?/:sendToNext?/:payloadSize?', (req, res) =>
        workloads.blkioIntensiveWorkload(req).then(function (responses) {
            res.send(name + ": Wrote and removed " + responses[0].paramValue + "MB x " + responses[0].threadsCount + " files = " + responses[0].paramValue * responses[0].threadsCount + "MB of data in the storage using " + responses[0].threadsCount + " thread(s)!");
        }).catch(err => {
            res.send(err.toString());
        }));
    router.all('*/net/:payloadSize?/:isPromised?', (req, res) => {
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
    router.all('*/x/:sendToNext?/:isPromised?', (req, res) => {
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
        const showdown = require('showdown');
        const fs = require('fs');
        const converter = new showdown.Converter();
        const text = fs.readFileSync('./README.md', 'utf8');
        res.send(converter.makeHtml(text));
    });

    app.use('/', router);
}

module.exports = {setRouter: setRouter};