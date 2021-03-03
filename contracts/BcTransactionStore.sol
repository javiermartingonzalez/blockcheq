pragma solidity ^0.4.18;

import "./Banker.sol";
import "./TransactionStore.sol";
import "./BankStore.sol";
import "./AccountStore.sol";
import "./CheckStore.sol";

contract BcTransactionStore is TransactionStore {

    address internal bankStoreContract;
    BankStore private bankStore;

	mapping (bytes32 => mapping (bytes32 => Transaction[])) private transactions; // Key1: Bank Code Hash, Value(Key2): Account Hash, Value: Account transaction array
    mapping (bytes32 => bytes32) private accountsBank;  // key: Account Hash, value: Bank Code Hash.
    bytes32[] private accountList;                  // Array of hashes of used account hashes

	function setBankStoreContract(address _bankStoreContract) public onlyBy(owner) {
		bankStoreContract = _bankStoreContract;
		bankStore = BankStore(_bankStoreContract);
	}

    function add(bytes32 bankCode, bytes32[2] accountNumber, bytes32 hashCodeline, uint version, CheckStatus status) public {
        bytes32 depositBankHash = bankHashFromDepositAccount(accountNumber);
        bool exists;
        bool authorized;
        (, , , , , authorized, exists) = bankStore.getByCode(bankCode);
        require (exists && authorized);

        bytes32 accountHash = keccak256(accountNumber[0], accountNumber[1]);
        Transaction[] storage userTrans = transactions[depositBankHash][accountHash];
        if (userTrans.length == 0) {
            accountsBank[accountHash] = depositBankHash;
            accountList.push(accountHash);
        }
        uint l = userTrans.length;
        userTrans.length++;
        Transaction storage t = userTrans[l];
        t.bankCode = bankCode;
        t.hashCodeline = hashCodeline;
        t.version = version;
        t.timestamp = block.timestamp;
        t.status = status;
    }

    function addCustom(bytes32 bankCode, bytes32[2] accountNumber, bytes32 hashCodeline, uint version, CheckStatus status) public {
        bytes32 depositBankHash = bankHashFromDepositAccount(accountNumber);
        checkAddPrerequisites(bankCode, depositBankHash);

        bytes32 accountHash = keccak256(accountNumber[0], accountNumber[1]);
        Transaction[] storage userTrans = transactions[depositBankHash][accountHash];
        if (userTrans.length == 0) {
            accountsBank[accountHash] = depositBankHash;
            accountList.push(accountHash);
        }
        uint l = userTrans.length;
        userTrans.length++;
        Transaction storage t = userTrans[l];
        t.bankCode = bankCode;
        t.hashCodeline = hashCodeline;
        t.version = version;
        t.timestamp = block.timestamp;
        t.status = status;
    }

    function checkAddPrerequisites(bytes32 issueBankCode, bytes32 depositBankHash) internal view {
        bool issueAuth;
        bool depositAuth;
        address issueContract;
        address depositContract;
        address issueAddress;
        address depositAddress;
        (issueAuth, issueAddress, issueContract) = isBankAuthorizedByCode(issueBankCode);
        (depositAuth, depositAddress, depositContract) = isBankAuthorizedByHash(depositBankHash);
        require(issueAuth && depositAuth && (sender(issueContract) || sender(depositContract) || sender(issueAddress) || sender(depositAddress)));
    }

    function get(bytes32[2] accountNumber, uint transactionIdx) public view returns (bytes32, bytes32, uint, uint, CheckStatus) {
        Transaction memory t = getTransactionByHash(keccak256(accountNumber[0], accountNumber[1]), transactionIdx);
        return (t.bankCode, t.hashCodeline, t.version, t.timestamp, t.status);
    }

    function getByHash(bytes32 accountHash, uint transactionIdx) public view returns (bytes32, bytes32, uint, uint, CheckStatus) {
        Transaction memory t = getTransactionByHash(accountHash, transactionIdx);
        return (t.bankCode, t.hashCodeline, t.version, t.timestamp, t.status);
    }

    function getCheckBase(bytes32[2] accountNumber, uint transactionIdx) public view returns (uint checkIdx, bytes32 owner, bytes32[2] memory codeline, uint256 amount, uint processDate, uint version, uint cType, bytes32 certifier) {
        Transaction memory trans = getTransactionByHash(keccak256(accountNumber[0], accountNumber[1]), transactionIdx);
        version = trans.version;
        (codeline, owner,  amount, processDate, , cType, certifier) = CheckStore(getCheckStoreAddress(trans.bankCode)).getBaseByHash(trans.hashCodeline);
        checkIdx = CheckStore(getCheckStoreAddress(trans.bankCode)).getIndex(codeline);
    }


    function getCheckBaseByHash(bytes32 accountHash, uint transactionIdx) public view returns (uint checkIdx, bytes32 owner, bytes32[2] memory codeline, uint256 amount, uint processDate, uint version, uint checkType, bytes32 certifier) {
        Transaction memory trans = getTransactionByHash(accountHash, transactionIdx);
        version = trans.version;
        (codeline, owner,  amount, processDate, ,checkType, certifier) = CheckStore(getCheckStoreAddress(trans.bankCode)).getBaseByHash(trans.hashCodeline);
        checkIdx = CheckStore(getCheckStoreAddress(trans.bankCode)).getIndex(codeline);
    }

    function getCheckVersion(bytes32[2] accountNumber, uint transactionIdx) public view returns (CheckStatus status, bytes32[2] memory depositAccount, bytes32[2] memory deliveredTo, bytes32[2] memory reason, bytes32[2] memory securityCode, uint timestamp, bytes32 deliveredIdentifier) {
        Transaction memory trans = getTransactionByHash(keccak256(accountNumber[0], accountNumber[1]), transactionIdx);
        (status, depositAccount, deliveredTo, reason, securityCode, timestamp, deliveredIdentifier) = CheckStore(getCheckStoreAddress(trans.bankCode)).getVersionByHash(trans.hashCodeline, trans.version);
    }

    function getCheckVersionByHash(bytes32 accountHash, uint transactionIdx) public view returns (CheckStatus status, bytes32[2] memory depositAccount, bytes32[2] memory deliveredTo, bytes32[2] memory reason, bytes32[2] memory securityCode, uint timestamp, bytes32 deliveredIdentifier) {
        Transaction memory trans = getTransactionByHash(accountHash, transactionIdx);
        (status, depositAccount, deliveredTo, reason, securityCode, timestamp, deliveredIdentifier) = CheckStore(getCheckStoreAddress(trans.bankCode)).getVersionByHash(trans.hashCodeline, trans.version);
    }

    function getBankHash(bytes32 accountHash) public view returns (bytes32 bankHash) {
        return accountsBank[accountHash];
    }

    function countByAccount(bytes32[2] accountNumber) public view returns (uint length) {
        return countByHash(keccak256(accountNumber[0], accountNumber[1]));
    }

    function countByHash(bytes32 accountHash) public view returns (uint length) {
        bytes32 bank = accountsBank[accountHash];
        return transactions[bank][accountHash].length;
    }

    function isAccesible(bytes32 accountHash, uint id) public view returns (bool accesible) {
        (accesible,) = isTransactionAccesible(accountsBank[accountHash], accountHash, id);
    }

    function getCheckStoreAddress(bytes32 bankCode) internal view returns (address contractAddress) {
        (, , , , contractAddress, , ) = bankStore.getByCode(bankCode);
        contractAddress = geCheckStore(contractAddress);
    }

    function bankHashFromDepositAccount(bytes32[2] accountNumber) internal view returns(bytes32) {
        string memory accountString = doubleb322Str(accountNumber);
        uint codePos;
        uint codeLen;
        (codePos, codeLen) = bankStore.getCodeLocation();

    	return keccak256(str2B32(substring(accountString, codePos, codeLen)));
    }

    function isBankAuthorizedByCode(bytes32 bankCode) internal view returns (bool authorized, address bankOwner, address bankContract) {
        bool exists;
        (, , , bankOwner, bankContract, authorized, exists) = bankStore.getByCode(bankCode);
        bankContract = geCheckStore(bankContract);
        authorized = authorized && exists;
    }

    function isBankAuthorizedByHash(bytes32 bankHash) internal view returns (bool authorized, address bankOwner, address bankContract) {
        bool exists;
        (, , , bankOwner, bankContract, authorized, exists) = bankStore.getByHash(bankHash);
        bankContract = geCheckStore(bankContract);
        authorized = authorized && exists;
    }

    function getTransactionByHash(bytes32 accountHash, uint transactionIdx) internal view returns (Transaction) {
        bool accesible;
        Transaction memory trans;
        (accesible, trans) = isTransactionAccesible(accountsBank[accountHash], accountHash, transactionIdx);
        require(accesible);
        return trans;
    }

    function isTransactionAccesible(bytes32 hashBankCode, bytes32 accountHash, uint id) internal view returns (bool, Transaction) {
        Transaction[] storage transCollection = transactions[hashBankCode][accountHash];
        Transaction memory trans;
        if (transCollection.length <= id) {
            return (false, trans);
        }
        trans = transCollection[id];
        bytes32 originBankHash = keccak256(trans.bankCode);
        if (hashBankCode == originBankHash) {
            return ((askByTransDest(trans, hashBankCode, accountHash) || askByTransSender(trans) || askByTransBankOwner(trans)), trans) ;
        }
        return ((askByTransDest(trans, hashBankCode, accountHash) || askByDestBankOwner(hashBankCode) || askByTransSender(trans) || sender(owner) || askByTransBankOwner(trans)), trans);
    }

    function askByTransDest(Transaction trans, bytes32 hashBankCode, bytes32 hashAccount) view internal returns (bool) {
        address contractAddress;
        address originContractAddress;
        (, , , , originContractAddress, , ) = bankStore.getByCode(trans.bankCode);
        (, , , , contractAddress, , ) = bankStore.getByHash(hashBankCode);
        CheckStore chkStore = CheckStore(geCheckStore(originContractAddress));
        AccountStore accStore = AccountStore(CheckStore(geCheckStore(contractAddress)).getAccountStore());
        return ( (chkStore.isDest(trans.hashCodeline, trans.version, msg.sender)) || (chkStore.isDest(trans.hashCodeline, trans.version, tx.origin)) )
                    ||
                ( (accStore.getHashByOwner(msg.sender) == hashAccount) || (accStore.getHashByOwner(tx.origin) == hashAccount) );
    }

    function askByTransSender(Transaction trans) view internal returns (bool) {
        address contractAddress;
        (, , , , contractAddress, , ) = bankStore.getByCode(trans.bankCode);
        CheckStore chkStore = CheckStore(geCheckStore(contractAddress));
        return chkStore.isOwner(trans.hashCodeline, msg.sender) || chkStore.isOwner(trans.hashCodeline, tx.origin);
    }

    function askByTransBankOwner(Transaction trans) view internal returns (bool) {
        address bankAddress;
        (, , , bankAddress, , ,) = bankStore.getByCode(trans.bankCode);
        return (sender(bankAddress));
    }

    function askByDestBankOwner(bytes32 depositBankHash) view internal returns (bool) {
        bytes32 codeBySender;
        bytes32 codeByOrigin;
        (, codeBySender , , , , , ) = bankStore.getByAddress(msg.sender);
        (, codeByOrigin , , , , , ) = bankStore.getByAddress(tx.origin);
        return ( (keccak256(codeBySender) == depositBankHash) || (keccak256(codeByOrigin) == depositBankHash) );
    }

    function getAccountTransactionsLength() public view returns(uint){
        return accountList.length;
    }

    function getAccountHash(uint index) public view returns (bytes32 hash){
        return accountList[index];
    }

    function getTransactionsLengthByHash(bytes32 accountHash) public view returns(uint length) {
        bytes32 bank = accountsBank[accountHash];
        return transactions[bank][accountHash].length;
    }

    function geCheckStore(address addr) internal view returns(address) {
        return Banker(addr).getCheckContract();
    }

}
