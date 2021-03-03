pragma solidity ^0.4.18;

import "./BlockcheqCore.sol";
import "./BankStore.sol";
import "./TransactionStore.sol";

contract Regulator is BlockcheqCore  {

	BankStore public bankStore;
	TransactionStore public transactionStore;
    string public regulatorName;             // Regulator name


    function Regulator() public {}

    function getRegulatorName() public constant returns (string) {
        return (regulatorName);
    }

    function setRegulatorName(string _name) public onlyBy(owner) {
        regulatorName = _name;
    }

	/////////////////////////////////////////////////////////////////////////////////////////////////////
    // Funciones de asignación de contratos de almacenamiento y gestión.
    function setBankContract(address bankAddress) public onlyBy(owner) {
        bankStore = BankStore(bankAddress);
    }

    function setTransactionContract(address transactionAddress) public onlyBy(owner) {
        transactionStore = TransactionStore(transactionAddress);
    }

	/////////////////////////////////////////////////////////////////////////////////////////////////////
	// Bancos -> CRUD de Bancos
	/////////////////////////////////////////////////////////////////////////////////////////////////////
    // Funciones para la gestión de bancos
    function addBank(string _code, string bankName, address bankAddress, address contractAddress) public {
        bankStore.add(str2B32(_code), str2DoubleB32(bankName), bankAddress, contractAddress);
    }

    function updateBank(string _code, string bankName, address bankAddress, address contractAddress, bool authorized) public {
        bankStore.update(str2B32(_code), str2DoubleB32(bankName), bankAddress, contractAddress, authorized);
    }

    function getBankCount() public view returns (uint) {
    	return bankStore.count();
    }

    function deleteBank(string _code) public {
        bankStore.disable(str2B32(_code));
    }

    function restoreBank(string _code) public {
        bankStore.enable(str2B32(_code));
    }

    function getBankByCode(string _code) public view returns (uint id, string, string, address bankAddress, address contractAddress, bool authorized, bool exists) {
        bytes32 codeB32;
        bytes32[2] memory nameB322;

    	(id, codeB32 , nameB322, bankAddress, contractAddress, authorized, exists) = bankStore.getByCode(str2B32(_code));

        return (id, b322Str(codeB32) , doubleb322Str(nameB322), bankAddress, contractAddress, authorized, exists);
    }

    function getBankByIndex(uint index) public view returns (uint id, string, string, address bankAddress, address contractAddress, bool authorized, bool exists) {
        bytes32 codeB32;
        bytes32[2] memory nameB322;

        (id, codeB32, nameB322, bankAddress, contractAddress, authorized, exists) = bankStore.getByHash(bankStore.getHashByIndex(index));

        return (id, b322Str(codeB32), doubleb322Str(nameB322), bankAddress, contractAddress, authorized, exists);
    }

    function getBankByHash(bytes32 hash) public view returns (uint id, string, string, address bankAddress, address contractAddress, bool authorized, bool exists) {
        bytes32 codeB32;
        bytes32[2] memory nameB322;

        (id, codeB32, nameB322, bankAddress, contractAddress, authorized, exists) = bankStore.getByHash(hash);

        return (id, b322Str(codeB32), doubleb322Str(nameB322), bankAddress, contractAddress, authorized, exists);
    }

	/////////////////////////////////////////////////////////////////////////////////////////////////////
	// Transacciones -> CRUD de Transacciones
	/////////////////////////////////////////////////////////////////////////////////////////////////////
    // Funciones para la gestión de transaciones

    function addTransaction(string bankCode, string accountNumber, string codeline, uint version, CheckStatus status) public {
        bytes32[2] memory b32Codeline = str2DoubleB32(codeline);
        transactionStore.addCustom(str2B32(bankCode), str2DoubleB32(accountNumber), keccak256(b32Codeline[0], b32Codeline[1]), version, status);
    }

    function getTransaction(string accountNumber, uint transactionIdx) public view returns (string, bytes32 hash, uint version, uint timeStamp, CheckStatus status) {
        bytes32 bankcodeB32;

    	(bankcodeB32, hash, version, timeStamp, status) = transactionStore.get(str2DoubleB32(accountNumber), transactionIdx);

        return (b322Str(bankcodeB32), hash, version, timeStamp, status);
    }

    function getTransactionByHash(bytes32 accountNumberHash, uint transactionIdx) public view returns (string, bytes32 hash, uint version, uint timeStamp, CheckStatus status) {
        bytes32 bankcodeB32;

        (bankcodeB32, hash, version, timeStamp, status) = transactionStore.getByHash(accountNumberHash, transactionIdx);

        return (b322Str(bankcodeB32), hash, version, timeStamp, status);
    }

    function getCheckBase(string accountNumber, uint transactionIdx) public view returns (uint checkIdx, bytes32 owner, string codeline, uint256 amount, uint processDate, uint version, uint cType, string certifier) {
        bytes32[2] memory _codeline;
        bytes32 _certifier;
        (, , , , processDate, version, cType, _certifier) = transactionStore.getCheckBase(str2DoubleB32(accountNumber), transactionIdx);
        (checkIdx, owner, _codeline, amount, , , , ) = transactionStore.getCheckBase(str2DoubleB32(accountNumber), transactionIdx);
        codeline = doubleb322Str(_codeline);
        certifier = b322Str(_certifier);
    }

    function getCheckVersion(string accountNumber, uint transactionIdx) public view returns (CheckStatus status, string, string, string reason, bytes32[2] securityCode, uint timestamp, string) {
        bytes32[2][3] memory strings;// 0 - depositAccount; 1 - deliveredTo; 2 - reason;
        bytes32 _deliveredIdentifier;

        (status, strings[0], strings[1], strings[2], securityCode, timestamp, _deliveredIdentifier) = transactionStore.getCheckVersion(str2DoubleB32(accountNumber), transactionIdx);

        return (status, doubleb322Str(strings[0]), doubleb322Str(strings[1]), doubleb322Str(strings[2]), securityCode, timestamp, b322Str(_deliveredIdentifier));
    }

    function getCheckBaseByHash(bytes32 accountNumberHash, uint transactionIdx) public view returns (uint checkIdx, bytes32 owner, string codeline, uint256 amount, uint processDate, uint version, uint cType, string certifier) {
        bytes32[2] memory _codeline;
        bytes32 _certifier;
        (, , , , processDate, version, cType, _certifier) = transactionStore.getCheckBaseByHash(accountNumberHash, transactionIdx);
        (checkIdx, owner, _codeline, amount, , , , ) = transactionStore.getCheckBaseByHash(accountNumberHash, transactionIdx);
        codeline = doubleb322Str(_codeline);
        certifier = b322Str(_certifier);
    }

    function getCheckVersionByHash(bytes32 accountNumberHash, uint transactionIdx) public view returns (CheckStatus status, string, string , string, bytes32[2] securityCode, uint timestamp, string) {
        bytes32[2][3] memory strings;// 0 - depositAccount; 1 - deliveredTo; 2 - reason;
        bytes32 _deliveredIdentifier;

        (status,  strings[0], strings[1], strings[2], securityCode, timestamp, _deliveredIdentifier) = transactionStore.getCheckVersionByHash(accountNumberHash, transactionIdx);

        return (status,  doubleb322Str(strings[0]), doubleb322Str(strings[1]), doubleb322Str(strings[2]), securityCode, timestamp, b322Str(_deliveredIdentifier));
    }

    function getBankHashByAccountHash(bytes32 accountHash) public view returns (bytes32 bankHash) {
        return transactionStore.getBankHash(accountHash);
    }

    function getBankHashByAccount(string account) public view returns (bytes32 bankHash) {
        bytes32[2] memory _account = str2DoubleB32(account);
        bytes32 accountHash = keccak256(_account[0], _account[1]);
        return transactionStore.getBankHash(accountHash);
    }

    function getAccountLength() public view returns (uint){
        return transactionStore.getAccountTransactionsLength();
    }

    function getAccountHash(uint index) public view returns (bytes32 hash){
        return transactionStore.getAccountHash(index);
    }

    function isTransactionAccesibleByHash(bytes32 accountHash, uint id) public view returns (bool accesible) {
        return transactionStore.isAccesible(accountHash, id);
    }

    function isTransactionAccesible(string accountNumber, uint id) public view returns (bool accesible) {
        bytes32[2] memory _accountNumber = str2DoubleB32(accountNumber);
        return transactionStore.isAccesible(keccak256(_accountNumber[0], _accountNumber[1]), id);
    }

    function getTransactionsLengthByHash(bytes32 hash) public view returns (uint length){
        return transactionStore.getTransactionsLengthByHash(hash);
    }

    function getTransactionsLength(string accountNumber) public view returns (uint length){
        bytes32[2] memory _accountNumber = str2DoubleB32(accountNumber);
        return transactionStore.getTransactionsLengthByHash(keccak256(_accountNumber[0], _accountNumber[1]));
    }
}
