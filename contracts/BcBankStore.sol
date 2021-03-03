pragma solidity ^0.4.18;

import "./BankStore.sol";

contract BcBankStore is BankStore {

	bytes32[] private bankList;                             // Array of hashes of registered Bank codes 
    mapping (bytes32 => Bank) private bankInfos;            // Key: Bank Code Hash, value: Bank struct
    mapping (address => bytes32) private bankAddresses;     // Key: Bank Eth Address, value: Bank Code Hash.

    uint private codePos;
	uint private codeLen;

    function add(bytes32 _code, bytes32[2] bankName, address bankAddress, address contractAddress) public onlyBy(owner) {
        bytes32 codeHash = keccak256(_code);
        Bank storage newbank = bankInfos[codeHash];
        require(!newbank.exists);    
        
        newbank.code = _code;
        newbank.name = bankName;
        newbank.bankAddress = bankAddress;
        newbank.contractAddress = contractAddress;
        newbank.authorized = true;
        newbank.exists = true;
        
        if (newbank.id == 0){
        	uint idBank = bankList.length;
        	bankList.push(codeHash);
        	newbank.id = idBank;	
        }

        bankAddresses[bankAddress] = codeHash;
    }

    function getHashByIndex(uint index) public view returns (bytes32){
    	require(index < bankList.length);
		return bankList[index];
    }

    function getByCode(bytes32 _code) public view returns(uint, bytes32, bytes32[2], address, address, bool, bool) {
    	bytes32 hashCode = keccak256(_code);
        Bank storage b = bankInfos[hashCode];
        return (b.id, b.code, b.name, b.bankAddress, b.contractAddress, b.authorized, b.exists);
    }

    function getContract(bytes32 _code) public view returns(address) {
        return bankInfos[keccak256(_code)].contractAddress;
    }    

    function getByHash(bytes32 _hash) public view returns(uint, bytes32, bytes32[2], address, address, bool, bool) {
        
        Bank storage b = bankInfos[_hash];
        return (b.id, b.code, b.name, b.bankAddress, b.contractAddress, b.authorized, b.exists);
    }  
    
    function getByAddress(address bankOwner) public view returns(uint, bytes32, bytes32[2], address, address, bool, bool) {
        bytes32 hashCode = bankAddresses[bankOwner];
        Bank storage b = bankInfos[hashCode];
        return (b.id, b.code, b.name, b.bankAddress, b.contractAddress, b.authorized, b.exists);
    }  

     function count() public view returns (uint){
		return bankList.length;
    }  

    function update(bytes32 _code, bytes32[2] bankName, address bankAddress, address contractAddress, bool authorized) public onlyBy(owner){    
    	bytes32 codeHash = keccak256(_code);
    	require(bankInfos[codeHash].exists);

        address oldBankContractAddress = updatedbank.contractAddress;

    	Bank storage updatedbank = bankInfos[codeHash];
    	updatedbank.name = bankName;
        updatedbank.bankAddress = bankAddress;
        updatedbank.contractAddress = contractAddress;
    	updatedbank.authorized = authorized;
        
        bankAddresses[oldBankContractAddress] = bytes32(0);    
        bankAddresses[contractAddress] = codeHash;
    }

    function disable(bytes32 _code) public onlyBy(owner){
		bytes32 codeHash = keccak256(_code);
    	require(bankInfos[codeHash].exists);
    	bankInfos[codeHash].exists = false;

    }

    function enable(bytes32 _code) public onlyBy(owner){
		bytes32 codeHash = keccak256(_code);
    	require(!(bankInfos[codeHash].exists) && (bankInfos[codeHash].code != ''));
    	bankInfos[codeHash].exists = true;

    }

    function setCodeLocation(uint codePosition, uint codeLength) public {
    	require(codeLen==0);
    	codePos = codePosition;
    	codeLen = codeLength;
    }

    function getCodeLocation() public view returns (uint, uint){
        return (codePos,codeLen);
    }

}