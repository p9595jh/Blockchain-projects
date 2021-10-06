#!/bin/bash

. scripts/utils.sh

# export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false


function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    infoln "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}


function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    infoln "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

# Versions of fabric known not to work with the test network
NONWORKING_VERSIONS="^1\.0\. ^1\.1\. ^1\.2\. ^1\.3\. ^1\.4\."


function checkPrereqs() {
  ## Check if your have cloned the peer binaries and configuration files.
  peer version > /dev/null 2>&1

  # use the fabric tools container to see if the samples and binaries match your
  # docker images
  LOCAL_VERSION=$(peer version | sed -ne 's/ Version: //p')
  DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)

  infoln "LOCAL_VERSION=$LOCAL_VERSION"
  infoln "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

  if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    warnln "Local fabric binaries and docker images are out of sync. This may cause problems."
  fi

  for UNSUPPORTED_VERSION in $NONWORKING_VERSIONS; do
    infoln "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      errorln "ERROR! Local Fabric binary version of $LOCAL_VERSION does not match the versions supported by the test network."
      exit 1
    fi

    infoln "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      errorln "ERROR! Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match the versions supported by the test network."
      exit 1
    fi
  done

  ## Check for fabric-ca
  if [ "$CRYPTO" == "Certificate Authorities" ]; then

    fabric-ca-client version > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      errorln "ERROR! fabric-ca-client binary not found.."
      errorln "Follow the instructions in the Fabric docs to install the Fabric Binaries:"
      errorln "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
      exit 1
    fi
    CA_LOCAL_VERSION=$(fabric-ca-client version | sed -ne 's/ Version: //p')
    CA_DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-ca:$CA_IMAGETAG fabric-ca-client version | sed -ne 's/ Version: //p' | head -1)
    infoln "CA_LOCAL_VERSION=$CA_LOCAL_VERSION"
    infoln "CA_DOCKER_IMAGE_VERSION=$CA_DOCKER_IMAGE_VERSION"

    if [ "$CA_LOCAL_VERSION" != "$CA_DOCKER_IMAGE_VERSION" ]; then
      warnln "Local fabric-ca binaries and docker images are out of sync. This may cause problems."
    fi
  fi
}

# to set env variables for registering
function orgEnv {
  ORG_ADDR=$1
  CAPORT=$2
  ADDR=${ORG_ADDR}.${SERV_NM}.com
  regiParams=($ORG_ADDR $ADDR $CAPORT)
}

# Create Organziation crypto material using cryptogen or CAs
function createOrgs() {

  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  infoln "Generate certificates using Fabric CA's"
  IMAGE_TAG=${CA_IMAGETAG} docker-compose -f $COMPOSE_FILE_CA up -d 2>&1

  . organizations/fabric-ca/registerEnroll.sh
  sleep 3

  infoln "Create Ins1 Identites"

  orgEnv ins1 7054
  createOrg $SERV_NM $ORG_ADDR $CAPORT
  registerPeer ${regiParams[@]} peer0
  registerUser ${regiParams[@]} user1 User1
  registerAdmin ${regiParams[@]} ${ORG_ADDR}admin Admin

  infoln "Create Ins2 Identites"

  orgEnv ins2 8054
  createOrg $SERV_NM $ORG_ADDR $CAPORT
  registerPeer ${regiParams[@]} peer0
  registerUser ${regiParams[@]} user1 User1
  registerAdmin ${regiParams[@]} ${ORG_ADDR}admin Admin

  infoln "Create Ins3 Identites"

  orgEnv ins3 9054
  createOrg $SERV_NM $ORG_ADDR $CAPORT
  registerPeer ${regiParams[@]} peer0
  registerUser ${regiParams[@]} user1 User1
  registerAdmin ${regiParams[@]} ${ORG_ADDR}admin Admin

  infoln "Create Ga1 Identites"

  orgEnv ga1 10054
  createOrg $SERV_NM $ORG_ADDR $CAPORT
  registerPeer ${regiParams[@]} peer0
  registerUser ${regiParams[@]} user1 User1
  registerAdmin ${regiParams[@]} ${ORG_ADDR}admin Admin

  infoln "Create Ga2 Identites"

  orgEnv ga2 11054
  createOrg $SERV_NM $ORG_ADDR $CAPORT
  registerPeer ${regiParams[@]} peer0
  registerUser ${regiParams[@]} user1 User1
  registerAdmin ${regiParams[@]} ${ORG_ADDR}admin Admin

  infoln "Create Hos1 Identites"

  orgEnv hos1 12054
  createOrg $SERV_NM $ORG_ADDR $CAPORT
  registerPeer ${regiParams[@]} peer0
  registerUser ${regiParams[@]} user1 User1
  registerAdmin ${regiParams[@]} ${ORG_ADDR}admin Admin

  infoln "Create Hos2 Identites"

  orgEnv hos2 13054
  createOrg $SERV_NM $ORG_ADDR $CAPORT
  registerPeer ${regiParams[@]} peer0
  registerUser ${regiParams[@]} user1 User1
  registerAdmin ${regiParams[@]} ${ORG_ADDR}admin Admin

  infoln "Create Hos3 Identites"

  orgEnv hos3 14054
  createOrg $SERV_NM $ORG_ADDR $CAPORT
  registerPeer ${regiParams[@]} peer0
  registerUser ${regiParams[@]} user1 User1
  registerAdmin ${regiParams[@]} ${ORG_ADDR}admin Admin

  infoln "Create Customer Identites"

  orgEnv customer 15054
  createOrg $SERV_NM $ORG_ADDR $CAPORT
  registerPeer ${regiParams[@]} peer0
  registerUser ${regiParams[@]} user1 User1
  registerAdmin ${regiParams[@]} ${ORG_ADDR}admin Admin

  infoln "Create Orderer Org Identities"
  createOrdererOrg ${SERV_NM} 16054 orderer

  # generate connection profile
  infoln "Generate CCP files for organizations"
  ./organizations/ccp-generate.sh ${SERV_NM} ins1 Ins1 7051 7054 peer0
  ./organizations/ccp-generate.sh ${SERV_NM} ins2 Ins2 8051 8054 peer0
  ./organizations/ccp-generate.sh ${SERV_NM} ins3 Ins3 9051 9054 peer0
  ./organizations/ccp-generate.sh ${SERV_NM} ga1 Ga1 10051 10054 peer0
  ./organizations/ccp-generate.sh ${SERV_NM} ga2 Ga2 11051 11054 peer0
  ./organizations/ccp-generate.sh ${SERV_NM} hos1 Hos1 12051 12054 peer0
  ./organizations/ccp-generate.sh ${SERV_NM} hos2 Hos2 13051 13054 peer0
  ./organizations/ccp-generate.sh ${SERV_NM} hos3 Hos3 14051 14054 peer0
  ./organizations/ccp-generate.sh ${SERV_NM} customer Customer 15051 15054 peer0

}


# Generate orderer system channel genesis block.
function createConsortium() {

  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatalln "configtxgen tool not found. exiting"
    exit 1
  fi

  infoln "Generating Orderer Genesis block"

  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  set -x
  configtxgen -profile $NETWORK_PROFILE -channelID $SYS_CHANNEL -outputBlock ./system-genesis-block/genesis.block
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    fatalln $'\e[1;32m'"Failed to generate orderer genesis block..."$'\e[0m'
    exit 1
  fi
}


# Bring up the peer and orderer nodes using docker compose.
function networkUp() {

  checkPrereqs
  # generate artifacts if they don't exist
  if [ ! -d "organizations/peerOrganizations" ]; then
    createOrgs
    createConsortium
  fi

  COMPOSE_FILES="-f ${COMPOSE_FILE_BASE}"

  if [ "${DATABASE}" == "couchdb" ]; then
    COMPOSE_FILES="${COMPOSE_FILES} -f ${COMPOSE_FILE_COUCH}"
  fi

  IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1

  docker ps -a
  if [ $? -ne 0 ]; then
    errorln "Unable to start network"
    exit 1
  fi
}


function createChannel() {

  if [ ! -d "organizations/peerOrganizations" ]; then
    infoln "Bringing up network"
    networkUp
  fi

  scripts/createChannel.sh $CHANNEL_NAME $CLI_DELAY $MAX_RETRY $VERBOSE
  if [ $? -ne 0 ]; then
    errorln "Create channel failed"
    exit 1
  fi
}


## Call the script to isntall and instantiate a chaincode on the channel
function deployCC() {

  cc/deploy.sh $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CC_SRC_LANGUAGE $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE $INSTALL_CASE

  if [ $? -ne 0 ]; then
    errorln "Deploying chaincode failed"
    exit 1
  fi

  exit 0
}


# Tear down running network
function networkDown() {
  docker-compose -f $COMPOSE_FILE_BASE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA down --volumes --remove-orphans
  if [ "$MODE" != "restart" ]; then
    clearContainers
    removeUnwantedImages
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ins1/msp organizations/fabric-ca/ins1/tls-cert.pem organizations/fabric-ca/ins1/ca-cert.pem organizations/fabric-ca/ins1/IssuerPublicKey organizations/fabric-ca/ins1/IssuerRevocationPublicKey organizations/fabric-ca/ins1/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ins2/msp organizations/fabric-ca/ins2/tls-cert.pem organizations/fabric-ca/ins2/ca-cert.pem organizations/fabric-ca/ins2/IssuerPublicKey organizations/fabric-ca/ins2/IssuerRevocationPublicKey organizations/fabric-ca/ins2/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ins3/msp organizations/fabric-ca/ins3/tls-cert.pem organizations/fabric-ca/ins3/ca-cert.pem organizations/fabric-ca/ins3/IssuerPublicKey organizations/fabric-ca/ins3/IssuerRevocationPublicKey organizations/fabric-ca/ins3/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ga1/msp organizations/fabric-ca/ga1/tls-cert.pem organizations/fabric-ca/ga1/ca-cert.pem organizations/fabric-ca/ga1/IssuerPublicKey organizations/fabric-ca/ga1/IssuerRevocationPublicKey organizations/fabric-ca/ga1/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ga2/msp organizations/fabric-ca/ga2/tls-cert.pem organizations/fabric-ca/ga2/ca-cert.pem organizations/fabric-ca/ga2/IssuerPublicKey organizations/fabric-ca/ga2/IssuerRevocationPublicKey organizations/fabric-ca/ga2/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/hos1/msp organizations/fabric-ca/hos1/tls-cert.pem organizations/fabric-ca/hos1/ca-cert.pem organizations/fabric-ca/hos1/IssuerPublicKey organizations/fabric-ca/hos1/IssuerRevocationPublicKey organizations/fabric-ca/hos1/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/hos2/msp organizations/fabric-ca/hos2/tls-cert.pem organizations/fabric-ca/hos2/ca-cert.pem organizations/fabric-ca/hos2/IssuerPublicKey organizations/fabric-ca/hos2/IssuerRevocationPublicKey organizations/fabric-ca/hos2/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/hos3/msp organizations/fabric-ca/hos3/tls-cert.pem organizations/fabric-ca/hos3/ca-cert.pem organizations/fabric-ca/hos3/IssuerPublicKey organizations/fabric-ca/hos3/IssuerRevocationPublicKey organizations/fabric-ca/hos3/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/customer/msp organizations/fabric-ca/customer/tls-cert.pem organizations/fabric-ca/customer/ca-cert.pem organizations/fabric-ca/customer/IssuerPublicKey organizations/fabric-ca/customer/IssuerRevocationPublicKey organizations/fabric-ca/customer/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'

  fi

  # remove all containers
  docker ps -aq
  if [ $? -ne 0 ]; then
    docker stop $(docker ps -aq)
    docker rm $(docker ps -aq)
  fi
  docker ps

  # remove all volumes
  docker volume prune -f
  docker volume ls
}


OS_ARCH=$(echo "$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# Using crpto vs CA. default is cryptogen
# CRYPTO="cryptogen"
CRYPTO="Certificate Authorities"
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
MAX_RETRY=5
# default for delay between commands
CLI_DELAY=3
# channel name defaults to "mychannel"
# CHANNEL_NAME="mychannel"
CHANNEL_NAME="hnchannel"
# chaincode name defaults to "basic"
CC_NAME="basic"
# chaincode path defaults to "NA"
CC_SRC_PATH="NA"
# endorsement policy defaults to "NA". This would allow chaincodes to use the majority default policy.
CC_END_POLICY="NA"
# collection configuration defaults to "NA"
CC_COLL_CONFIG="NA"
# chaincode init function defaults to "NA"
CC_INIT_FCN="NA"
# use this as the default docker-compose yaml definition
COMPOSE_FILE_BASE=docker/docker-compose-net.yaml
# docker-compose.yaml file if you are using couchdb
COMPOSE_FILE_COUCH=docker/docker-compose-couch.yaml
# certificate authorities compose file
COMPOSE_FILE_CA=docker/docker-compose-ca.yaml
# use this as the docker compose couch file for org3
COMPOSE_FILE_COUCH_ORG3=addOrg3/docker/docker-compose-couch-org3.yaml
# use this as the default docker-compose yaml definition for org3
COMPOSE_FILE_ORG3=addOrg3/docker/docker-compose-org3.yaml
#
# use go as the default language for chaincode
CC_SRC_LANGUAGE="go"
# Chaincode version
CC_VERSION="1.0"
# Chaincode definition sequence
CC_SEQUENCE=1
# default image tag
IMAGETAG="latest"
# default ca image tag
CA_IMAGETAG="latest"
# default database
# DATABASE="leveldb"
DATABASE="couchdb"

# Parse commandline args

## Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

# parse a createChannel subcommand if used
if [[ $# -ge 1 ]] ; then
  key="$1"
  if [[ "$key" == "createChannel" ]]; then
      export MODE="createChannel"
      shift
  fi
fi

# parse flags
while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ca )
    CRYPTO="Certificate Authorities"
    ;;
  -r )
    MAX_RETRY="$2"
    shift
    ;;
  -d )
    CLI_DELAY="$2"
    shift
    ;;
  -s )
    DATABASE="$2"
    shift
    ;;
  -ccl )
    CC_SRC_LANGUAGE="$2"
    shift
    ;;
  -ccn )
    CC_NAME="$2"
    shift
    ;;
  -ccv )
    CC_VERSION="$2"
    shift
    ;;
  -ccs )
    CC_SEQUENCE="$2"
    shift
    ;;
  -ccp )
    CC_SRC_PATH="$2"
    shift
    ;;
  -ccep )
    CC_END_POLICY="$2"
    shift
    ;;
  -cccg )
    CC_COLL_CONFIG="$2"
    shift
    ;;
  -cci )
    CC_INIT_FCN="$2"
    shift
    ;;
  -i )
    IMAGETAG="$2"
    shift
    ;;
  -cai )
    CA_IMAGETAG="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    shift
    ;;
  * )
    errorln "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

# Are we generating crypto material with this command?
if [ ! -d "organizations/peerOrganizations" ]; then
  CRYPTO_MODE="with crypto from '${CRYPTO}'"
else
  CRYPTO_MODE=""
fi

# Determine mode of operation and printing out what we asked for
if [ "$MODE" == "up" ]; then
  infoln "Starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE}' ${CRYPTO_MODE}"
elif [ "$MODE" == "createChannel" ]; then
  infoln "Creating channel '${CHANNEL_NAME}'."
  infoln "If network is not up, starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE} ${CRYPTO_MODE}"
elif [ "$MODE" == "down" ]; then
  infoln "Stopping network"
elif [ "$MODE" == "restart" ]; then
  infoln "Restarting network"
elif [ "$MODE" == "deployCC" ]; then
  infoln "deploying chaincode on channel '${CHANNEL_NAME}'"
else
  printHelp
  exit 1
fi

if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "createChannel" ]; then
  createChannel
elif [ "${MODE}" == "deployCC" ]; then
  deployCC
elif [ "${MODE}" == "down" ]; then
  networkDown
elif [ "${MODE}" == "restart" ]; then
  networkDown
  networkUp
else
  printHelp
  exit 1
fi