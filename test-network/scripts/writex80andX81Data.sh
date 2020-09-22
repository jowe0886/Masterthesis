# This script enables the user to write data in the the private data collections of the peers.
# For custom invokes the using Org,the peer adresses and the tlsRootcerts have to be changed accordingly

export PEER0_ORG1_CA=${PWD}organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export PEER0_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export PEER0_ORG4_CA=${PWD}/organizations/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt
export PEER0_ORG5_CA=${PWD}/organizations/peerOrganizations/org5.example.com/peers/peer0.org5.example.com/tls/ca.crt

FABRIC_CFG_PATH=$PWD/../config/


# import utils
. scripts/envVar.sh

writex80andx81Data() {
  ORG=$1
  setGlobals $ORG
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  echo $ORG1_CA
  echo $PWD

  set -x
  export x81_data=$(echo -n "{\"OrdinalNumber\" :\"21\",\"Quantity\":10000,\"Unit\":\"m2\",\"TotalAmount\":1000000,\"Collection\":\"projectC\"}" | base64 | tr -d \\n)
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com  --tls \
   --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem  \
  --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG3_CA --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_ORG4_CA  --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_ORG5_CA \
   -C mychannel -n  variation_chaincode -c '{"Args":["addX80_X81_data","general data"]}' --transient "{\"variation\":\"$x81_data\"}"\
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo
}

writex80andx81Data 3