const express = require('express');
const app = express();
const bodyParser = require('body-parser');
let workloads = require("./workloads/workloads");
const helper = require("./workloads/helper");

app.use(bodyParser.json({limit: '10000mb'}));
app.use('/images', express.static('images'));
app.use((req, res, next) => {
    const start = process.hrtime();
    console.log(`Received ${req.method} ${req.originalUrl} from ${req.headers['referer']} [RECEIVED]`)

    res.on('close', () => {
        const durationInMilliseconds = helper.getDurationInMilliseconds(start);
        console.log(`Closed received ${req.method} ${req.originalUrl} from ${req.headers['referer']} [CLOSED] ${durationInMilliseconds.toLocaleString()} ms`)
    });
    next();
})
app.all('*/cpu/:workloadSize?/:threadsCount?/:sendToNext?/:payloadSize?', (req, res) =>
    workloads.CPUIntensiveWorkload(req).then(function (responses) {
        res.send("Executed " + responses[0].paramValue + " Diffie-Hellman checksums in " + responses[0].threadsCount + " thread(s)!");
    }).catch(err => {
        res.send(err.toString());
    }));
app.all('*/mem/:dataSize?/:threadsCount?/:sendToNext?/:payloadSize?', (req, res) =>
    workloads.memoryIntensiveWorkload(req).then(function (responses) {
        res.send("Stored and released " + responses[0].paramValue + " x " + responses[0].threadsCount + "=" + responses[0].paramValue * responses[0].threadsCount + "MB of data in RAM using " + responses[0].threadsCount + " thread(s)!");
    }).catch(err => {
        res.send(err.toString());
    }));
app.all('*/blkio/:fileSize?/:threadsCount?/:sendToNext?/:payloadSize?', (req, res) =>
    workloads.blkioIntensiveWorkload(req).then(function (responses) {
        res.send("Wrote and removed " + responses[0].paramValue + "MB x " + responses[0].threadsCount + " files = " + responses[0].paramValue * responses[0].threadsCount + "MB of data in the storage using " + responses[0].threadsCount + " thread(s)!");
    }).catch(err => {
        res.send(err.toString());
    }));
app.all('*/net/:payloadSize?/:isPromised?', (req, res) => {
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
app.get('*/x/:sendToNext?/:isPromised?', (req, res) => {
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
                res.send("OK");
            }
        }).catch(err => {
            res.send(err.toString());
        });
    } else {
        res.send("OK");
    }
});

app.get('*/', (req, res) => {
    const showdown = require('showdown');
    const fs = require('fs');
    const converter = new showdown.Converter();
    const text = fs.readFileSync('./README.md', 'utf8');
    res.send(converter.makeHtml(text));
});

app.listen(30005, "0.0.0.0");
