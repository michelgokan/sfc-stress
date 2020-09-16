const express = require('express');
const app = express();
var bodyParser = require('body-parser')
let workloads = require("./workloads");

const getDurationInMilliseconds = (start) => {
    const NS_PER_SEC = 1e9;
    const NS_TO_MS = 1e6;
    const diff = process.hrtime(start);

    return (diff[0] * NS_PER_SEC + diff[1]) / NS_TO_MS;
}

app.use(bodyParser.json({limit: '10000mb'}))

app.use((req, res, next) => {
    // console.log(`${req.method} ${req.originalUrl}`)
    const start = process.hrtime();
    console.log(`Received ${req.method} ${req.originalUrl} from ${req.headers['referer']} [RECEIVED]`)

    res.on('close', () => {
        const durationInMilliseconds = getDurationInMilliseconds(start);
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
app.all('*/net/:payloadSize?', (req, res) => res.send(workloads.networkIntensiveWorkload(req, false).toString()));
app.all('*/promisedNet/:payloadSize?', (req, res) =>
    workloads.networkIntensiveWorkload(req, true).then(function (responses) {
        res.send([responses.concat('<br />')]);
    }).catch(err => {
        res.send(err.toString());
    }));
app.get('*/x/:isPromised?/:sendToNext?', (req, res) => {
    let combinedWorkloadResults = workloads.combinedWorkload(req);
    if (combinedWorkloadResults[0]) {
        combinedWorkloadResults[1].then(function (responses) {
            let result = workloads.runAll(req);
            Promise.all(result).then((responses) => {
                res.send([responses.concat('<br />')]);
            }).catch(err => {
                res.send(err.toString());
            });
        }).catch(err => {
            res.send(err.toString());
        });
    } else {
        res.send("OK");
        let result = workloads.runAll(req);
    }
});
app.get('*/', (req, res) => res.send("Hi :)!<br />Please use one of the following endpoints:<br />* /cpu for CPU intensive workloads<br />* /mem for memory intensive workloads<br />* /disk for disk intensive workloads<br />* /net for network intensive workloads<br />* /x for combined workloads"));

app.listen(30005, "0.0.0.0");
