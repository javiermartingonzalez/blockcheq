pragma solidity ^0.4.18;

import "./BlockcheqCore.sol";

contract CheckTypeStore is BlockcheqCore {

    function add(bytes32[2] name, bytes32 comparator, uint maxEndorse) public;
    function update(uint index, bytes32[2] name, bytes32 comparator, uint maxEndorse) public;
    function count() public view returns(uint length);
    function get(uint index) public view returns(bytes32[2] name, bool exists, bytes32 comparator, uint maxEndorse);
    function enable(uint index) public;
    function disable(uint index) public;

}
