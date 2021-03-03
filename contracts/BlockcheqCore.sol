pragma solidity ^0.4.18;

contract Ownable {

    address internal owner;

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwner(address _owner) public onlyBy(owner) {
        owner = _owner;
    }

    function isTheOwner() public view returns(bool) {
        return sender(owner);
    }

    modifier onlyBy(address userA) {
        require(sender(userA));
        _;
    }

    modifier onlyByOne2(address userA, address userB) {
        require(sender(userA) || sender(userB));
        _;
    }

    modifier onlyByOne3(address userA, address userB, address userC) {
        require(sender(userA) || sender(userB) || sender(userC));
        _;
    }

    modifier onlyByOne4(address userA, address userB, address userC, address userD) {
        require(sender(userA) || sender(userB) || sender(userC) || sender(userD));
        _;
    }

    function sender(address user) internal view returns(bool) {
        return (msg.sender == user) || (tx.origin == user);
    }

}

contract BlockcheqCore is Ownable {

    enum CheckStatus {Issued, Filled, ReservedFunds, Delivered, Accepted, PendingCertification, Certified, Deposited, SentToHost, Paid, NotAccepted, RejectedConformation, RejectedCertification, ReleasedFunds, Rejected, Locked, Completed, DepositRejected, Endorsed}

    struct Bank {
        uint id;                    // bankList index.
        bytes32 code;                // Bank code.
        bytes32[2] name;                // Bank name.
        address bankAddress;        // Ethereum account of the bank
        address contractAddress;    // Bank contract address
        bool authorized;            // Authorized to operate
        bool exists;                // Exist for the system
    }

    struct Account {
        address owner;
        bytes32[2] number;
        uint256 balance;
        bool exists;
    }

    struct Check {
        bytes32 owner;
        bytes32[2] codeline;
        uint256 amount;
        uint processDate;
        uint checkType;
        bytes32 certifier;
    }

    struct Version {
        CheckStatus status;
        bytes32[2] depositAccount;
        bytes32[2] deliveredTo;
        bytes32[2] reason;
        bytes32[2] securityCode;
        uint timestamp;
        bytes32 deliveredIdentifier;
    }

    struct Transaction {
        bytes32 bankCode;
        bytes32 hashCodeline;
        uint version;
        uint timestamp;
        CheckStatus status;
    }

    struct ReceiverCheck {
        bytes32 bankCode;
        bytes32 hashCodeline;
        uint version;
    }

    struct CheckType {
        uint id;
        bytes32[2] name;
        bool exists;
        bytes32 comparator;
        uint endorses;
    }

    uint8 public PROMO_ROL = 0; // Who can do the promotion
    uint8 public PROMO_SECURITY = 1; // Who need securityCode
    uint8 public PROMO_UPDATEDEPACC = 2; // Update account update config
    uint8 public PROMO_UPDATESECCOD = 3; // Security code update config
    uint8 public PROMO_REVERTSTATUS = 4; // Status to Revert check.

    uint8 public CHCK_OWNER = 1; // 0001
    uint8 public BANK_OWNER = 2; // 0010
    uint8 public CHCK_DEST = 4;  // 0100
    uint8 public EVERYBODY_HAS_PERMISSION = 8;

    uint8 public USER_SECURITY = 1;
    uint8 public BANKER_SECURITY = 2;
    uint8 public CERTIFIER_SECURITY = 4;

    uint8 public CAN_UPDATE = 1;
    uint8 public MUST_UPDATE = 2;
    uint8 public CERTIFIER_UPDATE = 4;

    uint8 public FIELD_DELIVERYTO = 0;
    uint8 public FIELD_DEPOSITACC = 1;

    function substring(string str, uint init, uint len) internal pure returns (string) {
        bytes memory strBytes = bytes(str);
        bytes memory out = new bytes(len);
        for(uint i = 0; i < len; i++) {
            out[i] = strBytes[init+i];
        }
        return string(out);
    }

    function stringsEqual(string memory _a, string memory _b) internal pure returns (bool) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length) {
            return false;
        }
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }

    function stringEmpty(string memory _str) internal pure returns (bool) {
        bytes memory aux = bytes(_str);
        return (aux.length == 0);
    }


    function doubleb32Empty(bytes32[2] db32) internal pure returns (bool){
        return b32Empty(db32[0]) && b32Empty(db32[1]);
    }

    function b32Empty(bytes32 b32) internal pure returns (bool){
        return b32 == 0x0;
    }

    function str2DoubleB32(string source) internal pure returns (bytes32[2] memory) {
        bytes32[2] memory result;
        uint len = bytes(source).length;
        if(len>32){
            result[0] = str2B32(substring(source,0,32));
            uint left = len-32;
            result[1] = str2B32(substring(source,32,(left>32?32:left)));
        } else {
            result[0] = str2B32(source);
        }
        return result;
    }

    function str2DoubleB322Hash(string source) public pure returns (bytes32 hash) {
        bytes32[2] memory doubleB32 = str2DoubleB32(source);
        return keccak256(doubleB32[0], doubleB32[1]);
    }

    function b322Str(bytes32 data) internal pure returns (string) {
        bytes memory bytesString = new bytes(64);
        uint urlLength;
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[urlLength] = char;
                urlLength += 1;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(urlLength);
        for (uint i=0; i<urlLength; i++) {
            bytesStringTrimmed[i] = bytesString[i];
        }
        return string(bytesStringTrimmed);
    }

    function str2B32(string source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function eqDoubleb32(bytes32[2] a, bytes32[2] b) internal pure returns (bool) {
        return a[0] == b[0] && a[1] == b[1];
    }

    function doubleb322Str(bytes32[2] data) internal pure returns (string) {
        bytes memory bytesString = new bytes(64);
        uint urlLength;
        for (uint i=0; i<2; i++) {
            for (uint j=0; j<32; j++) {
                byte char = byte(bytes32(uint(data[i]) * 2 ** (8 * j)));
                if (char != 0) {
                    bytesString[urlLength] = char;
                    urlLength += 1;
                }
            }
        }
        bytes memory bytesStringTrimmed = new bytes(urlLength);
        for (i=0; i<urlLength; i++) {
            bytesStringTrimmed[i] = bytesString[i];
        }
        return string(bytesStringTrimmed);
    }


    /* This unnamed function is called whenever someone tries to send ether to it */
    function () public {
        require(false);     // Prevents accidental sending of ether
    }

}
