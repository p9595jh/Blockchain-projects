#!/bin/bash

source scripts/utils.sh

function createOrg() {

  local SERV_NM=$1
  local ORG_ADDR=$2
  local CAPORT=$3
  local ADDR=${ORG_ADDR}.${SERV_NM}.com
  local ADMIN_PW="adminpw"

  infoln "Enroll the CA admin"
  mkdir -p organizations/peerOrganizations/${ADDR}/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/${ADDR}
  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://admin:${ADMIN_PW}@localhost:${CAPORT} --caname ca-${ORG_ADDR} --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_ADDR}/tls-cert.pem
  { set +x; } 2>/dev/null

  echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-$CAPORT-ca-$ORG_ADDR.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-$CAPORT-ca-$ORG_ADDR.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-$CAPORT-ca-$ORG_ADDR.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-$CAPORT-ca-$ORG_ADDR.pem
    OrganizationalUnitIdentifier: orderer" >${PWD}/organizations/peerOrganizations/${ADDR}/msp/config.yaml
}


function registerPeer() {

  local ORG_ADDR=$1
  local ADDR=$2
  local CAPORT=$3
  local PEER_NM=$4
  local PEER_PW=${PEER_NM}pw

  infoln "Register ${PEER_NM}"
  set -x
  fabric-ca-client register --caname ca-${ORG_ADDR} --id.name ${PEER_NM} --id.secret ${PEER_NM}pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_ADDR}/tls-cert.pem
  { set +x; } 2>/dev/null

  mkdir -p organizations/peerOrganizations/${ADDR}/peers
  mkdir -p organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}

  infoln "Generate the ${PEER_NM} msp"
  set -x
  fabric-ca-client enroll -u https://${PEER_NM}:${PEER_NM}pw@localhost:${CAPORT} --caname ca-${ORG_ADDR} -M ${PWD}/organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}/msp --csr.hosts ${PEER_NM}.${ADDR} --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_ADDR}/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/peerOrganizations/${ADDR}/msp/config.yaml ${PWD}/organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}/msp/config.yaml

  infoln "Generate the ${PEER_NM}-tls certificates"
  set -x
  fabric-ca-client enroll -u https://${PEER_NM}:${PEER_PW}@localhost:${CAPORT} --caname ca-${ORG_ADDR} -M ${PWD}/organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}/tls --enrollment.profile tls --csr.hosts ${PEER_NM}.${ADDR} --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_ADDR}/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}/tls/signcerts/* ${PWD}/organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}/tls/keystore/* ${PWD}/organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}/tls/server.key

  mkdir -p ${PWD}/organizations/peerOrganizations/${ADDR}/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/${ADDR}/msp/tlscacerts/ca.crt

  mkdir -p ${PWD}/organizations/peerOrganizations/${ADDR}/tlsca
  cp ${PWD}/organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/${ADDR}/tlsca/tlsca.${ADDR}-cert.pem

  mkdir -p ${PWD}/organizations/peerOrganizations/${ADDR}/ca
  cp ${PWD}/organizations/peerOrganizations/${ADDR}/peers/${PEER_NM}.${ADDR}/msp/cacerts/* ${PWD}/organizations/peerOrganizations/${ADDR}/ca/ca.${ADDR}-cert.pem

}

function registerUser() {

  local ORG_ADDR=$1
  local ADDR=$2
  local CAPORT=$3
  local USER_ID=$4
  local USER_NM=$5
  # temp password
  local USER_PW=${USER_ID}pw

  infoln "Register user"
  set -x
  fabric-ca-client register --caname ca-${ORG_ADDR} --id.name ${USER_ID} --id.secret ${USER_PW} --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_ADDR}/tls-cert.pem
  { set +x; } 2>/dev/null

  mkdir -p organizations/peerOrganizations/${ADDR}/users
  mkdir -p organizations/peerOrganizations/${ADDR}/users/${USER_NM}@${ADDR}

  infoln "Generate the user msp"
  set -x
  fabric-ca-client enroll -u https://${USER_ID}:${USER_PW}@localhost:${CAPORT} --caname ca-${ORG_ADDR} -M ${PWD}/organizations/peerOrganizations/${ADDR}/users/${USER_NM}@${ADDR}/msp --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_ADDR}/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/peerOrganizations/${ADDR}/msp/config.yaml ${PWD}/organizations/peerOrganizations/${ADDR}/users/${USER_NM}@${ADDR}/msp/config.yaml
}

function registerAdmin() {

  local ORG_ADDR=$1
  local ADDR=$2
  local CAPORT=$3
  local ADMIN_ID=$4
  local ADMIN_NM=$5
  # temp password
  local ADMIN_PW=${ADMIN_ID}pw

  infoln "Register the org admin"
  set -x
  fabric-ca-client register --caname ca-${ORG_ADDR} --id.name ${ADMIN_ID} --id.secret ${ADMIN_PW} --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_ADDR}/tls-cert.pem
  { set +x; } 2>/dev/null

  mkdir -p organizations/peerOrganizations/${ADDR}/users/${ADMIN_NM}@${ADDR}

  infoln "Generate the org admin msp"
  set -x
  fabric-ca-client enroll -u https://${ADMIN_ID}:${ADMIN_PW}@localhost:${CAPORT} --caname ca-${ORG_ADDR} -M ${PWD}/organizations/peerOrganizations/${ADDR}/users/${ADMIN_NM}@${ADDR}/msp --tls.certfiles ${PWD}/organizations/fabric-ca/${ORG_ADDR}/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/peerOrganizations/${ADDR}/msp/config.yaml ${PWD}/organizations/peerOrganizations/${ADDR}/users/${ADMIN_NM}@${ADDR}/msp/config.yaml
}


#####
function createOrderer {

  local SERV_NM=$1
  local CAPORT=$2
  local ORDERER_PW="ordererpw"
  local ORDERER_ADMIN_PW="ordererAdminpw"
  local ADMIN_PW=adminpw #"123123"

	infoln "Enroll the CA admin"
	mkdir -p organizations/ordererOrganizations/${SERV_NM}.com

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/${SERV_NM}.com
#  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
#  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://admin:${ADMIN_PW}@localhost:${CAPORT} --caname ca-orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-${CAPORT}-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-${CAPORT}-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-${CAPORT}-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-${CAPORT}-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer" > ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/config.yaml

	infoln "Register orderer1"
  set -x
	fabric-ca-client register --caname ca-orderer --id.name orderer1 --id.secret orderer1pw --id.type orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

	infoln "Register orderer2"
  set -x
	fabric-ca-client register --caname ca-orderer --id.name orderer2 --id.secret orderer2pw --id.type orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  infoln "Register the orderer admin"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ${ORDERER_ADMIN_PW} --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

	mkdir -p organizations/ordererOrganizations/${SERV_NM}.com/orderers
  # mkdir -p organizations/ordererOrganizations/${SERV_NM}.com/orderers/${SERV_NM}.com

  mkdir -p organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com
  mkdir -p organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com

  infoln "## Generate the orderer1 msp"
  set -x
	fabric-ca-client enroll -u https://orderer1:orderer1pw@localhost:${CAPORT} --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/msp --csr.hosts orderer1.${SERV_NM}.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/msp/config.yaml

  infoln "## Generate the orderer1-tls certificates"
  set -x
  fabric-ca-client enroll -u https://orderer1:orderer1pw@localhost:${CAPORT} --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/tls --enrollment.profile tls --csr.hosts orderer1.${SERV_NM}.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/tls/ca.crt
  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/tls/server.crt
  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/tls/keystore/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/tls/server.key

  mkdir -p ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/msp/tlscacerts/tlsca.${SERV_NM}.com-cert.pem

  mkdir -p ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer1.${SERV_NM}.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/tlscacerts/tlsca.${SERV_NM}.com-cert.pem

  infoln "## Generate the orderer2 msp"
  set -x
	fabric-ca-client enroll -u https://orderer2:orderer2pw@localhost:${CAPORT} --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/msp --csr.hosts orderer2.${SERV_NM}.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/msp/config.yaml

  infoln "## Generate the orderer2-tls certificates"
  set -x
  fabric-ca-client enroll -u https://orderer2:orderer2pw@localhost:${CAPORT} --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/tls --enrollment.profile tls --csr.hosts orderer2.${SERV_NM}.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/tls/ca.crt
  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/tls/server.crt
  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/tls/keystore/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/tls/server.key

  mkdir -p ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/msp/tlscacerts/tlsca.${SERV_NM}.com-cert.pem

  mkdir -p ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/orderer2.${SERV_NM}.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/tlscacerts/tlsca.${SERV_NM}.com-cert.pem

  mkdir -p organizations/ordererOrganizations/${SERV_NM}.com/users
  mkdir -p organizations/ordererOrganizations/${SERV_NM}.com/users/Admin@${SERV_NM}.com

  infoln "## Generate the admin msp"
  set -x
	fabric-ca-client enroll -u https://ordererAdmin:${ORDERER_ADMIN_PW}@localhost:${CAPORT} --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/users/Admin@${SERV_NM}.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/users/Admin@${SERV_NM}.com/msp/config.yaml

}

function createOrdererOrg {

  local SERV_NM=$1
  local CAPORT=$2
  shift 2
  local ORDERER_ORGS=("$@")
  local ORDERER_PW="ordererpw"
  local ORDERER_ADMIN_PW="ordererAdminpw"
  local ADMIN_PW=adminpw #"123123"

	infoln "Enroll the CA admin"
	mkdir -p organizations/ordererOrganizations/${SERV_NM}.com

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/${SERV_NM}.com

  set -x
  fabric-ca-client enroll -u https://admin:${ADMIN_PW}@localhost:${CAPORT} --caname ca-orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-${CAPORT}-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-${CAPORT}-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-${CAPORT}-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-${CAPORT}-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer" > ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/config.yaml

  for ORDERER_ORG in ${ORDERER_ORGS[@]}; do
    infoln "Register $ORDERER_ORG"
    set -x
    fabric-ca-client register --caname ca-orderer --id.name $ORDERER_ORG --id.secret ${ORDERER_ORG}pw --id.type orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
    set +x
  done

  infoln "Register the orderer admin"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ${ORDERER_ADMIN_PW} --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

	mkdir -p organizations/ordererOrganizations/${SERV_NM}.com/orderers

  for ORDERER_ORG in ${ORDERER_ORGS[@]}; do
    mkdir -p organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com
  done

  for ORDERER_ORG in ${ORDERER_ORGS[@]}; do
    infoln "## Generate the $ORDERER_ORG msp"
    set -x
    fabric-ca-client enroll -u https://${ORDERER_ORG}:${ORDERER_ORG}pw@localhost:${CAPORT} --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/msp --csr.hosts ${ORDERER_ORG}.${SERV_NM}.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
    set +x

    cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/msp/config.yaml

    infoln "## Generate the ${ORDERER_ORG}-tls certificates"
    set -x
    fabric-ca-client enroll -u https://${ORDERER_ORG}:${ORDERER_ORG}pw@localhost:${CAPORT} --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/tls --enrollment.profile tls --csr.hosts ${ORDERER_ORG}.${SERV_NM}.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
    set +x

    cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/tls/ca.crt
    cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/tls/server.crt
    cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/tls/keystore/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/tls/server.key

    mkdir -p ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/msp/tlscacerts
    cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/msp/tlscacerts/tlsca.${SERV_NM}.com-cert.pem

    mkdir -p ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/tlscacerts
    cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/orderers/${ORDERER_ORG}.${SERV_NM}.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/tlscacerts/tlsca.${SERV_NM}.com-cert.pem
  done

  mkdir -p organizations/ordererOrganizations/${SERV_NM}.com/users
  mkdir -p organizations/ordererOrganizations/${SERV_NM}.com/users/Admin@${SERV_NM}.com

  infoln "## Generate the admin msp"
  set -x
	fabric-ca-client enroll -u https://ordererAdmin:${ORDERER_ADMIN_PW}@localhost:${CAPORT} --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/users/Admin@${SERV_NM}.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/${SERV_NM}.com/users/Admin@${SERV_NM}.com/msp/config.yaml

}
