# delete old connection files 
rm ../api-2.0/config/connection-org1.json
rm ../api-2.0/config/connection-org2.json
rm ../api-2.0/config/connection-org3.json
rm ../api-2.0/config/connection-org4.json
rm ../api-2.0/config/connection-org5.json

cp ./organizations/peerOrganizations/org1.example.com/connection-org1.json ../api-2.0/config/
cp ./organizations/peerOrganizations/org2.example.com/connection-org2.json ../api-2.0/config/
cp ./organizations/peerOrganizations/org3.example.com/connection-org3.json ../api-2.0/config/
cp ./organizations/peerOrganizations/org4.example.com/connection-org4.json ../api-2.0/config/
cp ./organizations/peerOrganizations/org5.example.com/connection-org5.json ../api-2.0/config/

# delete old credentials
rm -r ../api-2.0/org1-wallet
rm -r ../api-2.0/org2-wallet

mkdir ../api-2.0/org1-wallet
mkdir ../api-2.0/org2-wallet