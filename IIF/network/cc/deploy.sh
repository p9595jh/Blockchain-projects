#!/bin/bash

# import utils
. scripts/envVar.sh
. scripts/utils.sh
. cc/ccfs.sh

CHANNEL_NAME=${1:-"hnchannel"}
CC_NAME=${2}
CC_SRC_PATH=${3}
CC_SRC_LANGUAGE=${4}
CC_VERSION=${5:-"1.0"}
CC_SEQUENCE=${6:-"1"}
CC_INIT_FCN=${7:-"NA"}
CC_END_POLICY=${8:-"NA"}
CC_COLL_CONFIG=${9:-"NA"}
DELAY=${10:-"3"}
MAX_RETRY=${11:-"5"}
VERBOSE=${12:-"false"}

# FABRIC_CFG_PATH=$PWD/configtx
CC_SRC_PATH="../chaincode/codes/$CC_SRC_PATH"

println "executing with the following"
println "- CHANNEL_NAME: ${C_GREEN}${CHANNEL_NAME}${C_RESET}"
println "- CC_NAME: ${C_GREEN}${CC_NAME}${C_RESET}"
println "- CC_SRC_PATH: ${C_GREEN}${CC_SRC_PATH}${C_RESET}"
println "- CC_SRC_LANGUAGE: ${C_GREEN}${CC_SRC_LANGUAGE}${C_RESET}"
println "- CC_VERSION: ${C_GREEN}${CC_VERSION}${C_RESET}"
println "- CC_SEQUENCE: ${C_GREEN}${CC_SEQUENCE}${C_RESET}"
println "- CC_END_POLICY: ${C_GREEN}${CC_END_POLICY}${C_RESET}"
println "- CC_COLL_CONFIG: ${C_GREEN}${CC_COLL_CONFIG}${C_RESET}"
println "- CC_INIT_FCN: ${C_GREEN}${CC_INIT_FCN}${C_RESET}"
println "- DELAY: ${C_GREEN}${DELAY}${C_RESET}"
println "- MAX_RETRY: ${C_GREEN}${MAX_RETRY}${C_RESET}"
println "- VERBOSE: ${C_GREEN}${VERBOSE}${C_RESET}"

#User has not provided a name
if [ -z "$CC_NAME" ] || [ "$CC_NAME" = "NA" ]; then
  fatalln "No chaincode name was provided. Valid call example: ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go"

# User has not provided a path
elif [ -z "$CC_SRC_PATH" ] || [ "$CC_SRC_PATH" = "NA" ]; then
  fatalln "No chaincode path was provided. Valid call example: ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go"

# User has not provided a language
elif [ -z "$CC_SRC_LANGUAGE" ] || [ "$CC_SRC_LANGUAGE" = "NA" ]; then
  fatalln "No chaincode language was provided. Valid call example: ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go"

## Make sure that the path to the chaincode exists
elif [ ! -d "$CC_SRC_PATH" ]; then
  fatalln "Path to chaincode does not exist. Please provide different path."
fi

CC_SRC_LANGUAGE=$(echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:])
CC_PACKAGE_PATH="../chaincode/packages/${CC_NAME}_${CC_VERSION}.tar.gz"

# do some language specific preparation to the chaincode before packaging
if [ "$CC_SRC_LANGUAGE" = "go" ]; then
  CC_RUNTIME_LANGUAGE=golang

  infoln "Vendoring Go dependencies at $CC_SRC_PATH"
  pushd $CC_SRC_PATH
  GO111MODULE=on go mod vendor
  popd
  successln "Finished vendoring Go dependencies"

elif [ "$CC_SRC_LANGUAGE" = "java" ]; then
  CC_RUNTIME_LANGUAGE=java

  infoln "Compiling Java code..."
  pushd $CC_SRC_PATH
  ./gradlew installDist
  popd
  successln "Finished compiling Java code"
  CC_SRC_PATH=$CC_SRC_PATH/build/install/$CC_NAME

elif [ "$CC_SRC_LANGUAGE" = "javascript" ]; then
  CC_RUNTIME_LANGUAGE=node

elif [ "$CC_SRC_LANGUAGE" = "typescript" ]; then
  CC_RUNTIME_LANGUAGE=node

  infoln "Compiling TypeScript code into JavaScript..."
  pushd $CC_SRC_PATH
  npm install
  npm run build
  popd
  successln "Finished compiling TypeScript code into JavaScript"

else
  fatalln "The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script. Supported chaincode languages are: go, java, javascript, and typescript"
  exit 1
fi

INIT_REQUIRED="--init-required"
# check if the init fcn should be called
if [ "$CC_INIT_FCN" = "NA" ]; then
  INIT_REQUIRED=""
fi

if [ "$CC_END_POLICY" = "NA" ]; then
  CC_END_POLICY=""
else
  CC_END_POLICY="--signature-policy $CC_END_POLICY"
fi

if [ "$CC_COLL_CONFIG" = "NA" ]; then
  CC_COLL_CONFIG=""
else
  CC_COLL_CONFIG="--collections-config $CC_COLL_CONFIG"
fi


##################################################################################################################################
##################################################################################################################################
##################################################################################################################################

if [ "$CHANNEL_NAME" = "constructor-channel" ]; then

  param1=("${_ins1_p0_ch0[@]}")
  param2=("${_ins2_p0_ch0[@]}")
  param3=("${_ins3_p0_ch0[@]}")
  param4=("${_ga1_p0_ch0[@]}")
  param5=("${_ga2_p0_ch0[@]}")


  # to remove channel info
unset param1[5]
unset param2[5]
unset param3[5]
unset param4[5]
unset param5[5]

  ## package the chaincode
packageChaincode

  ## Install chaincode
infoln "Installing chaincode on the channel..."
installChaincode ${param1[@]}
installChaincode ${param2[@]}
installChaincode ${param3[@]}
installChaincode ${param4[@]}
installChaincode ${param5[@]}

  ## query whether the chaincode is installed
queryInstalled ${param1[@]}
queryInstalled ${param2[@]}
queryInstalled ${param3[@]}
queryInstalled ${param4[@]}
queryInstalled ${param5[@]}

  ## approve the definition for the channel
approveForMyOrg ${param1[@]}
approveForMyOrg ${param2[@]}
approveForMyOrg ${param3[@]}
approveForMyOrg ${param4[@]}
approveForMyOrg ${param5[@]}

  ## now that we know for sure both orgs have approved, commit the definition
  commitChaincodeDefinition ${param1[@]} ${param2[@]} ${param3[@]} ${param4[@]} ${param5[@]}

  ## query on both orgs to see that the definition committed successfully
queryCommitted ${param1[@]}
queryCommitted ${param2[@]}
queryCommitted ${param3[@]}
queryCommitted ${param4[@]}
queryCommitted ${param5[@]}

  ## Invoke the chaincode - this does require that the chaincode have the `initLedger` method defined
  if [ "$CC_INIT_FCN" = "NA" ]; then
    infoln "Chaincode initialization is not required"
  else
    chaincodeInvokeInit ${param1[@]} ${param2[@]} ${param3[@]} ${param4[@]} ${param5[@]}
  fi

elif [ "$CHANNEL_NAME" = "ga-channel" ]; then

  param1=("${_ins1_p0_ch1[@]}")
  param2=("${_ins2_p0_ch1[@]}")
  param3=("${_ins3_p0_ch1[@]}")
  param4=("${_ga1_p0_ch1[@]}")
  param5=("${_ga2_p0_ch1[@]}")


  # to remove channel info
unset param1[5]
unset param2[5]
unset param3[5]
unset param4[5]
unset param5[5]

  ## package the chaincode
packageChaincode

  ## Install chaincode
infoln "Installing chaincode on the channel..."
installChaincode ${param1[@]}
installChaincode ${param2[@]}
installChaincode ${param3[@]}
installChaincode ${param4[@]}
installChaincode ${param5[@]}

  ## query whether the chaincode is installed
queryInstalled ${param1[@]}
queryInstalled ${param2[@]}
queryInstalled ${param3[@]}
queryInstalled ${param4[@]}
queryInstalled ${param5[@]}

  ## approve the definition for the channel
approveForMyOrg ${param1[@]}
approveForMyOrg ${param2[@]}
approveForMyOrg ${param3[@]}
approveForMyOrg ${param4[@]}
approveForMyOrg ${param5[@]}

  ## now that we know for sure both orgs have approved, commit the definition
  commitChaincodeDefinition ${param1[@]} ${param2[@]} ${param3[@]} ${param4[@]} ${param5[@]}

  ## query on both orgs to see that the definition committed successfully
queryCommitted ${param1[@]}
queryCommitted ${param2[@]}
queryCommitted ${param3[@]}
queryCommitted ${param4[@]}
queryCommitted ${param5[@]}

  ## Invoke the chaincode - this does require that the chaincode have the `initLedger` method defined
  if [ "$CC_INIT_FCN" = "NA" ]; then
    infoln "Chaincode initialization is not required"
  else
    chaincodeInvokeInit ${param1[@]} ${param2[@]} ${param3[@]} ${param4[@]} ${param5[@]}
  fi

elif [ "$CHANNEL_NAME" = "medical-channel" ]; then

  param1=("${_ins1_p0_ch2[@]}")
  param2=("${_ins2_p0_ch2[@]}")
  param3=("${_ins3_p0_ch2[@]}")
  param4=("${_hos1_p0_ch0[@]}")
  param5=("${_hos2_p0_ch0[@]}")
  param6=("${_hos3_p0_ch0[@]}")
  param7=("${_customer_p0_ch1[@]}")


  # to remove channel info
unset param1[5]
unset param2[5]
unset param3[5]
unset param4[5]
unset param5[5]
unset param6[5]
unset param7[5]

  ## package the chaincode
packageChaincode

  ## Install chaincode
infoln "Installing chaincode on the channel..."
installChaincode ${param1[@]}
installChaincode ${param2[@]}
installChaincode ${param3[@]}
installChaincode ${param4[@]}
installChaincode ${param5[@]}
installChaincode ${param6[@]}
installChaincode ${param7[@]}

  ## query whether the chaincode is installed
queryInstalled ${param1[@]}
queryInstalled ${param2[@]}
queryInstalled ${param3[@]}
queryInstalled ${param4[@]}
queryInstalled ${param5[@]}
queryInstalled ${param6[@]}
queryInstalled ${param7[@]}

  ## approve the definition for the channel
approveForMyOrg ${param1[@]}
approveForMyOrg ${param2[@]}
approveForMyOrg ${param3[@]}
approveForMyOrg ${param4[@]}
approveForMyOrg ${param5[@]}
approveForMyOrg ${param6[@]}
approveForMyOrg ${param7[@]}

  ## now that we know for sure both orgs have approved, commit the definition
  commitChaincodeDefinition ${param1[@]} ${param2[@]} ${param3[@]} ${param4[@]} ${param5[@]} ${param6[@]} ${param7[@]}

  ## query on both orgs to see that the definition committed successfully
queryCommitted ${param1[@]}
queryCommitted ${param2[@]}
queryCommitted ${param3[@]}
queryCommitted ${param4[@]}
queryCommitted ${param5[@]}
queryCommitted ${param6[@]}
queryCommitted ${param7[@]}

  ## Invoke the chaincode - this does require that the chaincode have the `initLedger` method defined
  if [ "$CC_INIT_FCN" = "NA" ]; then
    infoln "Chaincode initialization is not required"
  else
    chaincodeInvokeInit ${param1[@]} ${param2[@]} ${param3[@]} ${param4[@]} ${param5[@]} ${param6[@]} ${param7[@]}
  fi

elif [ "$CHANNEL_NAME" = "insurance-channel" ]; then

  param1=("${_ins1_p0_ch3[@]}")
  param2=("${_ins2_p0_ch3[@]}")
  param3=("${_ins3_p0_ch3[@]}")
  param4=("${_ga1_p0_ch2[@]}")
  param5=("${_ga2_p0_ch2[@]}")
  param6=("${_customer_p0_ch2[@]}")


  # to remove channel info
unset param1[5]
unset param2[5]
unset param3[5]
unset param4[5]
unset param5[5]
unset param6[5]

  ## package the chaincode
packageChaincode

  ## Install chaincode
infoln "Installing chaincode on the channel..."
installChaincode ${param1[@]}
installChaincode ${param2[@]}
installChaincode ${param3[@]}
installChaincode ${param4[@]}
installChaincode ${param5[@]}
installChaincode ${param6[@]}

  ## query whether the chaincode is installed
queryInstalled ${param1[@]}
queryInstalled ${param2[@]}
queryInstalled ${param3[@]}
queryInstalled ${param4[@]}
queryInstalled ${param5[@]}
queryInstalled ${param6[@]}

  ## approve the definition for the channel
approveForMyOrg ${param1[@]}
approveForMyOrg ${param2[@]}
approveForMyOrg ${param3[@]}
approveForMyOrg ${param4[@]}
approveForMyOrg ${param5[@]}
approveForMyOrg ${param6[@]}

  ## now that we know for sure both orgs have approved, commit the definition
  commitChaincodeDefinition ${param1[@]} ${param2[@]} ${param3[@]} ${param4[@]} ${param5[@]} ${param6[@]}

  ## query on both orgs to see that the definition committed successfully
queryCommitted ${param1[@]}
queryCommitted ${param2[@]}
queryCommitted ${param3[@]}
queryCommitted ${param4[@]}
queryCommitted ${param5[@]}
queryCommitted ${param6[@]}

  ## Invoke the chaincode - this does require that the chaincode have the `initLedger` method defined
  if [ "$CC_INIT_FCN" = "NA" ]; then
    infoln "Chaincode initialization is not required"
  else
    chaincodeInvokeInit ${param1[@]} ${param2[@]} ${param3[@]} ${param4[@]} ${param5[@]} ${param6[@]}
  fi

elif [ "$CHANNEL_NAME" = "customer-channel" ]; then

  param1=("${_customer_p0_ch0[@]}")


  # to remove channel info
unset param1[5]

  ## package the chaincode
packageChaincode

  ## Install chaincode
infoln "Installing chaincode on the channel..."
installChaincode ${param1[@]}

  ## query whether the chaincode is installed
queryInstalled ${param1[@]}

  ## approve the definition for the channel
approveForMyOrg ${param1[@]}

  ## now that we know for sure both orgs have approved, commit the definition
  commitChaincodeDefinition ${param1[@]}

  ## query on both orgs to see that the definition committed successfully
queryCommitted ${param1[@]}

  ## Invoke the chaincode - this does require that the chaincode have the `initLedger` method defined
  if [ "$CC_INIT_FCN" = "NA" ]; then
    infoln "Chaincode initialization is not required"
  else
    chaincodeInvokeInit ${param1[@]}
  fi

fi


