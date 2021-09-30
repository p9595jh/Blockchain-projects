#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $7)
    local CP=$(one_line_pem $8)
    sed -e "s/\${ORG_ADDR}/$1/" \
        -e "s/\${ORG_NM}/$2/" \
        -e "s/\${SERV_NM}/$3/" \
        -e "s/\${P0PORT}/$4/" \
        -e "s/\${CAPORT}/$5/" \
        -e "s/\${PEER_NM}/$6/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $7)
    local CP=$(one_line_pem $8)
    sed -e "s/\${ORG_ADDR}/$1/" \
        -e "s/\${ORG_NM}/$2/" \
        -e "s/\${SERV_NM}/$3/" \
        -e "s/\${P0PORT}/$4/" \
        -e "s/\${CAPORT}/$5/" \
        -e "s/\${PEER_NM}/$6/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

SERV_NM=$1
ORG_ADDR=$2
ORG_NM=$3
P0PORT=$4
CAPORT=$5
PEER_NM=$6
PEERPEM=organizations/peerOrganizations/${ORG_ADDR}.${SERV_NM}.com/tlsca/tlsca.${ORG_ADDR}.${SERV_NM}.com-cert.pem
CAPEM=organizations/peerOrganizations/${ORG_ADDR}.${SERV_NM}.com/ca/ca.${ORG_ADDR}.${SERV_NM}.com-cert.pem

echo "$(json_ccp $ORG_ADDR $ORG_NM $SERV_NM $P0PORT $CAPORT $PEER_NM $PEERPEM $CAPEM)" > organizations/peerOrganizations/${ORG_ADDR}.${SERV_NM}.com/connection-${ORG_ADDR}.json
echo "$(yaml_ccp $ORG_ADDR $ORG_NM $SERV_NM $P0PORT $CAPORT $PEER_NM $PEERPEM $CAPEM)" > organizations/peerOrganizations/${ORG_ADDR}.${SERV_NM}.com/connection-${ORG_ADDR}.yaml

