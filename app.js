const express = require('express');
const app = express();
let workloads = require("./workloads");
const addresses = "http://127.0.0.1:30005/workload/mem,http://127.0.0.1:30005/workload/cpu";
// const addresses  = process.env.NEXT_SERVICES_ADDRESSES;
const addressesCount = addresses.split(',').length;
    
app.get('/workload/cpu/:workloadSize?/:threadsCount?/:sendToNext?', (req, res) =>
    workloads.CPUIntensiveWorkload(req).then(function (responses) {
        res.send("Executed " + responses[0].paramValue + " Diffie-Hellman checksums in " + responses[0].threadsCount + " thread(s)!");
    }).catch(err => res.send(err.toString())));
app.post('/workload/cpu/:workloadSize?/:threadsCount?/:sendToNext?', (req, res) =>
    workloads.CPUIntensiveWorkload(req).then(function (responses) {
        res.send("Executed " + responses[0].paramValue + " Diffie-Hellman checksums in " + responses[0].threadsCount + " thread(s)!");
    }).catch(err => res.send(err.toString())));
app.get('/workload/mem/:dataSize?/:threadsCount?/:sendToNext?', (req, res) =>
    workloads.memoryIntensiveWorkload(req).then(function (responses) {
        res.send("Stored and released " + responses[0].paramValue + " x " + responses[0].threadsCount + "=" + responses[0].paramValue * responses[0].threadsCount + "MB of data in RAM using " + responses[0].threadsCount + " thread(s)!");
    }).catch(err => res.send(err.toString())));
app.post('/workload/mem/:dataSize?/:threadsCount?/:sendToNext?', (req, res) =>
    workloads.memoryIntensiveWorkload(req).then(function (responses) {
        res.send("Stored and released " + responses[0].paramValue + " x " + responses[0].threadsCount + "=" + responses[0].paramValue * responses[0].threadsCount + "MB of data in RAM using " + responses[0].threadsCount + " thread(s)!");
    }).catch(err => res.send(err.toString())));
app.get('/workload/blkio/:fileSize?/:threadsCount?/:sendToNext?', (req, res) =>
    workloads.blkioIntensiveWorkload(req).then(function (responses) {
        res.send("Wrote and removed " + responses[0].paramValue + "MB x " + responses[0].threadsCount + " files = " + responses[0].paramValue * responses[0].threadsCount + "MB of data in the storage using " + responses[0].threadsCount + " thread(s)!");
    }).catch(err => res.send(err.toString())));
// app.get('/workload/net/:payloadSize?/:threadsCount?', (req, res) =>
//     workloads.networkIntensiveWorkload(req).then(function (responses) {
//             res.send("Transmitted " + responses[0].paramValue + "MB x " + addressesCount + " destinations x " + responses[0].threadsCount + " threads = " + responses[0].paramValue * responses[0].threadsCount * addressesCount + "MB of data from " + req.protocol + "://" + req.get('host') + req.originalUrl + " to [" + addresses + "]  using " + responses[0].threadsCount + " thread(s)!");
//     }).catch(err => res.send(err)));

app.get('/workload/net/:payloadSize?', (req, res) => res.send(workloads.networkIntensiveWorkload(req, false).toString()));
app.post('/workload/net/:payloadSize?', (req, res) => res.send(workloads.networkIntensiveWorkload(req, false).toString()));


app.get('/workload/promisedNet/:payloadSize?', (req, res) =>
    workloads.networkIntensiveWorkload(req, true).then(function (responses) {
        res.send([responses.concat('<br />')]);
    }).catch(err => {
        res.send(err.toString());
    }));

app.get('/workload/x', (req, res) => res.send(workloads.combinedWorkload().toString()));
app.get('/workload/', (req, res) => res.send("Hi :)!<br />Please use one of the following endpoints:<br />* /cpu for CPU intensive workloads<br />* /mem for memory intensive workloads<br />* /disk for disk intensive workloads<br />* /net for network intensive workloads<br />* /x for combined workloads"));

app.listen(30005, "0.0.0.0");
