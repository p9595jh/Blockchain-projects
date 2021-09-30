#!/bin/bash

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[0;33m'

SERV_NM='hn'
SYS_CHANNEL='system-channel'
NETWORK_PROFILE='HnNetworkProfile'

_ins1_p0_ch0=(ins1 Ins1 peer0 Admin 7051 constructor-channel)
_ins1_p0_ch1=(ins1 Ins1 peer0 Admin 7051 ga-channel)
_ins1_p0_ch2=(ins1 Ins1 peer0 Admin 7051 medical-channel)
_ins1_p0_ch3=(ins1 Ins1 peer0 Admin 7051 insurance-channel)
_ins2_p0_ch0=(ins2 Ins2 peer0 Admin 8051 constructor-channel)
_ins2_p0_ch1=(ins2 Ins2 peer0 Admin 8051 ga-channel)
_ins2_p0_ch2=(ins2 Ins2 peer0 Admin 8051 medical-channel)
_ins2_p0_ch3=(ins2 Ins2 peer0 Admin 8051 insurance-channel)
_ins3_p0_ch0=(ins3 Ins3 peer0 Admin 9051 constructor-channel)
_ins3_p0_ch1=(ins3 Ins3 peer0 Admin 9051 ga-channel)
_ins3_p0_ch2=(ins3 Ins3 peer0 Admin 9051 medical-channel)
_ins3_p0_ch3=(ins3 Ins3 peer0 Admin 9051 insurance-channel)
_ga1_p0_ch0=(ga1 Ga1 peer0 Admin 10051 constructor-channel)
_ga1_p0_ch1=(ga1 Ga1 peer0 Admin 10051 ga-channel)
_ga1_p0_ch2=(ga1 Ga1 peer0 Admin 10051 insurance-channel)
_ga2_p0_ch0=(ga2 Ga2 peer0 Admin 11051 constructor-channel)
_ga2_p0_ch1=(ga2 Ga2 peer0 Admin 11051 ga-channel)
_ga2_p0_ch2=(ga2 Ga2 peer0 Admin 11051 insurance-channel)
_hos1_p0_ch0=(hos1 Hos1 peer0 Admin 12051 medical-channel)
_hos2_p0_ch0=(hos2 Hos2 peer0 Admin 13051 medical-channel)
_hos3_p0_ch0=(hos3 Hos3 peer0 Admin 14051 medical-channel)
_customer_p0_ch0=(customer Customer peer0 Admin 15051 customer-channel)
_customer_p0_ch1=(customer Customer peer0 Admin 15051 medical-channel)
_customer_p0_ch2=(customer Customer peer0 Admin 15051 insurance-channel)

# Print the usage message
function printHelp() {
  USAGE="$1"
  if [ "$USAGE" == "up" ]; then
    println "Usage: "
    println "  network.sh \033[0;32mup\033[0m [Flags]"
    println
    println "    Flags:"
    println "    -ca <use CAs> -  Use Certificate Authorities to generate network crypto material"
    println "    -c <channel name> - Name of channel to create (defaults to \"mychannel\")"
    println "    -s <dbtype> - Peer state database to deploy: goleveldb (default) or couchdb"
    println "    -r <max retry> - CLI times out after certain number of attempts (defaults to 5)"
    println "    -d <delay> - CLI delays for a certain number of seconds (defaults to 3)"
    println "    -verbose - Verbose mode"
    println
    println "    -h - Print this message"
    println
    println " Possible Mode and flag combinations"
    println "   \033[0;32mup\033[0m -ca -r -d -s -verbose"
    println "   \033[0;32mup createChannel\033[0m -ca -c -r -d -s -verbose"
    println
    println " Examples:"
    println "   network.sh up createChannel -ca -c mychannel -s couchdb "
  elif [ "$USAGE" == "createChannel" ]; then
    println "Usage: "
    println "  network.sh \033[0;32mcreateChannel\033[0m [Flags]"
    println
    println "    Flags:"
    println "    -c <channel name> - Name of channel to create (defaults to \"mychannel\")"
    println "    -r <max retry> - CLI times out after certain number of attempts (defaults to 5)"
    println "    -d <delay> - CLI delays for a certain number of seconds (defaults to 3)"
    println "    -verbose - Verbose mode"
    println
    println "    -h - Print this message"
    println
    println " Possible Mode and flag combinations"
    println "   \033[0;32mcreateChannel\033[0m -c -r -d -verbose"
    println
    println " Examples:"
    println "   network.sh createChannel -c channelName"
  elif [ "$USAGE" == "deployCC" ]; then
    println "Usage: "
    println "  network.sh \033[0;32mdeployCC\033[0m [Flags]"
    println
    println "    Flags:"
    println "    -c <channel name> - Name of channel to deploy chaincode to"
    println "    -ccn <name> - Chaincode name."
    println "    -ccl <language> - Programming language of chaincode to deploy: go, java, javascript, typescript"
    println "    -ccv <version>  - Chaincode version. 1.0 (default), v2, version3.x, etc"
    println "    -ccs <sequence>  - Chaincode definition sequence. Must be an integer, 1 (default), 2, 3, etc"
    println "    -ccp <path>  - File path to the chaincode."
    println "    -ccep <policy>  - (Optional) Chaincode endorsement policy using signature policy syntax. The default policy requires an endorsement from Org1 and Org2"
    println "    -cccg <collection-config>  - (Optional) File path to private data collections configuration file"
    println "    -cci <fcn name>  - (Optional) Name of chaincode initialization function. When a function is provided, the execution of init will be requested and the function will be invoked."
    println
    println "    -h - Print this message"
    println
    println " Possible Mode and flag combinations"
    println "   \033[0;32mdeployCC\033[0m -ccn -ccl -ccv -ccs -ccp -cci -r -d -verbose"
    println
    println " Examples:"
    println "   network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-javascript/ ./ -ccl javascript"
    println "   network.sh deployCC -ccn mychaincode -ccp ./user/mychaincode -ccv 1 -ccl javascript"
  else
    println "Usage: "
    println "  network.sh <Mode> [Flags]"
    println "    Modes:"
    println "      \033[0;32mup\033[0m - Bring up Fabric orderer and peer nodes. No channel is created"
    println "      \033[0;32mup createChannel\033[0m - Bring up fabric network with one channel"
    println "      \033[0;32mcreateChannel\033[0m - Create and join a channel after the network is created"
    println "      \033[0;32mdeployCC\033[0m - Deploy a chaincode to a channel (defaults to asset-transfer-basic)"
    println "      \033[0;32mdown\033[0m - Bring down the network"
    println
    println "    Flags:"
    println "    Used with \033[0;32mnetwork.sh up\033[0m, \033[0;32mnetwork.sh createChannel\033[0m:"
    println "    -ca <use CAs> -  Use Certificate Authorities to generate network crypto material"
    println "    -c <channel name> - Name of channel to create (defaults to \"mychannel\")"
    println "    -s <dbtype> - Peer state database to deploy: goleveldb (default) or couchdb"
    println "    -r <max retry> - CLI times out after certain number of attempts (defaults to 5)"
    println "    -d <delay> - CLI delays for a certain number of seconds (defaults to 3)"
    println "    -verbose - Verbose mode"
    println
    println "    Used with \033[0;32mnetwork.sh deployCC\033[0m"
    println "    -c <channel name> - Name of channel to deploy chaincode to"
    println "    -ccn <name> - Chaincode name."
    println "    -ccl <language> - Programming language of the chaincode to deploy: go, java, javascript, typescript"
    println "    -ccv <version>  - Chaincode version. 1.0 (default), v2, version3.x, etc"
    println "    -ccs <sequence>  - Chaincode definition sequence. Must be an integer, 1 (default), 2, 3, etc"
    println "    -ccp <path>  - File path to the chaincode."
    println "    -ccep <policy>  - (Optional) Chaincode endorsement policy using signature policy syntax. The default policy requires an endorsement from Org1 and Org2"
    println "    -cccg <collection-config>  - (Optional) File path to private data collections configuration file"
    println "    -cci <fcn name>  - (Optional) Name of chaincode initialization function. When a function is provided, the execution of init will be requested and the function will be invoked."
    println
    println "    -h - Print this message"
    println
    println " Possible Mode and flag combinations"
    println "   \033[0;32mup\033[0m -ca -r -d -s -verbose"
    println "   \033[0;32mup createChannel\033[0m -ca -c -r -d -s -verbose"
    println "   \033[0;32mcreateChannel\033[0m -c -r -d -verbose"
    println "   \033[0;32mdeployCC\033[0m -ccn -ccl -ccv -ccs -ccp -cci -r -d -verbose"
    println
    println " Examples:"
    println "   network.sh up createChannel -ca -c mychannel -s couchdb"
    println "   network.sh createChannel -c channelName"
    println "   network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-javascript/ -ccl javascript"
    println "   network.sh deployCC -ccn mychaincode -ccp ./user/mychaincode -ccv 1 -ccl javascript"
  fi
}

# println echos string
function println() {
  echo -e "$1"
}

# errorln echos i red color
function errorln() {
  println "${C_RED}${1}${C_RESET}"
}

# successln echos in green color
function successln() {
  println "${C_GREEN}${1}${C_RESET}"
}

# infoln echos in blue color
function infoln() {
  println "${C_BLUE}${1}${C_RESET}"
}

# warnln echos in yellow color
function warnln() {
  println "${C_YELLOW}${1}${C_RESET}"
}

# fatalln echos in red color and exits with fail status
function fatalln() {
  errorln "$1"
  exit 1
}

function printDiv() {
  echo -e "${C_GREEN}"
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' +
  echo -e "$1"
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' +
  echo -e "${C_RESET}"
}

function waits {
    if [ $# -eq 0 ]; then
        printDiv "Wait 3 seconds..."
    else
        printDiv "$1"
    fi
    sleep 3
}

export -f errorln
export -f successln
export -f infoln
export -f warnln
