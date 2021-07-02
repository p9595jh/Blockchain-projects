#!/bin/bash

source scriptUtils.sh

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

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelTx() {

	set -x
	configtxgen -profile ${CHANNEL_PROFILE} -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
	if [ $res -ne 0 ]; then
		fatalln "Failed to generate channel configuration transaction..."
	fi
}

createAnchorPeerTx() {
	while [ "$#" -gt 0 ]; do
		local orgmsp=$1
		infoln "Generating anchor peer update transaction for ${orgmsp}"
		set -x
		configtxgen -profile ${CHANNEL_PROFILE} -outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}
		res=$?
		{ set +x; } 2>/dev/null
		if [ $res -ne 0 ]; then
			fatalln "Failed to generate anchor peer update transaction for ${orgmsp}..."
		fi
		shift
	done
}

createChannel() {

	setGlobals $1 $2 $3 $4 $5
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.${SERV_NM}.com -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA >&log.txt
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
	verifyResult $res "After $MAX_RETRY attempts, ${PEER_NM}.${ORG_ADDR} has failed to join channel '$CHANNEL_NAME' "
}

updateAnchorPeers() {
	setGlobals $1 $2 $3 $4 $5
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
		peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.${SERV_NM}.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&log.txt
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

FABRIC_CFG_PATH=${PWD}/configtx

## Create channeltx
infoln "Generating channel create transaction '${CHANNEL_NAME}.tx'"
createChannelTx

## Create anchorpeertx
infoln "Generating anchor peer update transactions"
createAnchorPeerTx Cafe1MSP

## Create channel
infoln "Creating channel ${CHANNEL_NAME}"
createChannel cafe1 Cafe1 peer0 Admin 7051

## Join all the peers to the channel
infoln "Join Cafe1 peers to the channel..."
joinChannel cafe1 Cafe1 peer0 Admin 7051

## Set the anchor peers for each org in the channel
infoln "Updating anchor peers for cafe1..."
updateAnchorPeers cafe1 Cafe1 peer0 Admin 7051

successln "Channel successfully joined"

exit 0
