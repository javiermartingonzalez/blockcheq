pragma solidity ^0.4.18;


import "./BlockcheqCore.sol";
import "./IdentityStore.sol";
import "./ReceiverStore.sol";
import "./CheckTypeStore.sol";


contract Customer is BlockcheqCore {
  IdentityStore private identityStore;
  ReceiverStore private receiverStore;
  CheckTypeStore private checkTypeStore;

  function setIdentityStore(address contractAddress) public onlyBy(owner) {
    identityStore = IdentityStore(contractAddress);
  }

  function setReceiverStore(address contractAddress) public onlyBy(owner) {
    receiverStore = ReceiverStore(contractAddress);
  }

  function setCheckTypeStore(address contractAddress) public onlyBy(owner) {
    checkTypeStore = CheckTypeStore(contractAddress);
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////////
  // Funciones de almacenamiento de identidades.

  function addIdentity(string identifier, address ethAccount, string notifyAddress) public {
    identityStore.add(str2B32(identifier), ethAccount, str2DoubleB32(notifyAddress));
  }

  function updateIdentity(string identifier, uint index, address ethAccount) public{
    identityStore.update(str2B32(identifier), index, ethAccount);
  }

  function disableIdentity(string identifier, uint index) public{
    identityStore.disable(str2B32(identifier), index);
  }

  function enableIdentity(string identifier, uint index) public{
    identityStore.enable(str2B32(identifier), index);
  }

  function identityCount(string identifier) public view returns(uint length){
    return identityStore.count(str2B32(identifier));
  }

  function getIdentityAddress(string identifier, uint index) public view returns(address ethAccount){
    return identityStore.getAddress(str2B32(identifier), index);
  }

  function getIdentityIdentifier(address ethAccount) public view returns(string identifier) {
    return b322Str(identityStore.getIdentifier(ethAccount));
  }

  function getIdentityNotifyAddress(string identifier) public view returns(string){
    bytes32[2] memory notifyAddress;
    notifyAddress = identityStore.getNotifyAddress(str2B32(identifier));
    return doubleb322Str(notifyAddress);
  }

  function setIdentityNotifyAddress(string identifier, string notifyAddress) public {
    identityStore.setNotifyAddress(str2B32(identifier), str2DoubleB32(notifyAddress));
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////////
  // Funciones de almacenamiento de ReceiversIdentities.

  function countReceived(string deliveredIdentifier) public view returns(uint length) {
    return receiverStore.count(str2B32(deliveredIdentifier));
  }

  function getReceived(string deliveredIdentifier, uint index) public view returns(string bankCode, string codeline, uint version) {
    bytes32[2] memory code;
    bytes32 bank;
    (bank, code, version) = receiverStore.getWithCodeline(str2B32(deliveredIdentifier), index);
    return (b322Str(bank), doubleb322Str(code), version);
  }

  function getReceivedIndex(string deliveredIdentifier, string codeline) public view returns(uint index, bool exists) {
    bytes32[2] memory code = str2DoubleB32(codeline);
    return receiverStore.getIndex(str2B32(deliveredIdentifier), keccak256(code[0],code[1]));
  }

  function getCheckBase(string codeline) public view returns (string _codeline, bytes32 owner, uint256 amount, uint256 processDate, uint256 version, uint checkType, string) {
    bytes32[2] memory code = str2DoubleB32(codeline);
    bytes32[2] memory newCode;
    bytes32 _certifier;
    (newCode, owner, amount, processDate, version, checkType, _certifier) = receiverStore.getCheckBase(keccak256(code[0],code[1]));
    return (doubleb322Str(newCode), owner, amount, processDate, version, checkType, b322Str(_certifier));
  }

  function getCheckVersionLast(string codeline) public view returns (CheckStatus status, string depositAccount, string deliveredTo, string reason, bytes32[2] securityCode, uint256 timestamp, string deliveredIdentifier) {
    bytes32[2][4] memory strings;
    bytes32 simpleString;
    (status,strings[0],strings[1],strings[2],strings[3],timestamp,simpleString) = receiverStore.getCheckVersion(keccak256(str2DoubleB32(codeline)[0],str2DoubleB32(codeline)[1]));
    return (status, doubleb322Str(strings[0]), doubleb322Str(strings[1]), doubleb322Str(strings[2]), strings[3], timestamp, b322Str(simpleString));
  }

  function getCheckVersion(string codeline, uint version) public view returns (CheckStatus status, string depositAccount, string deliveredTo, string reason, bytes32[2] securityCode, uint timestamp, string deliveredIdentifier) {
    bytes32[2][4] memory strings;
    bytes32 simpleString;
    (status,strings[0],strings[1],strings[2],strings[3],timestamp,simpleString) = receiverStore.getCheckVersion(keccak256(str2DoubleB32(codeline)[0],str2DoubleB32(codeline)[1]), version);
    return (status, doubleb322Str(strings[0]), doubleb322Str(strings[1]), doubleb322Str(strings[2]), strings[3], timestamp, b322Str(simpleString));
  }

  function getAddressNumber(address ownerAddress) public view returns (string){
    return doubleb322Str(receiverStore.getAddressNumber(ownerAddress));
  }

  function getOwnerAddress(string codeline) public view returns (address) {
    bytes32[2] memory code = str2DoubleB32(codeline);
    return receiverStore.getOwnerAddress(keccak256(code[0],code[1]));
  }

  function updateCheck(string codeline, uint256 amount, uint processDate, CheckStatus status, string depositAccount, string deliveredTo, string reason, string securityCode, string newSecurityCode, string deliveredIdentifier, string certifier) public {
    bytes32[2] memory code = str2DoubleB32(codeline);
    receiverStore.updateCheck(code, amount, processDate, status, str2DoubleB32(depositAccount), str2DoubleB32(deliveredTo), str2DoubleB32(reason), str2B32(securityCode), str2B32(newSecurityCode), str2B32(deliveredIdentifier), str2B32(certifier));
  }

  function getReceivedIndexByHash(string deliveredIdentifier, bytes32 codelineHash) public view returns(uint index, bool exists) {
    return receiverStore.getIndex(str2B32(deliveredIdentifier), codelineHash);
  }

  function getCheckBaseByHash(bytes32 codelineHash) public view returns (string _codeline, bytes32 owner, uint256 amount, uint256 processDate, uint256 version, uint checkType, string) {
    bytes32[2] memory newCode;
    bytes32 _certifier;
    (newCode, owner, amount, processDate, version, checkType, _certifier) = receiverStore.getCheckBase(codelineHash);
    return (doubleb322Str(newCode), owner, amount, processDate, version, checkType, b322Str(_certifier));
  }

  function getCheckVersionLastByHash(bytes32 codelineHash) public view returns (CheckStatus status, string depositAccount, string deliveredTo, string reason, bytes32[2] securityCode, uint256 timestamp, string deliveredIdentifier) {
    bytes32[2][4] memory strings;
    bytes32 simpleString;
    (status,strings[0],strings[1],strings[2],strings[3],timestamp,simpleString) = receiverStore.getCheckVersion(codelineHash);
    return (status, doubleb322Str(strings[0]), doubleb322Str(strings[1]), doubleb322Str(strings[2]), strings[3], timestamp, b322Str(simpleString));
  }

  function getCheckVersionByHash(bytes32 codelineHash, uint version) public view returns (CheckStatus status, string depositAccount, string deliveredTo, string reason, bytes32[2] securityCode, uint timestamp, string deliveredIdentifier) {
    bytes32[2][4] memory strings;
    bytes32 simpleString;
    (status,strings[0],strings[1],strings[2],strings[3],timestamp,simpleString) = receiverStore.getCheckVersion(codelineHash, version);
    return (status, doubleb322Str(strings[0]), doubleb322Str(strings[1]), doubleb322Str(strings[2]), strings[3], timestamp, b322Str(simpleString));
  }

  function updateCheckByHash(bytes32 codelineHash, uint256 amount, uint processDate, CheckStatus status, string depositAccount, string deliveredTo, string reason, string securityCode, string newSecurityCode, string deliveredIdentifier, string certifier) public {
    receiverStore.updateCheckByHash(codelineHash, amount, processDate, status, str2DoubleB32(depositAccount), str2DoubleB32(deliveredTo), str2DoubleB32(reason), str2B32(securityCode), str2B32(newSecurityCode), str2B32(deliveredIdentifier), str2B32(certifier));
  }

  function setMustNotifyReceiver(string codeline) public {
    bytes32[2] memory code = str2DoubleB32(codeline);
    receiverStore.setMustNotifyReceiver(code);
  }

  function cleanMustNotifyReceiver(string codeline) public {
    bytes32[2] memory code = str2DoubleB32(codeline);
    receiverStore.cleanMustNotifyReceiver(code);
  }

  function getMustNotifyReceiver(string codeline) public view returns (bool) {
    bytes32[2] memory code = str2DoubleB32(codeline);
    return receiverStore.getMustNotifyReceiver(code);
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////////
  // Funciones de almacenamiento de Tipos de Cheque.

  function addCheckType(string _name, string _comparator, uint endorses) public {
    bytes32[2] memory name = str2DoubleB32(_name);
    checkTypeStore.add(name, str2B32(_comparator), endorses);
  }

  function updateCheckType(uint index, string _name, string _comparator, uint endorses) public {
    bytes32[2] memory name = str2DoubleB32(_name);
    checkTypeStore.update(index, name, str2B32(_comparator), endorses);
  }

  function checkTypeCount() public view returns(uint length){
    return checkTypeStore.count();
  }

  function getCheckType(uint index) public view returns(string _name, bool _exists, string _comparator, uint _endorses) {
    bytes32[2] memory name;
    bool exists;
    bytes32 comparator;
    uint endorses;
    (name, exists, comparator, endorses) = checkTypeStore.get(index);
    return (doubleb322Str(name), exists, b322Str(comparator), endorses);
  }

  function disableCheckType(uint index) public{
    checkTypeStore.disable(index);
  }

  function enableCheckType(uint index) public{
    checkTypeStore.enable(index);
  }


}
