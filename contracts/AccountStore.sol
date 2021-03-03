pragma solidity ^0.4.18;

import "./BlockcheqCore.sol";

contract AccountStore is BlockcheqCore {
    function add(address accountOwner, bytes32[2] accountNumber, uint256 accountBalance) public;
    function getByAddress(address accountOwner) public view returns (address owner, bytes32[2] number, uint256 balance, bool exists);
    function getByNumber(bytes32[2] accountNumber) public view returns (address owner, bytes32[2] number, uint256 balance, bool exists);
    function getByHash(bytes32 accountHash) public view returns (address owner, bytes32[2] number, uint256 balance, bool exists);
    function getHashByIndex(uint index) public view returns (bytes32);
    function getHashByOwner(address owner) public view returns (bytes32);
    function count() public view returns (uint);
    function update(address accountOwner, bytes32[2] accountNumber, uint256 accountBalance) public;
    function disable(bytes32[2] accountNumber) public;
    function enable(bytes32[2] accountNumber) public;
}
