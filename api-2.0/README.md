
## Preface

As mentioned before this node application base on the work of https://github.com/adhavpavan/BasicNetwork-2.0.
The application is able to send commands to the Hyperledger Fabric network and acts as a client application. 
The application acts as a client for all organization and thus peers, meaning that it is possible to connect to every peer.
The connection parameters are generated and stored by a script in the test-network 
(`testnetwork/scripts/replaceConnectionfiles.sh`), meaning that the credentials are replaced automatically if the network is restartet.


## Running the node application and Api descripton 

The application is started with the command `node app.js`.
The Apis can triggerd with cURL commands or with the Postman collection commands (./postman-collection)
The application provides six APIs:


Query data 1 
Query data 2 

1. Register User

    To  connect to the respective peer, a registration of the admin and client is required and can be achieved by the user registration command. The credentials are stored in the `./orgX-wallet and retrived if needed. The received token have to be provided in further requests for authorization. In Postman is it easily storeable in the Varaiables in the Authorization section. Thus the token specifies from which organization the client (as this client implements all credentials) triggers the transactions or queries. The name and the organization have to be provided in the request body.  

    http://localhost:4000/users

    Example request Body:

    ```
    {
	"username":"Peter Parker",
	"orgName": "Org1"
    }	
    ```

1. Create a new Project
    
    To create a new project the private data collection is modified in terms of adding a new colltion to the configuration file.
    After the modification the chaincode definition is upgraded. Afterwards the project/ private data collection is accessable.
    Note that the sequence number in the `test-network/scripts/upgradeCCDefinition` have to be increased by one, every time a new chaincode definition is delpoyed. The project name (also the name of the collection referenced later), the stakeholder of the project (organizations who have acces to the data) and the blocktoLive variable have to be provided.
    Note that the path inside the function have to be set, as it is an absolute path. 


    http://localhost:4000/createNewProject

    ```
    {
    "projectName": "projectA",
    "stakeholder":"OR('Org1MSP.member', 'Org4MSP.member', 'Org3MSP.member')",
    "blockToLive": 100000
    }  
    ```


1. Add x80 and x81 data - Due to the endorsement policy constraints the writex80andx81Data scipt has to be used 
`./network.sh writex80andx81Data`

    Add x80 and x81 data to the channel and to the respective private data collection. The argument provides the general data and the transient the private data.

    http://localhost:4000/channels/:channelName/chaincodes/:chaincodeName

    Example reqeust Body: 
    ```
    {
    "fcn": "addX80_X81_data",
    "chaincodeName":"variation_chaincode",
    "channelName": "mychannel",
   "args": ["General Data example"],
   "transient": "{\"variation\":{\"OrdinalNumber\" :\"15\",\"Quantity\":10000,\"Unit\":\"m2\",\"TotalAmount\":1000000,\"Collection\":\"projectM\"}}"
    }
    ```
    
1. Add x84 data - Due to the endorsement policy constraints the writex84Data scipt has to be used `./network.sh writex84Data`.
    The MSPID targets the respective implicit private data collection. There are no args required. 


    http://localhost:4000/channels/:channelName/chaincodes/:chaincodeName

    Example reqeust Body: 
    
    ```
    {
    "fcn": "addX84_data",
    "peers": [],
    "chaincodeName":"variation_chaincode",
    "channelName": "mychannel",
   "args": [],
   "transient": "{\"variation\":{\"OrdinalNumber\" :\"11\",\"UnitPrice\":1000000,\"MSPID\":\"Org2MSP\"}}"
    }
    ```
1. Query general data - to query the channel ledger for general data a peer have to provided and also the argument for which variation number should be queried.  

    http://localhost:4000/channels/mychannel/chaincodes/variation_chaincode?args=[ "21"]&fcn=readGeneralData



1. Query private data - to query the respective private data collection/ implicit private data collection, the name of the PDC/I_PDC have to be provided and the variation number.  

    http://localhost:4000/channels/mychannel/chaincodes/variation_chaincode?args=[ "_implicit_org_Org1MSP","17"]&fcn=readPrivateData
