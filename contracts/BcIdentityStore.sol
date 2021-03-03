pragma solidity ^0.4.18;

import "./BlockcheqCore.sol";
import "./IdentityStore.sol";

contract BcIdentityStore is IdentityStore {

    struct IdentityReference {
        bytes32 identifier;
        uint index;
        bytes32[2] notifyAddress;
    }  

    struct AddressReference {
        address ethAccount;
        bool exists;
    }

    // Colección de direcciones de notificacion en relación a una identidad
    mapping (bytes32 => bytes32[2]) private notifyIdentifier;

    // Colección de direcciones de cuentas Ethereum de una identidad
    mapping (bytes32 => AddressReference[]) private adressesByIdentifier; // Key: Identifier, Value: Ethereum Addresses Array.

    // Colección auxiliar para localizar una identidad por la cuenta Ethereum
    mapping (address => IdentityReference) private identifierByAddress; // Key: Ethereum Address, Value: Identifier

    function add(bytes32 identifier, address ethAccount, bytes32[2] notifyAddress) public onlyBy(owner) {
        IdentityReference storage idRef = identifierByAddress[ethAccount];
    	require (bytes32(0) == idRef.identifier);
    	idRef.identifier = identifier;
        notifyIdentifier[identifier] = notifyAddress;
    	AddressReference[] storage refs = adressesByIdentifier[identifier];
    	refs.length++;
    	AddressReference storage ref = refs[refs.length-1];
    	ref.ethAccount = ethAccount;
    	ref.exists = true;
        idRef.index = refs.length-1;
    }

    function update(bytes32 identifier, uint index, address ethAccount) public onlyBy(owner) {
    	AddressReference[] storage refs = adressesByIdentifier[identifier];
    	require(refs.length > index);
    	AddressReference storage ref = refs[index];
    	require(ref.exists);
    	identifierByAddress[ref.ethAccount].identifier = bytes32(0);
    	ref.ethAccount = ethAccount;
    	identifierByAddress[ethAccount].identifier = identifier;
    }

    function disable(bytes32 identifier, uint index) public onlyBy(owner) {
    	AddressReference[] storage refs = adressesByIdentifier[identifier];
    	require(refs.length > index);
    	refs[index].exists = false;
    }
      
    function enable(bytes32 identifier, uint index) public onlyBy(owner) {
    	AddressReference[] storage refs = adressesByIdentifier[identifier];
    	require(refs.length > index);
    	refs[index].exists = true;
    }

    function count(bytes32 identifier) public view returns(uint length) {
    	return adressesByIdentifier[identifier].length;
    }
      
    function getAddress(bytes32 identifier, uint index) public view returns(address ethAccount) {
        AddressReference storage ref = adressesByIdentifier[identifier][index];
        require (ref.exists);
    	return adressesByIdentifier[identifier][index].ethAccount;
    }

    function getIdentifier(address ethAccount) public view returns(bytes32 identifier) {
        IdentityReference storage idRef = identifierByAddress[ethAccount];
        require(adressesByIdentifier[idRef.identifier][idRef.index].exists);
    	return identifierByAddress[ethAccount].identifier;
    }

    function getNotifyAddress(bytes32 identifier) public view returns(bytes32[2] notifyAddress){
        return notifyIdentifier[identifier];
    }

    function setNotifyAddress(bytes32 identifier, bytes32[2] notifyAddress) public{
        notifyIdentifier[identifier] = notifyAddress;
    }

}