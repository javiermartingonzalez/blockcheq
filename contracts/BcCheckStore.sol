pragma solidity ^0.4.18;

import "./CheckStore.sol";
import "./AccountStore.sol";
import "./TransactionStore.sol";
import "./ReceiverStore.sol";
import "./CheckTypeStore.sol";

contract BcCheckStore is CheckStore {

	mapping(bytes32 => Check[]) private checks;        // Checks by account hash.
	mapping(bytes32 => Version[]) private versions;    // Version by codeline hash

    struct CodelineIndex {
        bytes32 accountHash;
        uint index;
    }

    mapping(bytes32 => CodelineIndex) checksByCodelinehash;

    mapping(bytes32 => bool[19]) private notified;       // Check notification for each status by codeline hash
	mapping(bytes32 => bool) private mustNotifyReceiver; // Check if need to send mail to receiver for this codeline

    event CheckChanged(string action, address sender, string codeline, uint256 amount,
                       uint processDate, uint checkType, bytes32 certifier, CheckStatus status,
                       bytes32 deliveredIdentifier, string deliveredTo, string depositAccount,
                       bytes32 reason);

	AccountStore private accountStore;
    TransactionStore private transactionStore;
    bytes32 private code;
    address managerContractAddress;
    ReceiverStore private receiverStore;
    CheckTypeStore private checkTypeStore;

    modifier onlyByManager() {
        require (msg.sender == managerContractAddress || tx.origin == managerContractAddress);
        _;
    }

	function setAccountStore (address _accountStoreAddress) public onlyBy(owner){
		accountStore = AccountStore(_accountStoreAddress);
	}

    function getAccountStore() public view returns (address)  {
        return address(accountStore);
    }

    function setTransactionStore (address _transactionStoreAddress) public onlyBy(owner){
        transactionStore = TransactionStore(_transactionStoreAddress);
    }

    function getTransactionStore() public view returns (address)  {
        return address(transactionStore);
    }

    function setReceiverStore (address _receiverStoreAddress) public onlyBy(owner){
        receiverStore = ReceiverStore(_receiverStoreAddress);
    }

    function getReceiverStore() public view returns (address)  {
        return address(receiverStore);
    }

    function setCheckTypeStore (address _checkTypeStoreAddress) public onlyBy(owner){
        checkTypeStore = CheckTypeStore(_checkTypeStoreAddress);
    }

    function getCheckTypeStore() public view returns (address)  {
        return address(checkTypeStore);
    }

    function setBankCode(bytes32 bankCode) public onlyBy(owner){
        code = bankCode;
    }

    function setManagerContractAddress (address _managerContractAddress) public onlyBy(owner){
        managerContractAddress = _managerContractAddress;
    }

    function getManagerContractAddress() public view returns (address)  {
        return managerContractAddress;
    }

    function getCode() public view returns(bytes32) {
        return code;
    }

	function add(bytes32[2] account, bytes32[2] codeline, uint checkType, bytes32 certifier) public onlyByManager {
		require(!doubleb32Empty(codeline));
		address ownerAdress;
		bool existsAccount;
		(ownerAdress, , , existsAccount) = accountStore.getByNumber(account);
		require(existsAccount);
    	bytes32 codelineHash = keccak256(codeline[0], codeline[1]);
		require(!existsCodelineHash(codelineHash));
    	require(existsCheckType(checkType));

		bytes32 accountHash = accountStore.getHashByOwner(ownerAdress);

		uint index = checks[accountHash].length;
		checks[accountHash].length = index + 1;
		checks[accountHash][index].owner = accountHash;
		checks[accountHash][index].codeline = codeline;
		checks[accountHash][index].amount = 0;
		checks[accountHash][index].processDate = 0;
    	checks[accountHash][index].checkType = checkType;
    	checks[accountHash][index].certifier = certifier;
		versions[codelineHash].push(createInitialVersion());

    	checksByCodelinehash[codelineHash] = CodelineIndex({accountHash : accountHash, index : index});
        // evento 1
        Version storage v = versions[codelineHash][versions[codelineHash].length - 1];
        CheckChanged('add',
                     //checks[accountHash][index].owner,
                     tx.origin,
                     doubleb322Str(checks[accountHash][index].codeline),
                     checks[accountHash][index].amount,
                     checks[accountHash][index].processDate,
                     checks[accountHash][index].checkType,
                     checks[accountHash][index].certifier,
                     v.status,
                     v.deliveredIdentifier,
                     doubleb322Str(v.deliveredTo),
                     doubleb322Str(v.depositAccount),
                     v.reason[0]
                    );
	}

    function getIndex(bytes32[2] _codeline) public view returns (uint checkIdx) {
        bytes32 codelineHash = keccak256(_codeline[0], _codeline[1]);
        require(existsCodelineHash(codelineHash));

        CodelineIndex storage codelineIndex = checksByCodelinehash[codelineHash];
        return codelineIndex.index;
    }

    function getBase(bytes32[2] _codeline) public view returns (bytes32 owner, uint256 amount, uint processDate, uint version, uint checkType, bytes32 certifier) {
        bytes32 codelineHash = keccak256(_codeline[0], _codeline[1]);

        require(existsCodelineHash(codelineHash));

        (owner, ,amount, processDate, checkType, certifier) = getCheck(codelineHash);
        version = versions[codelineHash].length - 1;
        //return (owner, amount, processDate, versions[codelineHash].length - 1, checkType, certifier);
    }

    function getBaseByHash(bytes32 codelineHash) public view returns (bytes32[2], bytes32, uint256, uint, uint version, uint, bytes32) {
        CodelineIndex storage codelineIndex = checksByCodelinehash[codelineHash];

        Check storage outCheck = checks[codelineIndex.accountHash][codelineIndex.index];
        version = versions[codelineHash].length - 1;

        return (outCheck.codeline , outCheck.owner, outCheck.amount,
                outCheck.processDate, version, outCheck.checkType, outCheck.certifier);
    }

    function getBaseByHashIndex(bytes32 codelineHash) public view returns (uint, bytes32[2], bytes32, uint256, uint, uint version, uint, bytes32) {
        CodelineIndex storage codelineIndex = checksByCodelinehash[codelineHash];

        Check storage outCheck = checks[codelineIndex.accountHash][codelineIndex.index];
        version = versions[codelineHash].length - 1;

        return (codelineIndex.index, outCheck.codeline , outCheck.owner,
                outCheck.amount, outCheck.processDate, version,
                outCheck.checkType, outCheck.certifier);
    }

    function getBaseByIndex(bytes32[2] accountNumber, uint index) public view returns (bytes32[2], bytes32 , uint256 , uint , uint , uint , bytes32 ) {
        bytes32 accountHash = keccak256(accountNumber[0], accountNumber[1]);
        require (hasCheckInAccount(accountHash, index));
        Check storage outCheck = checks[accountHash][index];
        return (outCheck.codeline, outCheck.owner, outCheck.amount,
                outCheck.processDate, versions[keccak256(outCheck.codeline[0],
                outCheck.codeline[1])].length - 1, outCheck.checkType, outCheck.certifier);
    }

    function getVersion(bytes32[2] _codeline, uint version) public view returns (CheckStatus status, bytes32[2] memory depositAccount, bytes32[2] memory deliveredTo, bytes32[2] memory reason, bytes32[2] memory securityCode, uint timestamp, bytes32 deliveredIdentifier) {
        bytes32 codelineHash = keccak256(_codeline[0], _codeline[1]);
        require(existsCodelineHash(codelineHash));
        return getVersionCheck(codelineHash,version);
    }

    function getVersionByHash(bytes32 codelineHash, uint version) public view returns (CheckStatus status, bytes32[2] memory depositAccount, bytes32[2] memory deliveredTo, bytes32[2] memory reason, bytes32[2] memory securityCode, uint timestamp, bytes32 deliveredIdentifier) {
        require (existsCodelineHash(codelineHash));
        return getVersionCheck(codelineHash,version);
    }

    function update(bytes32[2] codeline, uint256 amount, uint processDate, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32[2] securityCode, bytes32 deliveredIdentifier, bytes32 certifier) public {

        updateByHash(keccak256(codeline[0],codeline[1]), amount, processDate, status, depositAccount, deliveredTo, reason, securityCode, deliveredIdentifier, certifier);
    }

    function updateByHash(bytes32 codelineHash, uint256 amount, uint processDate, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32[2] securityCode, bytes32 deliveredIdentifier, bytes32 certifier) public onlyByManager {
        CodelineIndex storage codelineIndex = checksByCodelinehash[codelineHash];

        Check storage updateCheck = checks[codelineIndex.accountHash][codelineIndex.index];

        if (updateCheck.certifier == bytes32(0x0)){
            updateCheck.certifier = certifier;
        }

        if (updateCheck.amount == 0){
            require(amount > 0);
            updateCheck.amount = amount;
        }

        if (updateCheck.processDate == 0){
            require(processDate > 0);
            updateCheck.processDate = processDate;
        }

        Version storage v = createVersionToUpdate(updateCheck.owner, codelineHash, status, depositAccount, deliveredTo, reason, securityCode, deliveredIdentifier);
        cleanNotifiedByHash(codelineHash, status);
        addTransaction(v.depositAccount, codelineHash, status);
        // evento 2
        CheckChanged('update',
                     //updateCheck.owner,
                     tx.origin,
                     doubleb322Str(updateCheck.codeline),
                     updateCheck.amount,
                     updateCheck.processDate,
                     updateCheck.checkType,
                     updateCheck.certifier,
                     v.status,
                     v.deliveredIdentifier,
                     doubleb322Str(v.deliveredTo),
                     doubleb322Str(v.depositAccount),
                     v.reason[0]
                    );
    }

    function createVersionToUpdate(bytes32 ownerHash, bytes32 codelineHash, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32[2] securityCode, bytes32 deliveredIdentifier) internal returns(Version storage v) {
        Version[] storage checkVers = versions[codelineHash];

        uint l = checkVers.length;
        Version storage oldV = checkVers[l-1];
        checkVers.length = l+1;

        v = checkVers[l];

        v.depositAccount = (doubleb32Empty(depositAccount)?oldV.depositAccount:depositAccount);
        v.deliveredTo = (doubleb32Empty(deliveredTo)?oldV.deliveredTo:deliveredTo);
				if (!mustNotifyReceiver[codelineHash]) {
					v.securityCode[0] = 0x0;
				} else {
					v.securityCode[0] = (securityCode[0] != bytes32(0) ? keccak256(securityCode[0]) : oldV.securityCode[0]);
				}
				v.securityCode[1] = (securityCode[1] != bytes32(0) ? keccak256(securityCode[1]) : oldV.securityCode[1]);
        v.deliveredIdentifier = (deliveredIdentifier != bytes32(0) ? deliveredIdentifier : oldV.deliveredIdentifier);
        v.status = status;
        v.reason = reason;
        v.timestamp = block.timestamp;
        updateReceiverStore(ownerHash, v.deliveredIdentifier, getCode(), codelineHash, l);
    }

    function revertVersions(bytes32[2] codeline, uint revertStatus) public {
        revertVersionsByHash(keccak256(codeline[0], codeline[1]), revertStatus);
    }

    function revertVersionsByHash(bytes32 codelineHash, uint revertStatus) public onlyByManager {
        require(existsCodelineHash(codelineHash));
        Version[] storage versionCodeline = versions[codelineHash];
        uint totalVersion = versionCodeline.length - 1;
        uint i = totalVersion;
        for (; i > 0; i--) {
            Version storage replicateVersion = versionCodeline[i];
            if (replicateVersion.status == CheckStatus(revertStatus)) {
                CodelineIndex storage codelineIndex = checksByCodelinehash[codelineHash];
                Check storage chk = checks[codelineIndex.accountHash][codelineIndex.index];
                
                createVersionToUpdate(chk.owner, codelineHash, replicateVersion.status, replicateVersion.depositAccount, replicateVersion.deliveredTo, replicateVersion.reason, replicateVersion.securityCode, replicateVersion.deliveredIdentifier);
                cleanNotifiedByHash(codelineHash, replicateVersion.status);
                addTransaction(replicateVersion.depositAccount, codelineHash, replicateVersion.status);
                
                // evento 3
                CheckChanged('update',
                             //chk.owner,
                             tx.origin,
                             doubleb322Str(chk.codeline),
                             chk.amount,
                             chk.processDate,
                             chk.checkType,
                             chk.certifier,
                             replicateVersion.status,
                             replicateVersion.deliveredIdentifier,
                             doubleb322Str(replicateVersion.deliveredTo),
                             doubleb322Str(replicateVersion.depositAccount),
                             replicateVersion.reason[0]
                            );
                break;
            }
        }
    }

    function addTransaction(bytes32[2] depositAccount, bytes32 codelineHash, CheckStatus status) internal {
        if(!doubleb32Empty(depositAccount)){
            uint indexVersion = versions[codelineHash].length - 1;
            transactionStore.add(code, depositAccount, codelineHash, indexVersion, status);
        }
    }

    function updateReceiverStore(bytes32 ownerHash, bytes32 deliveredIdentifier, bytes32 bankCode, bytes32 hashCodeline, uint versionIndex) internal {
        if ( deliveredIdentifier != bytes32(0) ) {
            uint idx;
            bool exists;
            (idx, exists) = receiverStore.getIndex(deliveredIdentifier, hashCodeline);
            if (!exists) {
                receiverStore.add(deliveredIdentifier, bankCode, hashCodeline, versionIndex);
                address ownerAdress;
                bytes32[2] memory number;
                (ownerAdress, number, ,) = accountStore.getByHash(ownerHash);
                receiverStore.addAddressNumber(ownerAdress, number, bankCode);
            } else {
                receiverStore.update(deliveredIdentifier, idx, hashCodeline, versionIndex);
            }
        }
    }

    function isOwner(bytes32 codelineHash, address user) public view returns (bool){
        if(versions[codelineHash].length == 0) {
            return false;
        }
		bytes32 userhash = accountStore.getHashByOwner(user);

        CodelineIndex storage codelineIndex = checksByCodelinehash[codelineHash];
		bytes32 ownerhash = codelineIndex.accountHash;
		return userhash == ownerhash;
    }

    function isDest(bytes32 codelineHash, uint versionIndex, address user) public view returns (bool){
        if(versionIndex >= versions[codelineHash].length) {
            return false;
        }
        bytes32 userhash = accountStore.getHashByOwner(user);
        bytes32[2] storage depositAccount = versions[codelineHash][versionIndex].depositAccount;
        bytes32 hashDepositAccount = keccak256(depositAccount[0], depositAccount[1]);

        return userhash == hashDepositAccount;
    }

    function getAccountChecksCount(bytes32[2] accountNumber) public view returns(uint) {
    	return checks[keccak256(accountNumber[0], accountNumber[1])].length;
    }

    function getCheck(bytes32 codelineHash )internal view returns (bytes32, bytes32[2] memory, uint256, uint, uint, bytes32){
        CodelineIndex memory codelineIndex = checksByCodelinehash[codelineHash];
        Check storage outCheck = checks[codelineIndex.accountHash][codelineIndex.index];

        return (outCheck.owner, outCheck.codeline, outCheck.amount, outCheck.processDate,
                outCheck.checkType, outCheck.certifier);
    }

    function getVersionCheck(bytes32 codelineHash, uint index) internal view returns (CheckStatus, bytes32[2] memory, bytes32[2] memory, bytes32[2] memory, bytes32[2] memory, uint, bytes32){
        Version storage outVersion = versions[codelineHash][index];
        return (outVersion.status, outVersion.depositAccount, outVersion.deliveredTo,
                outVersion.reason, outVersion.securityCode, outVersion.timestamp,
                outVersion.deliveredIdentifier);
    }

    function existsCodelineHash (bytes32 codeHash) internal view returns (bool){
    	return versions[codeHash].length > 0;
    }

    function existsCheckType (uint checkType) internal view returns (bool){
        bool _exists;
        (, _exists, , ) = checkTypeStore.get(checkType);
        return _exists;
    }

    function hasCheckInAccount(bytes32 accountHash, uint index) internal view returns (bool){
    	uint lengthCheck = checks[accountHash].length;

    	return (lengthCheck > 0 ) && (index < lengthCheck);
    }

    function createInitialVersion () internal view returns (Version){
    	bytes32[2] memory da;
		Version memory v;
        v.status =  CheckStatus.Issued;
        v.depositAccount = da;
        v.deliveredTo = da;
        //v.securityCode = 0x0;
        v.timestamp = block.timestamp;
        v.deliveredIdentifier = 0x0;
		return v;
    }

    function isAccountOwner(bytes32[2] accountNumber) internal view returns (bool){
        address ownerAdress;
        (ownerAdress, , , ) = accountStore.getByNumber(accountNumber);
        return sender(ownerAdress);
    }

    function setNotified(bytes32[2] codeline, CheckStatus status) public onlyBy(owner) {
        notified[keccak256(codeline[0], codeline[1])][uint(status)] = true;
    }

    function isNotified(bytes32[2] codeline, CheckStatus status) view public returns (bool) {
        return notified[keccak256(codeline[0], codeline[1])][uint(status)];
    }

    function cleanNotified(bytes32[2] codeline, CheckStatus status) public onlyBy(owner) {
        cleanNotifiedByHash(keccak256(codeline[0], codeline[1]), status);
    }

    function cleanNotifiedByHash(bytes32 hashCodeline, CheckStatus status) internal {
        notified[hashCodeline][uint(status)] = false;
    }

	function setMustNotifyReceiver(bytes32[2] codeline) public {
    	mustNotifyReceiver[keccak256(codeline[0], codeline[1])] = true;
	}

	function cleanMustNotifyReceiver(bytes32[2] codeline) public {
    	mustNotifyReceiver[keccak256(codeline[0], codeline[1])] = false;
	}

	function getMustNotifyReceiver(bytes32[2] codeline) view public returns (bool) {
    	return mustNotifyReceiver[keccak256(codeline[0], codeline[1])];
	}

}
