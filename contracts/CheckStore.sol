pragma solidity ^0.4.18;

import "./BlockcheqCore.sol";

contract CheckStore is BlockcheqCore {
    function getCode() public view returns(bytes32 code);
    function add(bytes32[2] accountNumber, bytes32[2] codeline, uint checkType, bytes32 certifier) public;
    function getIndex(bytes32[2] _codeline) public view returns (uint index);

    function getBase(bytes32[2] _codeline) public view returns (bytes32 owner, uint256 amount, uint processDate, uint version, uint checkType, bytes32 certifier);

    function getBaseByHash(bytes32 codelineHash) public view returns (bytes32[2] memory codeline, bytes32 owner, uint256 amount, uint processDate, uint version, uint checkType, bytes32 certifier);
    function getBaseByHashIndex(bytes32 codelineHash) public view returns (uint, bytes32[2] memory codeline, bytes32 owner, uint256 amount, uint processDate, uint version, uint checkType, bytes32 certifier);
    function getVersion(bytes32[2] _codeline, uint version) public view returns (CheckStatus status, bytes32[2] memory depositAccount, bytes32[2] memory deliveredTo, bytes32[2] memory reason, bytes32[2] memory securityCode, uint timestamp, bytes32 deliveredIdentifier);
    function getVersionByHash(bytes32 codelineHash, uint version) public view returns (CheckStatus status, bytes32[2] memory depositAccount, bytes32[2] memory deliveredTo, bytes32[2] memory reason, bytes32[2] memory securityCode, uint timestamp, bytes32 deliveredIdentifier);

    function getBaseByIndex(bytes32[2] accountNumber, uint index) public view returns (bytes32[2] codeline, bytes32 owner, uint256 amount, uint processDate, uint version, uint checkType, bytes32 certifier);

    function update(bytes32[2] codeline, uint256 amount, uint processDate, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32[2] securityCode, bytes32 deliveredIdentifier, bytes32 certifier) public;
    function revertVersions(bytes32[2] codeline, uint count) public;

    function updateByHash(bytes32 codelineHash, uint256 amount, uint processDate, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32[2] securityCode, bytes32 deliveredIdentifier, bytes32 certifier) public;
    function revertVersionsByHash(bytes32 codelineHash, uint count) public;
    function isOwner(bytes32 codelineHash, address user) public view returns (bool);
    function isDest(bytes32 codelineHash, uint versionIndex, address user) public view returns (bool);
    function getAccountChecksCount(bytes32[2] accountNumber) public view returns (uint count);
    function getAccountStore() public view returns (address contractAddress);

    function setNotified(bytes32[2] codeline, CheckStatus status) public;
    function isNotified(bytes32[2] codeline, CheckStatus status) view public returns (bool);
    function cleanNotified(bytes32[2] codeline, CheckStatus status) public;

    function setMustNotifyReceiver(bytes32[2] codeline) public;
    function cleanMustNotifyReceiver(bytes32[2] codeline) public;
    function getMustNotifyReceiver(bytes32[2] codeline) view public returns (bool);
}
