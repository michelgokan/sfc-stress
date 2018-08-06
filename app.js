const express = require('express');
const app = express();
var workloads = require("./workloads");


app.get('/workload/cpu', (req, res) => res.send(workloads.CPUIntensiveWorkload().toString()));
app.get('/workload/mem', (req, res) => res.send(workloads.memoryIntensiveWorkload().toString()));
app.get('/workload/disk', (req, res) => res.send(workloads.diskIntensiveWorkload().toString()));
app.get('/workload/net', (req, res) => res.send(workloads.networkIntensiveWorkload().toString()));
app.get('/workload/x', (req, res) => res.send(workloads.combinedWorkload().toString()));
app.get('/workload/', (req, res) => res.send("Hi :)!<br />Please use one of the following endpoints:<br />* /cpu for CPU intensive workloads<br />* /mem for memory intensive workloads<br />* /disk for disk intensive workloads<br />* /net for network intensive workloads<br />* /x for combined workloads"));

app.listen(30005, "0.0.0.0");