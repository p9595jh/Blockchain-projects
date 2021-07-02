#!/bin/bash

set -e

. scripts/utils.sh

./network.sh down
waits

./network.sh up createChannel
waits

./network.sh deployCC -cci initLedger -ccn testcc -ccp testcc -ccl typescript -c ${CHANNEL_NAME}1
waits

./network.sh deployCC -cci initLedger -ccn testcc2 -ccp testcc2 -ccl typescript -c ${CHANNEL_NAME}2
waits

./invoke.sh ${ins11[@]} -n testcc -q '{"function":"getStocks","Args":[]}'
./invoke.sh ${ins32[@]} -n testcc2 -q '{"function":"getThings","Args":[]}'

