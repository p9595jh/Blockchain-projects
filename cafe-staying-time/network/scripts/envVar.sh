source scriptUtils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer.${SERV_NM}.com/msp/tlscacerts/tlsca.${SERV_NM}.com-cert.pem
export PEER_ORG_CA_PATH=${PWD}/organizations/peerOrganizations

# Set OrdererOrg.Admin globals
setOrdererGlobals() {
  export CORE_PEER_LOCALMSPID="OrdererMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer.${SERV_NM}.com/msp/tlscacerts/tlsca.${SERV_NM}.com-cert.pem
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/users/Admin@${SERV_NM}.com/msp
}

# Set environment variables for the peer org
setGlobals() {
  local ORG_ADDR=$1
  local ORG_NM=$2
  local PEER_NM=$3
  local ADMIN_NM=$4
  local P0PORT=$5

  infoln "Set for organization ${ORG_ADDR}"
  export CORE_PEER_LOCALMSPID="${ORG_NM}MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PEER_ORG_CA_PATH}/${ORG_ADDR}.${SERV_NM}.com/peers/${PEER_NM}.${ORG_ADDR}.${SERV_NM}.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/${ORG_ADDR}.${SERV_NM}.com/users/${ADMIN_NM}@${ORG_ADDR}.${SERV_NM}.com/msp
  export CORE_PEER_ADDRESS=localhost:${P0PORT}

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
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
    ## Set peer addresses
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    ## Set path to TLS certificate
    TLSINFO=$(eval echo "--tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE")
    PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    # shift to get to the next organization
    shift 5
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
