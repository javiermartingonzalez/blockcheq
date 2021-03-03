pragma solidity ^0.4.18;

import "./BlockcheqCore.sol";

contract IdentityStore is BlockcheqCore {

    function add(bytes32 identifier, address ethAccount, bytes32[2] notifyAddress) public;    
    function update(bytes32 identifier, uint index, address ethAccount) public;    
    function disable(bytes32 identifier, uint index) public;
    function enable(bytes32 identifier, uint index) public;

    function count(bytes32 identifier) public view returns(uint length);
    function getAddress(bytes32 identifier, uint index) public view returns(address ethAccount);
    function getIdentifier(address ethAccount) public view returns(bytes32 identifier);
    function getNotifyAddress(bytes32 identifier) public view returns (bytes32[2] notifyAddress);
    function setNotifyAddress(bytes32 identifier, bytes32[2] notifyAddress) public;

}