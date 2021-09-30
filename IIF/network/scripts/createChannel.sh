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
infoln "Generating channel create transaction"
createChannelTx constructor-channel ConstructorChannelProfile
createChannelTx ga-channel GaChannelProfile
createChannelTx medical-channel MedicalChannelProfile
createChannelTx insurance-channel InsuranceChannelProfile
createChannelTx customer-channel CustomerChannelProfile

## Create anchorpeertx
infoln "Generating anchor peer update transactions"
createAnchorPeerTx Ins1MSP constructor-channel ConstructorChannelProfile ConstructorChannelProfile
createAnchorPeerTx Ins1MSP ga-channel GaChannelProfile GaChannelProfile
createAnchorPeerTx Ins1MSP medical-channel MedicalChannelProfile MedicalChannelProfile
createAnchorPeerTx Ins1MSP insurance-channel InsuranceChannelProfile InsuranceChannelProfile
createAnchorPeerTx Ins2MSP constructor-channel ConstructorChannelProfile ConstructorChannelProfile
createAnchorPeerTx Ins2MSP ga-channel GaChannelProfile GaChannelProfile
createAnchorPeerTx Ins2MSP medical-channel MedicalChannelProfile MedicalChannelProfile
createAnchorPeerTx Ins2MSP insurance-channel InsuranceChannelProfile InsuranceChannelProfile
createAnchorPeerTx Ins3MSP constructor-channel ConstructorChannelProfile ConstructorChannelProfile
createAnchorPeerTx Ins3MSP ga-channel GaChannelProfile GaChannelProfile
createAnchorPeerTx Ins3MSP medical-channel MedicalChannelProfile MedicalChannelProfile
createAnchorPeerTx Ins3MSP insurance-channel InsuranceChannelProfile InsuranceChannelProfile
createAnchorPeerTx Ga1MSP constructor-channel ConstructorChannelProfile ConstructorChannelProfile
createAnchorPeerTx Ga1MSP ga-channel GaChannelProfile GaChannelProfile
createAnchorPeerTx Ga1MSP insurance-channel InsuranceChannelProfile InsuranceChannelProfile
createAnchorPeerTx Ga2MSP constructor-channel ConstructorChannelProfile ConstructorChannelProfile
createAnchorPeerTx Ga2MSP ga-channel GaChannelProfile GaChannelProfile
createAnchorPeerTx Ga2MSP insurance-channel InsuranceChannelProfile InsuranceChannelProfile
createAnchorPeerTx Hos1MSP medical-channel MedicalChannelProfile
createAnchorPeerTx Hos2MSP medical-channel MedicalChannelProfile
createAnchorPeerTx Hos3MSP medical-channel MedicalChannelProfile
createAnchorPeerTx CustomerMSP customer-channel CustomerChannelProfile CustomerChannelProfile
createAnchorPeerTx CustomerMSP medical-channel MedicalChannelProfile MedicalChannelProfile
createAnchorPeerTx CustomerMSP insurance-channel InsuranceChannelProfile InsuranceChannelProfile

## Create channel
infoln "Creating channel constructor-channel"
createChannel ${_ins1_p0_ch0[@]}

infoln "Creating channel ga-channel"
createChannel ${_ins1_p0_ch1[@]}

infoln "Creating channel medical-channel"
createChannel ${_ins1_p0_ch2[@]}

infoln "Creating channel insurance-channel"
createChannel ${_ins1_p0_ch3[@]}

infoln "Creating channel customer-channel"
createChannel ${_customer_p0_ch0[@]}

## Join all the peers to the channel
infoln "Join peers to the constructor-channel..."
joinChannel ${_ins1_p0_ch0[@]}
joinChannel ${_ins2_p0_ch0[@]}
joinChannel ${_ins3_p0_ch0[@]}
joinChannel ${_ga1_p0_ch0[@]}
joinChannel ${_ga2_p0_ch0[@]}

infoln "Join peers to the ga-channel..."
joinChannel ${_ins1_p0_ch1[@]}
joinChannel ${_ins2_p0_ch1[@]}
joinChannel ${_ins3_p0_ch1[@]}
joinChannel ${_ga1_p0_ch1[@]}
joinChannel ${_ga2_p0_ch1[@]}

infoln "Join peers to the medical-channel..."
joinChannel ${_ins1_p0_ch2[@]}
joinChannel ${_ins2_p0_ch2[@]}
joinChannel ${_ins3_p0_ch2[@]}
joinChannel ${_hos1_p0_ch0[@]}
joinChannel ${_hos2_p0_ch0[@]}
joinChannel ${_hos3_p0_ch0[@]}
joinChannel ${_customer_p0_ch1[@]}

infoln "Join peers to the insurance-channel..."
joinChannel ${_ins1_p0_ch3[@]}
joinChannel ${_ins2_p0_ch3[@]}
joinChannel ${_ins3_p0_ch3[@]}
joinChannel ${_ga1_p0_ch2[@]}
joinChannel ${_ga2_p0_ch2[@]}
joinChannel ${_customer_p0_ch2[@]}

infoln "Join peers to the customer-channel..."
joinChannel ${_customer_p0_ch0[@]}

## Set the anchor peers for each org in the channel
infoln "Updating anchor peers for constructor-channel..."
updateAnchorPeers ${_ins1_p0_ch0[@]} ConstructorChannelProfile

infoln "Updating anchor peers for ga-channel..."
updateAnchorPeers ${_ins1_p0_ch1[@]} GaChannelProfile

infoln "Updating anchor peers for medical-channel..."
updateAnchorPeers ${_ins1_p0_ch2[@]} MedicalChannelProfile

infoln "Updating anchor peers for insurance-channel..."
updateAnchorPeers ${_ins1_p0_ch3[@]} InsuranceChannelProfile

infoln "Updating anchor peers for customer-channel..."
updateAnchorPeers ${_customer_p0_ch0[@]} CustomerChannelProfile


successln "Channel successfully joined"

exit 0
