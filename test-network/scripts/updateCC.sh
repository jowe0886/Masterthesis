
CHANNEL_NAME="$1"
CC_SRC_LANGUAGE="$2"
VERSION="$3"
DELAY="$4"
MAX_RETRY="$5"
VERBOSE="$6"
: ${CHANNEL_NAME:="mychannel"}
: ${CC_SRC_LANGUAGE:="golang"}
: ${VERSION:="1"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`

FABRIC_CFG_PATH=$PWD/../config/


# import utils
. scripts/envVar.sh



# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
  ORG=$1
  setGlobals $ORG
  echo test 
  echo $CORE_PEER_TLS_ENABLED 
  echo $ORDERER_CA
  echo $CHANNEL_NAME
  echo ${VERSION}
  echo ${PACKAGE_ID}
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name marbles02_private \
  --version ${VERSION} --collections-config ../chaincode/marbles02_private/collections_config_1.json \
  --sequence '2' >&log.txt
  set +x
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
  echo
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
  ORG=$1
  shift 1
  setGlobals $ORG
  echo "===================== Checking the commit readiness of the chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to check the commit readiness of the chaincode definition on peer0.org${ORG} secs"
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name marbles02_private \
     --collections-config ../chaincode/marbles02_private/collections_config_1.json  --version ${VERSION} \
     --sequence '2' --output json  >&log.txt    
    res=$?
    set +x
    let rc=0
    for var in "$@"
    do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
		COUNTER=$(expr $COUNTER + 1)
	done
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Checking the commit readiness of the chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Check commit readiness result on peer0.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED \
  --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name marbles02_private $PEER_CONN_PARMS \
  --version ${VERSION}  --collections-config ../chaincode/marbles02_private/collections_config_1.json \
  --sequence '2' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition committed on channel '$CHANNEL_NAME' ===================== "
  echo
}

# queryCommitted ORG
queryCommitted() {
  ORG=$1
  setGlobals $ORG
  EXPECTED_RESULT="Version: ${VERSION}, Sequence: 2, Endorsement Plugin: escc, Validation Plugin: vscc"
  echo "===================== Querying chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name marbles02_private >&log.txt
    res=$?
    set +x
		test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: [0-9], Sequence: [0-9], Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query chaincode definition result on peer0.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

# chaincodeInvokeInit() {
#   parsePeerConnectionParameters $@
#   res=$?
#   verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

#   # while 'peer chaincode' command can get the orderer endpoint from the
#   # peer (if join was successful), let's supply it directly as we know
#   # it using the "-o" option
#   set -x
#   peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n marbles02_private $PEER_CONN_PARMS --isInit -c '{"Args":["Init"]}' >&log.txt
#   res=$?
#   set +x
#   cat log.txt
#   verifyResult $res "Invoke execution on $PEERS failed "
#   echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
#   echo
# }

chaincodeInvokeInitMarble() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  export MARBLE=$(echo -n "{\"name\":\"marble1\",\"color\":\"red\",\"size\":35,\"owner\":\"tom\",\"price\":29}" | base64 | tr -d \\n)
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com  --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem  -C mychannel -n  marbles02_private -c '{"Args":["initMarble"]}' --transient "{\"marble\":\"$MARBLE\"}"
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo
}

chaincodeInvokeInitMarbleIPDC() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  export MARBLE=$(echo -n "{\"name\":\"marble2\",\"color\":\"red\",\"size\":35,\"owner\":\"tom\",\"price\":29}" | base64 | tr -d \\n)
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com  --tls \
   --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem  \
   -C mychannel -n  marbles02_private_1 -c '{"Args":["putPrivateData"]}' --transient "{\"marble\":\"$MARBLE\"}"\
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo
}

getChanncelInfo() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "getInfo "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer channel getinfo -c mychannel
  res=$?
  set +x
 
}

chaincodeQuery() {
  ORG=$1
  setGlobals $ORG
  echo "===================== Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query peer0.org${ORG} ...$(($(date +%s) - starttime)) secs"
    set -x
    peer chaincode query -C $CHANNEL_NAME -n marbles02_private -c '{"Args":["readMarblePrivateDetails","marble1"]}' >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query result on peer0.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

#approve the definition for org1
approveForMyOrg 1
approveForMyOrg 2
approveForMyOrg 3
approveForMyOrg 4
approveForMyOrg 5

# # # # # check whether the chaincode definition is ready to be committed
# # # # # expect them both to have approved
 checkCommitReadiness 1 
# # # checkCommitReadiness 2

# # # # # # now that we know for sure both orgs have approved, commit the definition
 commitChaincodeDefinition 1 2 3 4 5 


# # ## query on both orgs to see that the definition committed successfully
  queryCommitted 1
  queryCommitted 2
  queryCommitted 3
  queryCommitted 4
  queryCommitted 5


## Invoke the chaincode - init function 
# chaincodeInvokeInit 1 2 3 4 5 

# sleep 20

# Invoke the chaincode - store data

#chaincodeInvokeInitMarble 1

# Invoke chainode -put private data into implicit private data collection org1

#getChanncelInfo 1

# chaincodeInvokeInitMarbleIPDC 2


# sleep 3

# Query chaincode on peer0.org1
# echo "Querying chaincode on peer0.org1..."
# chaincodeQuery 1
# echo "Querying chaincode on peer0.org2..."
# chaincodeQuery 2
# echo "Querying chaincode on peer0.org3..."
# chaincodeQuery 3
# echo "Querying chaincode on peer0.org4..."
# chaincodeQuery 4
# echo "Querying chaincode on peer0.org5..."
# chaincodeQuery 5
# exit 0
