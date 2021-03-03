pragma solidity ^0.4.18;

import "./ReceiverStore.sol";
import "./BlockcheqCore.sol";
import "./AuthorizedBank.sol";
import "./BankStore.sol";
import "./Banker.sol";
import "./CheckManager.sol";
import "./CheckStore.sol";

contract BcReceiverStore is ReceiverStore, AuthorizedBank {

    BankStore private bankStore;

    struct ReceiverCheckIndex {
        uint index;
        bool exists;
    }

    mapping (bytes32 => ReceiverCheck[]) private receiverChecks; // Key: Receiver Identifier (dni), Value: Received checks array
    // Colección de indices de cheques recibidos por hashCodeline e identificador de receptor
    mapping (bytes32 => mapping (bytes32 => ReceiverCheckIndex)) private receiverChecksIndex; // Key1: hashCodeline, value(key2): Receiver Identifier (dni), Value: index
    // Colleción de hashes de cheques recibidos por bankCode
    mapping (bytes32 => bytes32) private codelineBankcode; // Key1: hashCodeline, value: BankCode

    mapping (address => bytes32[2]) private addressNumber; // Key1: adress, value: acc number

    function setBankStore(address _bankStoreAddress) public onlyBy(owner)  {
        bankStore = BankStore(_bankStoreAddress);
    }

    function add(bytes32 deliveredIdentifier, bytes32 bankCode, bytes32 hashCodeline, uint version) public {
        require(msg.sender == getCheckStoreAddress(bankCode));
        require(receiverChecksIndex[hashCodeline][deliveredIdentifier].exists == false);
        ReceiverCheck memory dataReceiverCheck = ReceiverCheck(bankCode,hashCodeline,version);
        receiverChecks[deliveredIdentifier].push(dataReceiverCheck);
        ReceiverCheckIndex memory dataReceiverCheckIndex = ReceiverCheckIndex(receiverChecks[deliveredIdentifier].length-1,true);
        receiverChecksIndex[hashCodeline][deliveredIdentifier] = dataReceiverCheckIndex;
        codelineBankcode[hashCodeline] = bankCode;
    }

    function update(bytes32 deliveredIdentifier, uint index,  bytes32 hashCodeline, uint version) public {
        require(msg.sender == getCheckStoreAddress(receiverChecks[deliveredIdentifier][index].bankCode));
        require(receiverChecksIndex[hashCodeline][deliveredIdentifier].exists == true);
        receiverChecks[deliveredIdentifier][index].version = version;//Solo se puede actualizar la version

    }

    function addAddressNumber(address ownerAddress, bytes32[2] number, bytes32 bankCode) public {
        require(msg.sender == getCheckStoreAddress(bankCode));
        addressNumber[ownerAddress] = number;
    }

    function getAddressNumber(address ownerAddress) public view returns (bytes32[2]){
        return addressNumber[ownerAddress];
    }


    function count(bytes32 deliveredIdentifier) public view returns(uint length) {
        return receiverChecks[deliveredIdentifier].length;
    }

    function get(bytes32 deliveredIdentifier, uint index) public view returns(bytes32 bankCode, bytes32 hashCodeline, uint version) {
        bankCode = receiverChecks[deliveredIdentifier][index].bankCode;
        hashCodeline = receiverChecks[deliveredIdentifier][index].hashCodeline;
        version = receiverChecks[deliveredIdentifier][index].version;

    }

    function getWithCodeline(bytes32 deliveredIdentifier, uint index) public view returns(bytes32 bankCode, bytes32[2] codeline, uint version) {
        bankCode = receiverChecks[deliveredIdentifier][index].bankCode;
        (codeline,,,,) = getCheckBase(receiverChecks[deliveredIdentifier][index].hashCodeline);
        version = receiverChecks[deliveredIdentifier][index].version;

    }

    function getIndex(bytes32 deliveredIdentifier, bytes32 hashCodeline) public view returns(uint index, bool exists) {
        index = receiverChecksIndex[hashCodeline][deliveredIdentifier].index;
        exists = receiverChecksIndex[hashCodeline][deliveredIdentifier].exists;
    }

    function getCheckBase(bytes32 hashCodeline) public view returns (bytes32[2] codeline, bytes32 owner, uint256 amount, uint processDate, uint version, uint checkType, bytes32 certifier) {
        (codeline,owner,amount,processDate,version,checkType, certifier) = CheckStore(getCheckStoreAddress(codelineBankcode[hashCodeline])).getBaseByHash(hashCodeline);
    }

    function getCheckVersion(bytes32 hashCodeline) public view returns (CheckStatus status, bytes32[2] memory depositAccount, bytes32[2] memory deliveredTo, bytes32[2] memory reason, bytes32[2] memory securityCode, uint timestamp, bytes32 deliveredIdentifier) {
        uint version;

        (,,,,version,, ) = CheckStore(getCheckStoreAddress(codelineBankcode[hashCodeline])).getBaseByHash(hashCodeline);
        (status, depositAccount, deliveredTo, reason, securityCode, timestamp, deliveredIdentifier) = CheckStore(getCheckStoreAddress(codelineBankcode[hashCodeline])).getVersionByHash(hashCodeline,version);
    }

    function getCheckVersion(bytes32 hashCodeline, uint version) public view returns (CheckStatus status, bytes32[2] memory depositAccount, bytes32[2] memory deliveredTo, bytes32[2] memory reason, bytes32[2] memory securityCode, uint timestamp, bytes32 deliveredIdentifier) {
        (status, depositAccount, deliveredTo, reason, securityCode, timestamp, deliveredIdentifier) = CheckStore(getCheckStoreAddress(codelineBankcode[hashCodeline])).getVersionByHash(hashCodeline,version);
    }

    function getOwnerAddress(bytes32 hashCodeline) public view returns (address owner) {
        Banker b = Banker(getBankerAddress(codelineBankcode[hashCodeline]));
        bytes32 _owner;
        (, _owner, , , , , ) = b.getBaseByHash(hashCodeline);
        (owner,,) = b.getAccountByHash(_owner);
    }

    function updateCheck(bytes32[2] codeline, uint256 amount, uint processDate, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32 securityCode, bytes32 newSecurityCode, bytes32 deliveredIdentifier, bytes32 certifier) public  {
        CheckManager(getCheckManagerAddress(codelineBankcode[keccak256(codeline[0],codeline[1])])).setStatus(codeline, amount, processDate, status, depositAccount, deliveredTo, reason, securityCode, newSecurityCode, deliveredIdentifier, certifier);
    }

    function updateCheckByHash(bytes32 codelineHash, uint256 amount, uint processDate, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32 securityCode, bytes32 newSecurityCode, bytes32 deliveredIdentifier, bytes32 certifier) public  {
        CheckManager(getCheckManagerAddress(codelineBankcode[codelineHash])).setStatusByHash(codelineHash, amount, processDate, status, depositAccount, deliveredTo, reason, securityCode, newSecurityCode, deliveredIdentifier, certifier);
    }

    function getCheckManagerAddress(bytes32 bankCode) internal view returns (address checkManager) {
        address banker = bankStore.getContract(bankCode);
        checkManager = Banker(banker).getCheckManagerContract();
    }

    function getCheckStoreAddress(bytes32 bankCode) internal view returns (address checkStore) {
        address banker = bankStore.getContract(bankCode);
        checkStore = Banker(banker).getCheckContract();
    }

    function getBankerAddress(bytes32 bankCode) internal view returns (address banker) {
        banker = bankStore.getContract(bankCode);
    }

    function setMustNotifyReceiver(bytes32[2] codeline) public {
        CheckStore(getCheckStoreAddress(codelineBankcode[keccak256(codeline[0], codeline[1])])).setMustNotifyReceiver(codeline);
	}

	function cleanMustNotifyReceiver(bytes32[2] codeline) public {
        CheckStore(getCheckStoreAddress(codelineBankcode[keccak256(codeline[0], codeline[1])])).cleanMustNotifyReceiver(codeline);
	}

	function getMustNotifyReceiver(bytes32[2] codeline) view public returns (bool) {
    	return CheckStore(getCheckStoreAddress(codelineBankcode[keccak256(codeline[0], codeline[1])])).getMustNotifyReceiver(codeline);
    }

}
