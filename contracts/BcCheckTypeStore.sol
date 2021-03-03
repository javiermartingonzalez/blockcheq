pragma solidity ^0.4.18;

import "./CheckTypeStore.sol";

contract BcCheckTypeStore is CheckTypeStore {

    CheckType[] private checkTypeList; // Array of CheckType of registered Check Types

    function add(bytes32[2] name, bytes32 comparator, uint endorses) public onlyBy(owner) {
        CheckType memory newType = CheckType(checkTypeList.length, name, true, comparator, endorses);
        require(!existsType(newType.name));
        checkTypeList.push(newType);
    }

    function update(uint index, bytes32[2] name, bytes32 comparator, uint endorses) public onlyBy(owner) {
    	require(index < checkTypeList.length);
    	require(checkTypeList[index].exists);
    	checkTypeList[index].name = name;
      checkTypeList[index].comparator = comparator;
      checkTypeList[index].endorses = endorses;
    }

    function get(uint index) public view returns (bytes32[2] name, bool exists, bytes32 comparator, uint endorses) {
    	require(index < checkTypeList.length);
        return (checkTypeList[index].name, checkTypeList[index].exists, checkTypeList[index].comparator, checkTypeList[index].endorses);
    }

    function count() public view returns (uint) {
        return checkTypeList.length;
    }

    function disable(uint index) public onlyBy(owner) {
    	require(index < checkTypeList.length);
        checkTypeList[index].exists = false;
    }

    function enable(uint index) public onlyBy(owner) {
    	require(index < checkTypeList.length);
        checkTypeList[index].exists = true;
    }

    function existsType(bytes32[2] name) internal constant returns (bool exists) {
        for (uint j = 0; j < checkTypeList.length; j++)
        {
            if (eqDoubleb32(checkTypeList[j].name, name)) {
                exists = true;
                break;
            }
        }
        return exists;
    }

}
