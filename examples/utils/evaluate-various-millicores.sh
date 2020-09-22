#!/bin/bash
ROOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../ && pwd -P )"

$ROOTPATH/examples/utils/get-perf-stats-while-running.sh s1 ingress-nginx s1/cpu/500 test1
