pragma solidity ^0.4.18;

import "./AccountStore.sol";
import "./AuthorizedBank.sol";

contract BcAccountStore is AccountStore, AuthorizedBank {

    address internal checkStoreAddress;

    mapping(bytes32 => Account) private accounts;       
    mapping(address => bytes32) private accountByOwner; 
    bytes32[] private accountByIndex;

    function setCheckStoreAddress(address _checkStoreAddress) public onlyBy(owner)  {
        checkStoreAddress = _checkStoreAddress;
    }   

    function add(address accountOwner, bytes32[2] accountNumber, uint256 accountBalance) public onlyBy(owner) authorizedBank {
        bytes32 accHash = keccak256(accountNumber[0], accountNumber[1]);
        Account storage acc = accounts[accHash];
        require(!acc.exists &&  (acc.owner == address(0x0)));
        acc.owner = accountOwner;
        acc.number = accountNumber;
        acc.balance = accountBalance;
        acc.exists = true;
        accountByOwner[accountOwner] = accHash;
        accountByIndex.push(accHash);        
    }

    function update(address accountOwner, bytes32[2] accountNumber, uint256 accountBalance) public onlyBy(owner) authorizedBank{
        bytes32 accHash = keccak256(accountNumber[0], accountNumber[1]);
        Account storage acc = accounts[accHash];
        require(acc.exists);
        accountByOwner[acc.owner] = bytes32(0);
        acc.owner = accountOwner;
        acc.balance = accountBalance;
        accountByOwner[accountOwner] = accHash;   
    }

    function disable(bytes32[2] accountNumber) public onlyBy(owner) authorizedBank {
        Account storage acc = accounts[keccak256(accountNumber[0], accountNumber[1])];
        require(isVisible(acc) && !(acc.owner == address(0x0)));
        acc.exists = false;
    }

    function enable(bytes32[2] accountNumber) public onlyBy(owner) authorizedBank {
        Account storage acc = accounts[keccak256(accountNumber[0], accountNumber[1])];
        require(isVisible(acc) && !(acc.owner == address(0x0)));
        acc.exists = true;
    }

    function getByHash(bytes32 accountHash) public view returns (address owner, bytes32[2] number, uint256 balance, bool exists){
        Account storage acc = accounts[accountHash];
        // require(isVisible(acc));
        // return (acc.owner, acc.number, acc.balance, acc.exists);
        if(isVisible(acc)) {
            return (acc.owner, acc.number, acc.balance, acc.exists);
        } 
        return (acc.owner, acc.number, 0, acc.exists);
    }    


    function getByAddress(address accountOwner) public view returns (address owner, bytes32[2] number, uint256 balance, bool exists) {
        Account storage acc = accounts[(accountByOwner[accountOwner])];
        // require(isVisible(acc));
        // return (acc.owner, acc.number, acc.balance, acc.exists);
        if(isVisible(acc)) {
            return (acc.owner, acc.number, acc.balance, acc.exists);
        } 
        return (acc.owner, acc.number, 0, acc.exists);
    }

    function getByNumber(bytes32[2] accountNumber) public view returns (address owner, bytes32[2] number, uint256 balance, bool exists) {
        Account storage acc = accounts[keccak256(accountNumber[0], accountNumber[1])];
        // require(isVisible(acc));
        // return (acc.owner, acc.number, acc.balance, acc.exists);
        if(isVisible(acc)) {
            return (acc.owner, acc.number, acc.balance, acc.exists);
        } 
        return (acc.owner, acc.number, 0, acc.exists);
    }

    function getHashByIndex(uint index) public view returns (bytes32) {
        return accountByIndex[index];
    }

    function getHashByOwner(address owner) public view returns (bytes32) {
        return accountByOwner[owner];
    }

    function count() public view returns (uint) {
        return accountByIndex.length;
    }

    function isVisible(Account acc) internal view returns(bool) {
        return((tx.origin == owner) || (msg.sender == checkStoreAddress) || (tx.origin == acc.owner));
    }    
}

