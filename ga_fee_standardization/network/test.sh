#!/bin/bash

set -e

. ./scripts/utils.sh
. ./scripts/envVar.sh

./network.sh down
waits

./network.sh up createChannel
waits

./network.sh deployCC -cci initLedger -ccn testcc2 -ccp testcc2 -ccl typescript -c ${CHANNEL_NAME}2
waits

./invoke.sh ${dids_0_ch2[@]} -n testcc2 -q '{"function":"getThings","Args":[]}'

