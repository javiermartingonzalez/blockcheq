pragma solidity ^0.4.18;

import "./BlockcheqCore.sol";

contract BankStore is BlockcheqCore {
    function add(bytes32 code, bytes32[2] name, address bankAddress, address contractAddress) public;
    function getByCode(bytes32 _code) public view returns (uint index, bytes32 code, bytes32[2] name, address bankAddress, address contractAddress, bool authorized, bool exists);
    function getContract(bytes32 _code) public view returns (address);
    function getByHash(bytes32 codeHash) public view returns (uint index, bytes32 code, bytes32[2] name, address bankAddress, address contractAddress, bool authorized, bool exists);
    function getByAddress(address bankOwner) public view returns (uint index, bytes32 code, bytes32[2] name, address bankAddress, address contractAddress, bool authorized, bool exists);    
    function getHashByIndex(uint index) public view returns (bytes32);    
    function count() public view returns (uint);
    function update(bytes32 code, bytes32[2] name, address bankAddress, address contractAddress, bool authorized) public;
    function disable(bytes32 code) public;
    function enable(bytes32 code) public;
    function setCodeLocation(uint codePosition, uint codeLength) public;
    function getCodeLocation() public view returns (uint codePosition, uint codeLength);
}
