#!/bin/bash

. scripts/utils.sh

ORDERER_NM='orderer'
ORDERER_CA_PATH=${PWD}/organizations/ordererOrganizations/${SERV_NM}.com
PEER_ORG_CA_PATH=${PWD}/organizations/peerOrganizations

export FABRIC_CFG_PATH=$PWD/configtx
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${ORDERER_CA_PATH}/orderers/${ORDERER_NM}.${SERV_NM}.com/msp/tlscacerts/tlsca.${SERV_NM}.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${ORDERER_CA_PATH}/${ORDERER_NM}.${SERV_NM}.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${ORDERER_CA_PATH}/${ORDERER_NM}.${SERV_NM}.com/tls/server.key

# Set OrdererOrg.Admin globals
setOrdererGlobals() {
  export CORE_PEER_LOCALMSPID="OrdererMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${ORDERER_CA_PATH}/orderers/${ORDERER_NM}.${SERV_NM}.com/msp/tlscacerts/tlsca.${SERV_NM}.com-cert.pem
  export CORE_PEER_MSPCONFIGPATH=${ORDERER_CA_PATH}/users/Admin@${SERV_NM}.com/msp
}

# Set environment variables for the peer org
setGlobals() {
  local ORG_ADDR=$1
  local ORG_NM=$2
  local PEER_NM=$3
  local ADMIN_NM=$4
  local P0PORT=$5

  infoln "Set for $PEER_NM of $ORG_ADDR ($P0PORT)"
  export CORE_PEER_LOCALMSPID="${ORG_NM}MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PEER_ORG_CA_PATH}/${ORG_ADDR}.${SERV_NM}.com/peers/${PEER_NM}.${ORG_ADDR}.${SERV_NM}.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${PEER_ORG_CA_PATH}/${ORG_ADDR}.${SERV_NM}.com/users/${ADMIN_NM}@${ORG_ADDR}.${SERV_NM}.com/msp
  export CORE_PEER_ADDRESS=localhost:${P0PORT}

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

parsePeerConnectionParameters() {
  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    local ORG_ADDR=$1
    local ORG_NM=$2
    local PEER_NM=$3
    local ADMIN_NM=$4
    local P0PORT=$5

    setGlobals $ORG_ADDR $ORG_NM $PEER_NM $ADMIN_NM $P0PORT
    PEER="${PEER_NM}.${ORG_ADDR}"
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    TLSINFO=$(eval echo "--tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE")
    PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    shift 5
  done
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
