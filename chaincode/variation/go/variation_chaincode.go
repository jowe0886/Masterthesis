/*
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-chaincode-go/pkg/cid"
	pb "github.com/hyperledger/fabric-protos-go/peer"
)

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
}

// General information -x80

type x80 struct {
	OrdinalNumber      string `json:"OrdinalNumber"`
	GeneralInformation string `json:"GeneralInformation"`
}

// Construction work description - x81
type x81 struct {
	OrdinalNumber string `json:"OrdinalNumber"`
	Quantity      int    `json:"Quantity"`
	Unit          string `json:"Unit"`
	TotalAmount   int    `json:"TotalAmount"`
}

// Variation offer - x84
type x84 struct {
	OrdinalNumber string `json:"OrdinalNumber"`
	UnitPrice     int    `json:"Unitprice"`
}

func main() {
	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	fmt.Println("invoke is running " + function)

	switch function {
	case "addX80_X81_data":
		//create new x80 and 81 data
		return t.addX80_X81_data(stub, args)
	case "addX84_data":
		//create a new x84 data
		return t.addX84Data(stub, args)
	case "readGeneralData":
		//read general x80 data
		return t.readGeneralData(stub, args)
	case "readPrivateData":
		//read private data
		return t.readPrivateData(stub, args)

	default:
		//error
		fmt.Println("invoke did not find func: " + function)
		return shim.Error("Received unknown function invocation")
	}
}

// ============================================================
// addX80_X81_data  - create new x80 and x81 data
// ============================================================

func (t *SimpleChaincode) addX80_X81_data(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var err error

	type x81TransientInput struct {
		OrdinalNumber string `json:"OrdinalNumber"`
		Quantity      int    `json:"Quantity"`
		Unit          string `json:"Unit"`
		TotalAmount   int    `json:"TotalAmount"`
		Collection    string `json:"Collection"`
	}

	type result struct {
		OrdinalNumber string `json:"OrdinalNumber"`
		GeneralData   string `json:"GeneralData"`
		Quantity      int    `json:"Quantity"`
		Unit          string `json:"Unit"`
		TotalAmount   int    `json:"TotalAmount"`
	}

	fmt.Println("- start init x80_x81_data")

	// === Save x81 data to state ===

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. General data is required and private data must be passed in transient map.")
	}

	transMap, err := stub.GetTransient()
	if err != nil {
		return shim.Error("Error getting transient: " + err.Error())
	}

	x81TransientJsonBytes, ok := transMap["variation"]
	if !ok {
		return shim.Error("variation must be a key in the transient map")
	}

	if len(x81TransientJsonBytes) == 0 {
		return shim.Error("variation value in the transient map must be a non-empty JSON string")
	}

	var x81Input x81TransientInput
	err = json.Unmarshal(x81TransientJsonBytes, &x81Input)
	if err != nil {
		return shim.Error("Failed to decode JSON of: " + string(x81TransientJsonBytes))
	}
	if len(x81Input.OrdinalNumber) == 0 {
		return shim.Error("OrdinalNumber field must be a non-empty string")
	}
	if x81Input.Quantity == 0 {
		return shim.Error("Quantity must be higher than 0")
	}
	if len(x81Input.Unit) == 0 {
		return shim.Error("unit field must be a non-empty string")
	}
	if x81Input.TotalAmount == 0 {
		return shim.Error("TotalAmount field must be a positive integer")
	}

	// ==== Check if x81 data already exists ====
	x81JsonBytes, err := stub.GetPrivateData(x81Input.Collection, x81Input.OrdinalNumber)
	if err != nil {
		return shim.Error("Failed to get x81Input: " + err.Error())
	} else if x81JsonBytes != nil {
		fmt.Println("This x81 data already exists: " + x81Input.OrdinalNumber)
		return shim.Error("This x81 data already exists: " + x81Input.OrdinalNumber)
	}

	// ==== Create x81 object, marshal to JSON, and save to state ====
	x81 := &x81{
		OrdinalNumber: x81Input.OrdinalNumber,
		Quantity:      x81Input.Quantity,
		Unit:          x81Input.Unit,
		TotalAmount:   x81Input.TotalAmount,
	}

	fmt.Println(x81)

	x81JSONasBytes, err := json.Marshal(x81)
	if err != nil {
		return shim.Error("Tja das wars" + err.Error())
	}
	fmt.Println(x81)

	err = stub.PutPrivateData(x81Input.Collection, x81Input.OrdinalNumber, x81JSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	// === Save x80 data to state ===

	x80_data := args[0]

	// ==== Check if boq already exists ====
	x80_dataAsBytes, err := stub.GetState(x81Input.OrdinalNumber)
	if err != nil {
		return shim.Error("Failed to get boq: " + err.Error())
	} else if x80_dataAsBytes != nil {
		fmt.Println("This boq already exists: " + x81Input.OrdinalNumber)
		return shim.Error("This boq already exists: " + x81Input.OrdinalNumber)
	}

	// ==== Create x80 object and marshal to JSON ====

	x80 := &x80{x81Input.OrdinalNumber, x80_data}

	x80JSONasBytes, err := json.Marshal(x80)
	if err != nil {
		return shim.Error(err.Error())
	}

	// === Save x80 data to state ===
	err = stub.PutState(x81Input.OrdinalNumber, x80JSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	resultStruct := &result{
		OrdinalNumber: x81Input.OrdinalNumber,
		GeneralData:   x80_data,
		Quantity:      x81Input.Quantity,
		Unit:          x81Input.Unit,
		TotalAmount:   x81Input.TotalAmount,
	}

	resultasBytes, err := json.Marshal(resultStruct)
	if err != nil {
		return shim.Error(err.Error())
	}

	fmt.Println("- end init data")
	return shim.Success(resultasBytes)

}

// ============================================================
// addX84Data  - create x84 data
// ============================================================

func (t *SimpleChaincode) addX84Data(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var err error

	type x84TransientInput struct {
		OrdinalNumber string `json:"OrdinalNumber"`
		UnitPrice     int    `json:"UnitPrice"`
		MSPID         string `json:"MSPID"`
	}

	fmt.Println("adding x84 data")

	transMap, err := stub.GetTransient()
	if err != nil {
		return shim.Error("Error getting transient: " + err.Error())
	}

	x84JsonBytes, ok := transMap["variation"]
	if !ok {
		return shim.Error("variation must be a key in the transient map")
	}

	if len(x84JsonBytes) == 0 {
		return shim.Error("variation value in the transient map must be a non-empty JSON string")
	}

	var x84Input x84TransientInput
	err = json.Unmarshal(x84JsonBytes, &x84Input)
	if err != nil {
		return shim.Error("Failed to decode JSON of: " + string(x84JsonBytes))
	}

	// ==== Create x84 data object, marshal to JSON, and save to state ====
	x84 := &x84{
		OrdinalNumber: x84Input.OrdinalNumber,
		UnitPrice:     x84Input.UnitPrice,
	}

	x84JSONasBytes, err := json.Marshal(x84)
	if err != nil {
		return shim.Error(err.Error())
	}

	//target an I_PDC ->  _implicit_org_<MSPID>

	MSPID := x84Input.MSPID

	err = stub.PutPrivateData("_implicit_org_"+MSPID, x84Input.OrdinalNumber, x84JSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	invokerMSP, err := cid.GetMSPID(stub)

	fmt.Println("put data in the invokers collection" + invokerMSP)

	err = stub.PutPrivateData("_implicit_org_"+invokerMSP, x84Input.OrdinalNumber, x84JSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	fmt.Println("end adding x84 data")
	fmt.Println(x84.UnitPrice)

	return shim.Success(x84JSONasBytes)
}

// ===============================================
// readGeneralData - read a readGeneralData from chaincode state
// ===============================================
func (t *SimpleChaincode) readGeneralData(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var key, jsonResp string
	var err error

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting name of the readGeneralData to query")
	}

	key = args[0]
	valAsbytes, err := stub.GetState(key) //get the readGeneralData from chaincode state
	if err != nil {
		jsonResp = "{\"Error\":\"Failed to get state for " + key + ": " + err.Error() + "\"}"
		return shim.Error(jsonResp)
	} else if valAsbytes == nil {
		jsonResp = "{\"Error\":\"Gener data does not exist: " + key + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(valAsbytes)
}

// ===============================================
// readPrivateData - read private details from chaincode state
// ===============================================
func (t *SimpleChaincode) readPrivateData(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var key, collection, jsonResp string
	var err error

	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting name of the private data to query")
	}

	collection = args[0]
	key = args[1]
	valAsbytes, err := stub.GetPrivateData(collection, key) //get the private data from chaincode state
	if err != nil {
		jsonResp = "{\"Error\":\"Failed to get private details for " + key + ": " + err.Error() + "\"}"
		return shim.Error(jsonResp)
	} else if valAsbytes == nil {
		jsonResp = "{\"Error\":\"private data does not exist: " + key + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(valAsbytes)
}
