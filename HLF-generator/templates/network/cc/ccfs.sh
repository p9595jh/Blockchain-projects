#!/bin/bash
#
# chaincode functions

. scripts/envVar.sh
. scripts/utils.sh

packageChaincode() {
	set -x
	#peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
	# peer lifecycle chaincode package $CC_PACKAGE_PATH --path $CC_SRC_PATH --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
	peer lifecycle chaincode package $CC_PACKAGE_PATH --path $CC_SRC_PATH --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME} >&log.txt
	res=$?
	{ set +x; } 2>/dev/null
	cat log.txt
	verifyResult $res "Chaincode packaging has failed"
	successln "Chaincode is packaged"
}

# installChaincode PEER ORG
installChaincode() {
	local ORG_ADDR=$1
	local ORG_NM=$2
	local PEER_NM=$3
	local ADMIN_NM=$4
	local P0PORT=$5
	setGlobals $ORG_ADDR $ORG_NM $PEER_NM $ADMIN_NM $P0PORT

	set -x
	peer lifecycle chaincode install $CC_PACKAGE_PATH >&log.txt
	res=$?
	{ set +x; } 2>/dev/null
	cat log.txt
	verifyResult $res "Chaincode installation on ${PEER_NM}.${ORG_ADDR} has failed"
	successln "Chaincode is installed on ${PEER_NM}.${ORG_ADDR}"
}

# queryInstalled PEER ORG
queryInstalled() {
	local ORG_ADDR=$1
	local ORG_NM=$2
	local PEER_NM=$3
	local ADMIN_NM=$4
	local P0PORT=$5

	setGlobals $ORG_ADDR $ORG_NM $PEER_NM $ADMIN_NM $P0PORT

	set -x
	peer lifecycle chaincode queryinstalled >&log.txt
	res=$?
	{ set +x; } 2>/dev/null
	cat log.txt
	PACKAGE_ID=$(sed -n "/${CC_NAME}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
	verifyResult $res "Query installed on ${PEER_NM}.${ORG_ADDR} has failed"
	successln "Query installed successful on ${PEER_NM}.${ORG_ADDR} on channel"
}

# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
	local ORG_ADDR=$1
	local ORG_NM=$2
	local PEER_NM=$3
	local ADMIN_NM=$4
	local P0PORT=$5

	setGlobals $ORG_ADDR $ORG_NM $PEER_NM $ADMIN_NM $P0PORT

	set -x
	peer lifecycle chaincode approveformyorg -o localhost:{{CHAINCODE_CCFS_ORDERER_PORT}} --ordererTLSHostnameOverride ${ORDERER_NM}.${SERV_NM}.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
	res=$?
	{ set +x; } 2>/dev/null
	cat log.txt
	verifyResult $res "Chaincode definition approved on ${PEER_NM}.${ORG_ADDR} on channel '$CHANNEL_NAME' failed"
	successln "Chaincode definition approved on ${PEER_NM}.${ORG_ADDR} on channel '$CHANNEL_NAME'"
}

# remove checkCommitReadiness

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
	parsePeerConnectionParameters $@
	res=$?
	verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

	set -x
	peer lifecycle chaincode commit -o localhost:{{CHAINCODE_CCFS_ORDERER_PORT}} --ordererTLSHostnameOverride ${ORDERER_NM}.${SERV_NM}.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} $PEER_CONN_PARMS --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
	res=$?
	{ set +x; } 2>/dev/null
	cat log.txt
	verifyResult $res "Chaincode definition commit failed on channel '$CHANNEL_NAME' failed"
	successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}


# queryCommitted ORG
queryCommitted() {

	local ORG_ADDR=$1
	local ORG_NM=$2
	local PEER_NM=$3
	local ADMIN_NM=$4
	local P0PORT=$5

	setGlobals $ORG_ADDR $ORG_NM $PEER_NM $ADMIN_NM $P0PORT
	EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
	infoln "Querying chaincode definition on ${PEER_NM}.${ORG_ADDR} on channel '$CHANNEL_NAME'..."

	local rc=1
	local COUNTER=1

	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
		sleep $DELAY
		infoln "Attempting to Query committed status on ${PEER_NM}.${ORG_ADDR}, Retry after $DELAY seconds."
		set -x
		peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: '$CC_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
		test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	if test $rc -eq 0; then
		successln "Query chaincode definition successful on ${PEER_NM}.${ORG_ADDR} on channel '$CHANNEL_NAME'"
	else
		fatalln "After $MAX_RETRY attempts, Query chaincode definition result on ${PEER_NM}.${ORG_ADDR} is INVALID!"
	fi
}


chaincodeInvokeInit() {
	parsePeerConnectionParameters $@
	res=$?
	verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

	set -x
	fcn_call='{"function":"'${CC_INIT_FCN}'","Args":[]}'
	infoln "invoke fcn call:${fcn_call}"
	peer chaincode invoke -o localhost:{{CHAINCODE_CCFS_ORDERER_PORT}} --ordererTLSHostnameOverride ${ORDERER_NM}.${SERV_NM}.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} $PEER_CONN_PARMS --isInit -c ${fcn_call} >&log.txt
	res=$?
	{ set +x; } 2>/dev/null
	cat log.txt
	verifyResult $res "Invoke execution on $PEERS failed"
	successln "Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME'"
}

# not used
chaincodeQuery() {
	local ORG_ADDR=$1
	local ORG_NM=$2
	local PEER_NM=$3
	local ADMIN_NM=$4
	local P0PORT=$5
	setGlobals $ORG_ADDR $ORG_NM $PEER_NM $ADMIN_NM $P0PORT

	infoln "Querying on ${PEER_NM}.${ORG_ADDR} on channel '$CHANNEL_NAME'..."
	local rc=1
	local COUNTER=1

	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
		sleep $DELAY
		infoln "Attempting to Query ${PEER_NM}.${ORG_ADDR}, Retry after $DELAY seconds."
		set -x
		peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["queryAllCars"]}' >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	if test $rc -eq 0; then
		successln "Query successful on ${PEER_NM}.${ORG_ADDR} on channel '$CHANNEL_NAME'"
	else
		fatalln "After $MAX_RETRY attempts, Query result on ${PEER_NM}.${ORG_ADDR} is INVALID!"
	fi
}
