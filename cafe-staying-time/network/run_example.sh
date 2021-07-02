#!/bin/bash


######################################################################################################################################
##
## example to run this program
##
## ./run_example.sh -oa org2 -on Org2 -pn peer0 -an Admin -p 9051 -ch hnchannel -n fabcar -q '{"function":"queryAllCars","Args":[""]}'
##
## that command can run query 'queryAllCars' on peer0.org2 (port 9051)
##
######################################################################################################################################


. ./scripts/envVar.sh

function run_ex {

    local ORG_ADDR="cafe1"
    local ORG_NM="Cafe1"
    local PEER_NM="peer0"
    local ADMIN_NM="Admin"
    local P0PORT=7051
    local CHANNEL="hnchannel"
    local NAME="cafe-manage"
    local QUERY='{"function":"getIOs","Args":[""]}'

    while [[ $# -ge 1 ]]; do
        key="$1"
        case $key in
            -oa )
                ORG_ADDR="$2"
                shift
                ;;
            -on )
                ORG_NM="$2"
                shift
                ;;
            -pn )
                PEER_NM="$2"
                shift
                ;;
            -an )
                ADMIN_NM="$2"
                shift
                ;;
            -p )
                P0PORT="$2"
                shift
                ;;
            -ch )
                CHANNEL="$2"
                shift
                ;;
            -n )
                NAME="$2"
                shift
                ;;
            -q )
                QUERY="$2"
                shift
                ;;
        esac
        shift
    done

    setGlobals $ORG_ADDR $ORG_NM $PEER_NM $ADMIN_NM $P0PORT

    set -x
    peer chaincode query -C $CHANNEL -n $NAME -c $QUERY
}

run_ex $@

