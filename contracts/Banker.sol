pragma solidity ^0.4.18;

import "./BlockcheqCore.sol";
import "./AccountStore.sol";
import "./CheckStore.sol";
import "./CheckManager.sol";
import "./IdentityStore.sol";


contract Banker is BlockcheqCore {

	AccountStore private accountStore;
	CheckStore private checkStore;
  CheckManager private checkManager;
  IdentityStore private identityStore;


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Funciones de asignación de contratos de almacenamiento y gestión.

    function setAccountContract(address accountAddress) public {
      accountStore = AccountStore(accountAddress);
    }

    function setCheckContract(address checkAddress) public {
      checkStore = CheckStore(checkAddress);
    }

    function setCheckManagerContract(address checkManagerAddress) public {
      checkManager = CheckManager(checkManagerAddress);
    }

    function setIdentityStore(address contractAddress) public {
      identityStore = IdentityStore(contractAddress);
    }

    function getAccountContract() public view returns(address) {
      return address(accountStore);
    }

    function getCheckContract() public view returns(address) {
      return address(checkStore);
    }

    function getCheckManagerContract() public view returns(address) {
      return address(checkManager);
    }

    function getIdentityStore() public view returns (address) {
      return address(identityStore);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Funciones de almacenamiento de identidades.

    function getIdentityNotifyAddress(string identifier) public view returns(string){
      bytes32[2] memory notifyAddress;
      notifyAddress = identityStore.getNotifyAddress(str2B32(identifier));
      return doubleb322Str(notifyAddress);
    }

    function setIdentityNotifyAddress(string identifier, string notifyAddress) public {
      identityStore.setNotifyAddress(str2B32(identifier), str2DoubleB32(notifyAddress));
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Funciones de gestion de cuentas

    function addAccount(address accountOwner, string accountNumber, uint256 accountBalance) public {
    	accountStore.add(accountOwner, str2DoubleB32(accountNumber), accountBalance);
    }

    function getAccountByAddress(address accountOwner) public view returns (address owner, string, uint256 balance, bool exists) {
      bytes32[2] memory numberB32;
      (owner, numberB32, balance, exists) = accountStore.getByAddress(accountOwner);
      return (owner, doubleb322Str(numberB32), balance, exists);
    }

    function getAccountByNumber(string accountNumber) public view returns (address owner, string, uint256 balance, bool exists) {
      bytes32[2] memory numberB32;
      (owner, numberB32, balance, exists) = accountStore.getByNumber(str2DoubleB32(accountNumber));
      return (owner, doubleb322Str(numberB32), balance, exists);
    }

    function getAccountByHash(bytes32 accountHash) public view returns (address owner, string, uint256 balance, bool exists) {
      bytes32[2] memory numberB32;
      (owner, numberB32, balance, exists) = accountStore.getByHash(accountHash);
      return (owner, doubleb322Str(numberB32), balance, exists);
    }

    function getAccountHashByIndex(uint index) public view returns (bytes32) {
      bytes32 accountB32 = accountStore.getHashByIndex(index);
      return (accountB32);
    }

    function getAccountHashByOwner(address owner) public view returns (bytes32) {
      bytes32 accountB32 = accountStore.getHashByOwner(owner);
      return (accountB32);
    }

    function accountCount() public view returns (uint) {
      return accountStore.count();
    }

    function updateAccount(address accountOwner, string accountNumber, uint256 accountBalance) public {
      return accountStore.update(accountOwner, str2DoubleB32(accountNumber), accountBalance);
    }

    function disableAccount(string accountNumber) public {
      return accountStore.disable(str2DoubleB32(accountNumber));
    }

    function enableAccount(string accountNumber) public {
      return accountStore.enable(str2DoubleB32(accountNumber));
    }

    function getBankCode() public view returns(string code) {
      return b322Str(checkStore.getCode());
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Funciones de gestion de cheques

    function addCheck(string accountNumber, string codeline, uint checkType, string certifier) public {
      return checkManager.addCheck(str2DoubleB32(accountNumber), str2DoubleB32(codeline), checkType, str2B32(certifier));
    }

    function getCheckIndex(string codeline) public view returns (uint checkIdx) {
      return checkStore.getIndex(str2DoubleB32(codeline));
    }

    function getBase(string _codeline) public view returns (bytes32 owner,  uint256 amount, uint processDate, uint version, uint checkType, string) {
      bytes32 _certifier;

      (owner, amount,processDate,version, checkType, _certifier) = checkStore.getBase(str2DoubleB32(_codeline));
      return (owner, amount, processDate, version, checkType, b322Str(_certifier));
    }

    function getBaseByHash(bytes32 _codelineHash) public view returns (string, bytes32 owner, uint256 amount, uint processDate, uint version, uint checkType, string) {
      bytes32[2] memory _codeline;
      bytes32 _certifier;
      (_codeline, owner, amount, processDate, version, checkType, _certifier) = checkStore.getBaseByHash(_codelineHash);
      return (doubleb322Str(_codeline), owner, amount, processDate, version, checkType, b322Str(_certifier));
    }

    function getVersion(string _codeline,uint version) public view returns (CheckStatus status, string depositAccount, string deliveredTo, string reason, bytes32[2] securityCode, uint timestamp, string identifier) {
      bytes32[2][3] memory strings;// 0 - depositAccount; 1 - deliveredTo; 2 - reason;
      CheckStatus _status;
      bytes32 _identifier;

      ( _status,
        strings[0],
        strings[1],
        strings[2],
        securityCode,
        timestamp,
        _identifier) = checkStore.getVersion(str2DoubleB32(_codeline), version);

      return (_status,
        doubleb322Str(strings[0]),
        doubleb322Str(strings[1]),
        doubleb322Str(strings[2]),
        securityCode,
        timestamp,
        b322Str(_identifier) );
    }

    function getVersionByHash(bytes32 codelineHash, uint version) public view returns (CheckStatus status, string depositAccount, string deliveredTo, string reason, bytes32[2] securityCode, uint timestamp, string identifier) {
      bytes32[2][3] memory strings;// 0 - depositAccount; 1 - deliveredTo; 2 - reason;
      CheckStatus _status;
      bytes32 _identifier;

      ( _status,
        strings[0],
        strings[1],
        strings[2],
        securityCode,
        timestamp,
        _identifier) = checkStore.getVersionByHash(codelineHash, version);

        return (_status,
        doubleb322Str(strings[0]),
        doubleb322Str(strings[1]),
        doubleb322Str(strings[2]),
        securityCode,
        timestamp,
        b322Str(_identifier) );
    }

    function getBaseByIndex(string accountNumber, uint index) public view returns (string, bytes32 owner,  uint256 amount, uint processDate, uint version, uint checkType, string) {
      bytes32[2] memory _codeline;
      bytes32 _certifier;
      (_codeline, owner, amount, processDate, version, checkType, _certifier) = checkStore.getBaseByIndex(str2DoubleB32(accountNumber), index);

      return(doubleb322Str(_codeline),   owner, amount, processDate, version, checkType, b322Str(_certifier));
    }

    function updateCheck(string codeline, uint256 amount, uint processDate, CheckStatus status, string depositAccount, string deliveredTo, string reason, string securityCode, string newSecurityCode, string identifier, string certifier) public {
      checkManager.setStatus(str2DoubleB32(codeline),
        amount,
        processDate,
        status,
        str2DoubleB32(depositAccount),
        str2DoubleB32(deliveredTo),
        str2DoubleB32(reason),
        str2B32(securityCode),
        str2B32(newSecurityCode),
        str2B32(identifier),
        str2B32(certifier));
    }

    function isCheckOwner(bytes32 codelineHash, address user) public view returns (bool) {
      return checkStore.isOwner(codelineHash, user);
    }

    function isCheckDest(bytes32 codelineHash, uint versionIndex, address user) public view returns (bool) {
      return checkStore.isDest(codelineHash, versionIndex, user);
    }

    function getChecksCount(string accountNumber) public view returns (uint count) {
      return checkStore.getAccountChecksCount(str2DoubleB32(accountNumber));
    }

    function setNotified(string codeline, CheckStatus status) public {
      checkStore.setNotified(str2DoubleB32(codeline), status);
    }

    function isNotified(string codeline, CheckStatus status) public view returns (bool) {
      return checkStore.isNotified(str2DoubleB32(codeline), status);
    }

    function cleanNotified(string codeline, CheckStatus status) public {
      checkStore.cleanNotified(str2DoubleB32(codeline), status);
    }

		function setMustNotifyReceiver(string codeline) public {
      checkStore.setMustNotifyReceiver(str2DoubleB32(codeline));
    }

		function cleanMustNotifyReceiver(string codeline) public {
      checkStore.cleanMustNotifyReceiver(str2DoubleB32(codeline));
    }

		function getMustNotifyReceiver(string codeline) public view returns (bool) {
      return checkStore.getMustNotifyReceiver(str2DoubleB32(codeline));
    }

}
