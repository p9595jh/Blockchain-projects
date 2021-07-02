#!/bin/bash

set -e

. ./scriptUtils.sh

function waitToPrepare {
    sleep 3
}

# cd network

printDiv "Down previous network before starting new"
./network.sh down
waitToPrepare

printDiv "Start new network"
./network.sh up -ca -s couchdb
waitToPrepare

printDiv "Create a channel"
./network.sh createChannel
waitToPrepare

printDiv "Deploy chaincode"
# ./network.sh deployCC -cci initLedger -ccn fabcar -ccp fabcar -ccl typescript
# cci: initialization function name, it is optional
# ccn: name of the chaincode
# ccp: path of the chaincode. In this program, i have set all the path to be '../chaincode/codes/${NAME}', so don't have to set entire path and just chaincode name is needed.
# ccl: composed language
# in this example, we're gonna install go chaincode named 'fabcar'

./network.sh deployCC -cci initLedger -ccn cafe-manage -ccp cafe-manage -ccl typescript
waitToPrepare

./run_example.sh -n cafe-manage -q '{"function":"getIOs","args":[]}' -oa cafe1 -on Cafe1
waitToPrepare

printDiv "querying"
pushd ../query/src

rm -rf wallet
waitToPrepare

node enrollAdmin.ts
node registerUser.ts
waitToPrepare

printDiv "yeah"
node query.ts
node invoke.ts
waitToPrepare
node query.ts
popd
