pragma solidity ^0.4.18;

import "./BlockcheqCore.sol";

contract ReceiverStore is BlockcheqCore {

    function add(bytes32 deliveredIdentifier, bytes32 bankCode, bytes32 hashCodeline, uint version) public;
    function update(bytes32 deliveredIdentifier, uint index, bytes32 hashCodeline, uint version) public;

    function addAddressNumber(address ownerAddress, bytes32[2] number, bytes32 bankCode) public;
    function getAddressNumber(address) public view returns (bytes32[2]);

    function count(bytes32 deliveredIdentifier) public view returns(uint length);
    function get(bytes32 deliveredIdentifier, uint index) public view returns(bytes32 bankCode, bytes32 hashCodeline, uint version);
    function getWithCodeline(bytes32 deliveredIdentifier, uint index) public view returns(bytes32 bankCode, bytes32[2] codeline, uint version);
    function getIndex(bytes32 deliveredIdentifier, bytes32 hashCodeline) public view returns(uint index, bool exists);

    function getCheckBase(bytes32 hashCodeline) public view returns (bytes32[2] codeline, bytes32 owner, uint256 amount, uint processDate, uint version, uint checkType, bytes32 certifier);
    function getCheckVersion(bytes32 hashCodeline) public view returns (CheckStatus status, bytes32[2] memory depositAccount, bytes32[2] memory deliveredTo, bytes32[2] memory reason, bytes32[2] memory securityCode, uint timestamp, bytes32 deliveredIdentifier);
    function getCheckVersion(bytes32 hashCodeline, uint version) public view returns (CheckStatus status, bytes32[2] memory depositAccount, bytes32[2] memory deliveredTo, bytes32[2] memory reason, bytes32[2] memory securityCode, uint timestamp, bytes32 deliveredIdentifier);
    function getOwnerAddress(bytes32 hashCodeline) public view returns (address owner);
    function updateCheck(bytes32[2] codeline, uint256 amount, uint processDate, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32 securityCode, bytes32 newSecurityCode, bytes32 deliveredIdentifier, bytes32 certifier) public;
    function updateCheckByHash(bytes32 codelineHash, uint256 amount, uint processDate, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32 securityCode, bytes32 newSecurityCode, bytes32 deliveredIdentifier, bytes32 certifier) public;

    function setMustNotifyReceiver(bytes32[2] codeline) public;
    function cleanMustNotifyReceiver(bytes32[2] codeline) public;
    function getMustNotifyReceiver(bytes32[2] codeline) view public returns (bool);
}
