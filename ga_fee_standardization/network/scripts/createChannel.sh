#!/bin/bash

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="hnchannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

# import utils
. scripts/envVar.sh
. scripts/utils.sh

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelTx() {
	local CHANNEL_NAME=$1
	local CHANNEL_PROFILE=$2

	set -x
	configtxgen -profile $CHANNEL_PROFILE -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

	res=$?
	{ set +x; } 2>/dev/null
	if [ $res -ne 0 ]; then
		fatalln "Failed to generate channel configuration transaction..."
	fi
}

createAnchorPeerTx() {
	local orgmsp=$1
	local CHANNEL_NAME=$2
	local CHANNEL_PROFILE=$3
	local tx_add=$4
	infoln "Generating anchor peer update transaction for ${orgmsp} in ${CHANNEL_NAME} of ${CHANNEL_PROFILE}"

	set -x
	configtxgen -profile ${CHANNEL_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors${tx_add}.tx -channelID $CHANNEL_NAME -asOrg $orgmsp
	res=$?
	{ set +x; } 2>/dev/null
	if [ $res -ne 0 ]; then
		fatalln "Failed to generate anchor peer update transaction for ${orgmsp} in ${CHANNEL_NAME} of ${CHANNEL_PROFILE}..."
	fi
}

createChannel() {
	setGlobals $1 $2 $3 $4 $5
	local CHANNEL_NAME=$6
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride ${ORDERER_NM}.${SERV_NM}.com -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA >&log.txt
		# osnadmin channel join --channel-id $CHANNEL_NAME --config-block ./channel-artifacts/${CHANNEL_NAME}.block -o localhost:7050 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
	successln "Channel '$CHANNEL_NAME' created"
}

# queryCommitted ORG
joinChannel() {
	local ORG_ADDR=$1
	local PEER_NM=$3
	local CHANNEL_NAME=$6
	setGlobals $1 $2 $3 $4 $5
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, ${PEER_NM}.${ORG_ADDR} has failed to join channel '$CHANNEL_NAME'"
}

updateAnchorPeers() {
	setGlobals $1 $2 $3 $4 $5
	local rc=1
	local COUNTER=1
	local CHANNEL_NAME=$6
	local ANCHOR_CHANNEL=$7
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY

		set -x
		peer channel update -o localhost:7050 --ordererTLSHostnameOverride ${ORDERER_NM}.${SERV_NM}.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors${ANCHOR_CHANNEL}.tx --tls --cafile $ORDERER_CA >&log.txt

		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Anchor peer update failed"
	successln "Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
	sleep $DELAY
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}


FABRIC_CFG_PATH=$PWD/configtx

## Create channeltx
infoln "Generating channel create transaction '${CHANNEL_NAME}.tx'"
createChannelTx ${CHANNEL_NAME}1 ${CHANNEL_PROFILE}1
createChannelTx ${CHANNEL_NAME}2 ${CHANNEL_PROFILE}2

## Create anchorpeertx
infoln "Generating anchor peer update transactions"
createAnchorPeerTx Ins1MSP ${CHANNEL_NAME}1 ${CHANNEL_PROFILE}1
createAnchorPeerTx Ins2MSP ${CHANNEL_NAME}1 ${CHANNEL_PROFILE}1 ${CHANNEL_PROFILE}1
createAnchorPeerTx Ins2MSP ${CHANNEL_NAME}2 ${CHANNEL_PROFILE}2 ${CHANNEL_PROFILE}2
createAnchorPeerTx Ins3MSP ${CHANNEL_NAME}2 ${CHANNEL_PROFILE}2
createAnchorPeerTx Ga1MSP ${CHANNEL_NAME}1 ${CHANNEL_PROFILE}1
createAnchorPeerTx Ga2MSP ${CHANNEL_NAME}2 ${CHANNEL_PROFILE}2

# Create channel
infoln "Creating channel ${CHANNEL_NAME}1"
createChannel ${ins11[@]}

infoln "Creating channel ${CHANNEL_NAME}2"
createChannel ${ins22[@]}

## Join all the peers to the channel
infoln "Join peers to the ${CHANNEL_NAME}1..."
joinChannel ${ins11[@]}
joinChannel ${ins21[@]}
joinChannel ${ga1[@]}

infoln "Join Dids peers to the ${CHANNEL_NAME}2..."
joinChannel ${ins22[@]}
joinChannel ${ins32[@]}
joinChannel ${ga2[@]}

## Set the anchor peers for each org in the channel
infoln "Updating anchor peers for ins1..."
updateAnchorPeers ${ins11[@]}

infoln "Updating anchor peers for ins2..."
updateAnchorPeers ${ins21[@]} ${CHANNEL_PROFILE}1
updateAnchorPeers ${ins22[@]} ${CHANNEL_PROFILE}2

infoln "Updating anchor peers for ins3..."
updateAnchorPeers ${ins32[@]}

infoln "Updating anchor peers for ga1..."
updateAnchorPeers ${ga1[@]}

infoln "Updating anchor peers for ga2..."
updateAnchorPeers ${ga2[@]}

successln "Channel successfully joined"

exit 0
