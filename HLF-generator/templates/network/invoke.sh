#!/bin/bash


######################################################################################################################################
##
## example to run this program
##
## #./invoke.sh -oa org2 -on Org2 -pn peer0 -an Admin -p 9051 -ch hnchannel -n fabcar -q '{"function":"queryAllCars","Args":[""]}'
##
## #that command can run query 'queryAllCars' on peer0.org2 (port 9051)
##
## ./invode.sh ${dids_0[@]} -n testcc -q '{"function":"getStocks","Args":[""]}'
##
## also can check on localhost:5984/_utils/#login
##
######################################################################################################################################


. ./scripts/envVar.sh

function run_ex {

    # receive parameters as an array
    # the arrays are defined in 'utils.sh'
    local ORG_ADDR=$1
	local ORG_NM=$2
	local PEER_NM=$3
	local ADMIN_NM=$4
	local P0PORT=$5
    local CHANNEL=$6

    # local ORG_ADDR="org1"
    # local ORG_NM="Org1"
    # local PEER_NM="peer0"
    # local ADMIN_NM="Admin"
    # local P0PORT=7051
    # local CHANNEL="hnchannel"

    local NAME="fabcar"
    local QUERY='{"function":"queryAllCars","Args":[""]}'

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

    # export CORE_PEER_TLS_ENABLED=true
    # export FABRIC_CFG_PATH=${PWD}/configtx
    setGlobals $ORG_ADDR $ORG_NM $PEER_NM $ADMIN_NM $P0PORT
    set -x
    peer chaincode query -C $CHANNEL -n $NAME -c $QUERY
}

run_ex $@

