pragma solidity ^0.4.18;

import "./BlockcheqCore.sol";

contract TransactionStore is BlockcheqCore {
    function add(bytes32 bankCode, bytes32[2] accountNumber, bytes32 hashCodeline, uint version, CheckStatus status) public;
    function addCustom(bytes32 bankCode, bytes32[2] accountNumber, bytes32 hashCodeline, uint version, CheckStatus status) public;
    function get(bytes32[2] accountNumber, uint transactionIdx) public view returns (bytes32 bankCode, bytes32 hashCodeline, uint version, uint timestamp, CheckStatus status);
    function getByHash(bytes32 accountHash, uint transactionIdx) public view returns (bytes32 bankCode, bytes32 hashCodeline, uint version, uint timestamp, CheckStatus status);
    function getCheckBase(bytes32[2] accountNumber, uint transactionIdx) public view returns (uint checkIdx, bytes32 owner, bytes32[2] memory codeline, uint256 amount, uint processDate, uint version, uint checkType, bytes32 certifier);
    function getCheckBaseByHash(bytes32 accountHash, uint transactionIdx) public view returns (uint checkIdx, bytes32 owner, bytes32[2] memory codeline, uint256 amount, uint processDate, uint version, uint checkType, bytes32 certifier);
    function getCheckVersion(bytes32[2] accountNumber, uint transactionIdx) public view returns (CheckStatus status, bytes32[2] memory depositAccount, bytes32[2] memory deliveredTo, bytes32[2] memory reason, bytes32[2] memory securityCode, uint timestamp, bytes32 deliveredIdentifier);
    function getCheckVersionByHash(bytes32 accountHash, uint transactionIdx) public view returns (CheckStatus status, bytes32[2] memory depositAccount, bytes32[2] memory deliveredTo, bytes32[2] memory reason, bytes32[2] memory securityCode, uint timestamp, bytes32 deliveredIdentifier);
    function getBankHash(bytes32 accountHash) public view returns (bytes32 bankHash);
    function countByAccount(bytes32[2] accountNumber) public view returns (uint length);
    function countByHash(bytes32 accountHash) public view returns (uint length);
    function isAccesible(bytes32 accountHash, uint id) public view returns (bool accesible);
    function getAccountTransactionsLength() public view returns (uint length);
    function getAccountHash(uint index) public view returns (bytes32 hash);
    function getTransactionsLengthByHash(bytes32 accountHash) public view returns(uint length);
}
