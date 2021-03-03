pragma solidity ^0.4.18;

import "./BlockcheqCore.sol";
import "./BankStore.sol";

contract AuthorizedBank is BlockcheqCore {

	bytes32 public code;
	BankStore private bankStore;

	function setBankCode(bytes32 _code) public onlyBy(owner) {
		code = _code;
	}

	function setBankStoreContract(address _bankStoreContract) public onlyBy(owner)  {
        bankStore = BankStore(_bankStoreContract);
    }    

	modifier authorizedBank {
		bool auth;
		(,,,,,auth,) = bankStore.getByCode(code);
        require(auth);
        _;
    }

}

