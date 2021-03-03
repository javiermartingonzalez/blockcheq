
pragma solidity ^0.4.18;

import "./BlockcheqCore.sol";
import "./AccountStore.sol";
import "./CheckStore.sol";

contract CheckManager is BlockcheqCore {
    mapping (uint8 => mapping (uint8 => mapping (uint8 => uint8[5]))) private promotions;
    address private aStoreAddress;
    address private cStoreAddress;

    CheckStore private cStore;
    AccountStore private aStore;

    function setCheckStore(address storeContract) public onlyBy(owner) {
        cStoreAddress = storeContract;
        cStore = CheckStore(storeContract);
    }

    function setAccountStore(address storeContract) public onlyBy(owner) {
        aStoreAddress = storeContract;
        aStore = AccountStore(storeContract);
    }

    function getCheckStore () public view returns(address) {
        return cStoreAddress;
    }

    function getAccountStore () public view returns(address) {
        return aStoreAddress;
    }

    function setPromotion(uint8 checkType, CheckStatus prev, CheckStatus post, uint8 rol, uint8 security, uint8 updateDepAcc, uint8 updateSecCod, uint8 revertStatus) public onlyBy(owner) {
        promotions[uint8(checkType)][uint8(prev)][uint8(post)] = [rol, security, updateDepAcc, updateSecCod, revertStatus];
    }

    function getPromotion(uint8 checkType, CheckStatus prev, CheckStatus post) public view onlyBy(owner) returns (uint8 rol, uint8 security, uint8 updateDepAcc, uint8 updateSecCod, uint8 revertStatus) {
        uint8[5] storage promo = promotions[uint8(checkType)][uint8(prev)][uint8(post)];
        (rol, security, updateDepAcc, updateSecCod, revertStatus) = (promo[PROMO_ROL], promo[PROMO_SECURITY], promo[PROMO_UPDATEDEPACC], promo[PROMO_UPDATESECCOD], promo[PROMO_REVERTSTATUS]);
    }

    function addCheck(bytes32[2] account, bytes32[2] codeline, uint checkType, bytes32 certifier) public {
        uint8[5] storage promo = promotions[uint8(checkType)][uint8(CheckStatus.Issued)][uint8(CheckStatus.Issued)];

        require(validRolAdd(promo[PROMO_ROL], account));
        cStore.add(account, codeline, checkType, certifier);
    }


    function setStatus(bytes32[2] codeline, uint256 amount, uint date, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32 currentSecurityCode, bytes32 newSecurityCode, bytes32 deliveredIdentifier, bytes32 certifier) public {
        uint8[5] memory promo;

        (promo, ) = requirements(codeline, status, currentSecurityCode);

        bytes32[3] memory varbyte32;
        varbyte32[0] = newSecurityCode;
        varbyte32[1] = deliveredIdentifier;
        varbyte32[2] = certifier;


        checkUpdate(promo, codeline, amount, date, status, depositAccount, deliveredTo, reason, varbyte32);
    }


    function setStatusByHash(bytes32 codelineHash, uint256 amount, uint date, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32 currentSecurityCode, bytes32 newSecurityCode, bytes32 deliveredIdentifier, bytes32 certifier) public {
        uint8[5] memory promo;
        (promo, ) = requirementsByHash(codelineHash, status, currentSecurityCode);

        bytes32[3] memory varbyte32;
        varbyte32[0] = newSecurityCode;
        varbyte32[1] = deliveredIdentifier;
        varbyte32[2] = certifier;

        checkUpdateByHash(promo, codelineHash, amount, date, status, depositAccount, deliveredTo, reason, varbyte32);
    }

    function requirements(bytes32[2] codeline, CheckStatus status, bytes32 currentSecurityCode) internal view returns(uint8[5] promo, uint currentV) {
        CheckStatus cStatus;
        bytes32[2] memory secCodeHash;
        bytes32[2] memory currentDA;
        uint checktype;
        (,,,currentV,checktype,) = cStore.getBase(codeline);
        (cStatus, currentDA, , , secCodeHash, , ) = cStore.getVersion(codeline,currentV);
        promo = promotions[uint8(checktype)][uint8(cStatus)][uint8(status)];

        require(validRol(promo[PROMO_ROL], currentDA, keccak256(codeline[0],codeline[1]), currentV));
        require(validSecurity(promo[PROMO_SECURITY], currentSecurityCode, secCodeHash));
    }

    function requirementsByHash(bytes32 codelineHash, CheckStatus status, bytes32 currentSecurityCode) internal view returns(uint8[5] promo, uint currentV) {
        CheckStatus cStatus;
        bytes32[2] memory secCodeHash;
        bytes32[2] memory currentDA;
        uint checktype;
        (,,,,currentV,checktype,) = cStore.getBaseByHash(codelineHash);
        (cStatus, currentDA, , , secCodeHash, , ) = cStore.getVersionByHash(codelineHash,currentV);
        promo = promotions[uint8(checktype)][uint8(cStatus)][uint8(status)];

        require(validRol(promo[PROMO_ROL], currentDA, codelineHash, currentV));
        require(validSecurity(promo[PROMO_SECURITY], currentSecurityCode, secCodeHash));
    }

    function getFieldPermisionToUpdate(uint8 permision, uint8 field) internal pure returns(uint8) {
        //field 1
        //0000 - 0 no modify allowed in deposit account
        //0100 - 1 modify allowed in deposit account
        //1000 - 2 must modify deposit account
        //field 0
        //0000 - 0 no modify allowed in deliveredTo
        //0001 - 1 modify allowed in deliveredTo
        //0010 - 2 must modify deliveredTo
        return (permision >> (2*field)) & 3;
    }


    function checkUpdate(uint8[5] promo, bytes32[2] codeline, uint amount, uint date, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32[3] varbyte32) internal {
        bytes32[2] memory da = calculateAttribUpdate(getFieldPermisionToUpdate(promo[PROMO_UPDATEDEPACC], FIELD_DEPOSITACC), depositAccount);
        bytes32[2] memory sc = calculateTokenUpdate(promo[PROMO_UPDATESECCOD], varbyte32[0]);
        bytes32 ide = calculateAttribUpdateb32(promo[PROMO_UPDATEDEPACC], varbyte32[1]);


        cStore.update(codeline, amount, date, status, da, deliveredTo, reason, sc, ide, varbyte32[2]);
        if(promo[PROMO_REVERTSTATUS] > 0) {
            cStore.revertVersions(codeline, promo[PROMO_REVERTSTATUS]);
        }
    }

    function checkUpdateByHash(uint8[5] promo, bytes32 codelineHash, uint amount, uint date, CheckStatus status, bytes32[2] depositAccount, bytes32[2] deliveredTo, bytes32[2] reason, bytes32[3] varbyte32) internal {
        bytes32[2] memory da = calculateAttribUpdate(getFieldPermisionToUpdate(promo[PROMO_UPDATEDEPACC], FIELD_DEPOSITACC), depositAccount);

        bytes32[2] memory sc = calculateTokenUpdate(promo[PROMO_UPDATESECCOD], varbyte32[0]);
        bytes32 ide = calculateAttribUpdateb32(promo[PROMO_UPDATEDEPACC], varbyte32[1]);

        cStore.updateByHash(codelineHash, amount, date, status, da, deliveredTo, reason, sc, ide, varbyte32[2]);

        if(promo[PROMO_REVERTSTATUS] > 0) {
            cStore.revertVersionsByHash(codelineHash, promo[PROMO_REVERTSTATUS]);
        }
    }

    function validRol(uint8 rol, bytes32[2] depositAccount, bytes32 codelineHash, uint currentV) internal view returns(bool) {
        if(rol == 0){
            return false;
        }

        if(rol == EVERYBODY_HAS_PERMISSION){
            return true;
        }

        if(rol & BANK_OWNER > 0) {
            if(sender(owner)){
                return true;
            }
        }

        bytes32 accHash = keccak256(depositAccount[0], depositAccount[1]);

        if(rol & CHCK_OWNER > 0) {
            if(cStore.isOwner(codelineHash, msg.sender) || cStore.isOwner(codelineHash, tx.origin)){
                return true;
            }
        }


        if(rol & CHCK_DEST > 0) {
            if(cStore.isDest(codelineHash, currentV, msg.sender)
                || cStore.isDest(codelineHash, currentV, tx.origin)
                || (aStore.getHashByOwner(msg.sender) == accHash)
                || (aStore.getHashByOwner(tx.origin) == accHash)){
                return true;
            }
        }
        return false;
    }

	   function validRolAdd(uint8 rol, bytes32[2] accountNumber) internal view returns(bool) {
        if(rol == 0){
            return false;
        }

        if(rol == EVERYBODY_HAS_PERMISSION){
            return true;
        }

        if(rol & BANK_OWNER > 0) {
            if(sender(owner)){
                return true;
            }
        }

		     address ownerAccount;
		     (ownerAccount, , , ) = aStore.getByNumber(accountNumber);

         if(rol & CHCK_OWNER > 0) {
           if(sender(ownerAccount)){
               return true;
           }
         }

         return false;
    }

    function validSecurity(uint8 security, bytes32 currentSecurityCode,  bytes32[2] secCodeHash) internal view returns(bool) {
        if(security == 0) {return b32Empty(currentSecurityCode);} // no security required
        if(secCodeHash[0] == bytes32(0x0) && secCodeHash[1] == bytes32(0x0) && b32Empty(currentSecurityCode)) {return true;} // security required but set empty

        if(sender(owner)) {
            if((security & CERTIFIER_SECURITY)>0){
              if(secCodeHash[1] == bytes32(0x0) && b32Empty(currentSecurityCode)) {
                return true; // security required but set empty for certifier
              } else {
                return(secCodeHash[1] == keccak256(currentSecurityCode));
              }
            } else if((security & BANKER_SECURITY)>0){
              if(secCodeHash[0] == bytes32(0x0) && b32Empty(currentSecurityCode)) {
                return true; // security required but set empty for banker
              } else {
                return(secCodeHash[0] == keccak256(currentSecurityCode));
              }
            } else {
                return true;
            }
        }
        if((security & USER_SECURITY)>0) {
          if(secCodeHash[0] == bytes32(0x0) && b32Empty(currentSecurityCode)) {
            return true; // security required but set empty for user
          } else {
            return(secCodeHash[0] == keccak256(currentSecurityCode));
          }
        }
        return false;
    }

    function calculateAttribUpdate(uint8 config, bytes32[2] attrib) internal view returns (bytes32[2]) {
        if(config == 0) {
            require (doubleb32Empty(attrib));
        } else if((config & MUST_UPDATE) > 0){
            require (!doubleb32Empty(attrib));
        }
        return attrib;
    }

    function calculateAttribUpdateb32(uint8 config, bytes32 attrib) internal view returns (bytes32) {
        if(config == 0) {
            require (b32Empty(attrib));
        } else if((config & MUST_UPDATE) > 0){
            require (!b32Empty(attrib));
        }
        return attrib;
    }

    function calculateTokenUpdate(uint8 config, bytes32 attrib) internal view returns (bytes32[2] memory token) {
    if((config & MUST_UPDATE) > 0){
        require (!b32Empty(attrib));
    } else if(config & CAN_UPDATE == 0){
        require (b32Empty(attrib));
    }

    if(config & CERTIFIER_UPDATE > 0) {
        token[1] = attrib;
    } else {
        token[0] = attrib;
    }
}
}
