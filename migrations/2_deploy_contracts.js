var Regulator = artifacts.require('Regulator');
var BankStore = artifacts.require('BcBankStore');
var TransactionStore = artifacts.require('BcTransactionStore');
var Banker = artifacts.require('Banker');
var AccountStore = artifacts.require('BcAccountStore');
var CheckStore = artifacts.require('BcCheckStore');
var CheckManagerStore = artifacts.require('CheckManager');
var ReceiverStore = artifacts.require('BcReceiverStore');
var IdentityStore = artifacts.require('BcIdentityStore');
var Customer = artifacts.require('Customer');
var CheckTypeStore = artifacts.require('BcCheckTypeStore');

var CheckStatus = {
	'Issued': 0,
	'Filled': 1,
	'ReservedFunds': 2,
	'Delivered': 3,
	'Accepted': 4,
	'PendingCertification': 5,
	'Certified': 6,
	'Deposited': 7,
	'SentToHost': 8,
	'Paid': 9,
	'NotAccepted': 10,
	'RejectedConformation': 11,
	'RejectedCertification': 12,
	'ReleasedFunds': 13,
	'Rejected': 14,
	'Locked': 15,
	'Completed': 16,
	'DepositRejected': 17,
	'Endorsed': 18
}

var Rol = {
	'CheckOwner' : 1,
	'Banker' : 2,
	'CheckDest' : 4,
	'Everybody' : 8
}

var CheckType = {
	'Check' : 0,
	'ConformedCheck' : 1,
	'PromissoryNote' : 2,
	'ConformedPromissoryNote' : 3
}

var setPromotions = async function(checkmanager, bankaddress) {

	var configPromotion = async function(checkType, currentStatus, newStatus, Rol, security, depAcc, secCode, searchStatus){
		await checkmanager.setPromotion(checkType, currentStatus, newStatus, Rol, security, depAcc, secCode, searchStatus, {from : bankaddress});
	}
	/* LEGEND *******************************************************************************************************

	   ROLES (Who can do the promotion)      FIELDS
	   0001 - 1 - CHECK_OWNER                0000 - 0 - No modify allowed in deliveredTo and deposit account fileds.
	   0010 - 2 - BANK_OWNER                 0001 - 1 - Modify allowed in deliveredTo field.
	   0100 - 4 - CHECK_DEST                 0010 - 2 - Must modify deliveredTo field.
	   1000 - 8 - EVERYBODY                  0100 - 4 - Modify allowed in deposit account field.
											 1000 - 8 - Must modify deposit account field.
	   SECURITY (Who need securityCode)
	   0001 - 1 - USER_SECURITY
	   0010 - 2 - BANKER_SECURITY            searchStatus (status to revert if exists and not equal to issued(0))
	   0100 - 4 - CERTIFIER

	   TOKEN (SecurityCode update config)
	   0001 - 1 - CAN_UPDATE
	   0010 - 2 - MUST_UPDATE
	   0100 - 4 - CERTIFIER

	   ****************************************************************************************************************/

	// Promotions                                                                                                                                                 (token)
	//              checkType,                         from,                               to,                                 Rol,             security, depAcc, secCode, RevertStatus
	//              ---------------------------------  ----------------------------------  ----------------------------------  ---------------  --------  ------  -------  ---------------------
	// Flow type Check
	await configPromotion(CheckType.Check,                   CheckStatus.Issued,                 CheckStatus.Issued,                 Rol.CheckOwner | Rol.Banker,  0,        5,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Issued,                 CheckStatus.Filled,                 Rol.CheckOwner | Rol.Banker,  0,        5,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Filled,                 CheckStatus.Delivered,              Rol.Banker,      0,        5,      1,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Delivered,              CheckStatus.Accepted,               Rol.Everybody,   3,        4,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Delivered,              CheckStatus.NotAccepted,            Rol.Everybody,   3,        0,      0,       CheckStatus.Accepted); // delivered to not accepted
	await configPromotion(CheckType.Check,                   CheckStatus.Accepted,               CheckStatus.Deposited,              Rol.Everybody,   3,        4,      0,       0                   );

	await configPromotion(CheckType.Check,                   CheckStatus.Accepted,               CheckStatus.PendingCertification,   Rol.Banker,      0,        0,      5,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.PendingCertification,   CheckStatus.Certified,              Rol.Banker,      4,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.PendingCertification,   CheckStatus.RejectedCertification,  Rol.Banker,      4,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Certified,              CheckStatus.Deposited,              Rol.Everybody,   3,        4,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.RejectedCertification,  CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Certified,              CheckStatus.Endorsed,               Rol.Everybody,   3,        6,      1,       0                   ); // certified to new status endorsed [case not previously covered]

	await configPromotion(CheckType.Check,                   CheckStatus.NotAccepted,            CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Accepted,               CheckStatus.Endorsed,               Rol.Everybody,   3,        6,      1,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Endorsed,               CheckStatus.Delivered,              Rol.Banker,      0,        5,      1,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Deposited,              CheckStatus.Paid,                   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Deposited,              CheckStatus.DepositRejected,        Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.DepositRejected,        CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	// Out of flow TimeOut
	await configPromotion(CheckType.Check,                   CheckStatus.Delivered,              CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Accepted,               CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	// Out of flow Administrator
	await configPromotion(CheckType.Check,                   CheckStatus.Filled,                 CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Filled,                 CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Filled,                 CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Delivered,              CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Delivered,              CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Accepted,               CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Accepted,               CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Deposited,              CheckStatus.SentToHost,             Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Deposited,              CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Deposited,              CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Deposited,              CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.SentToHost,             CheckStatus.Paid,                   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.SentToHost,             CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.SentToHost,             CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.SentToHost,             CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Paid,                   CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.NotAccepted,            CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.NotAccepted,            CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Rejected,               CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Rejected,               CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Locked,                 CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.Issued,                 CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   ); // issued to locked
	// Out of Flow Administrador - Certified

	await configPromotion(CheckType.Check,                   CheckStatus.PendingCertification,   CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.PendingCertification,   CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.RejectedCertification,  CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.Check,                   CheckStatus.RejectedCertification,  CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	console.log("Set promotions to CheckType Check");
	// Promotions
	//              checkType,                         from,                               to,                                 Rol,             security, depAcc, secCode, RevertStatus
	//              ---------------------------------  ----------------------------------  ----------------------------------  ---------------  --------  ------  -------  ---------------------
	// Flow type PromissoryNote
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Issued,                 CheckStatus.Issued,                 Rol.CheckOwner | Rol.Banker,  0,        5,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Issued,                 CheckStatus.Filled,                 Rol.CheckOwner | Rol.Banker,  0,        5,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Filled,                 CheckStatus.Delivered,              Rol.Banker,      0,        5,      1,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Delivered,              CheckStatus.Accepted,               Rol.Everybody,   3,        4,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Delivered,              CheckStatus.NotAccepted,            Rol.Everybody,   3,        0,      0,       CheckStatus.Accepted); // delivered to not accepted
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Accepted,               CheckStatus.Deposited,              Rol.Everybody,   3,        4,      0,       0                   );

	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Accepted,               CheckStatus.PendingCertification,   Rol.Banker,      0,        0,      5,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.PendingCertification,   CheckStatus.Certified,              Rol.Banker,      4,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.PendingCertification,   CheckStatus.RejectedCertification,  Rol.Banker,      4,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Certified,              CheckStatus.Deposited,              Rol.Everybody,   3,        4,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.RejectedCertification,  CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Certified,              CheckStatus.Endorsed,               Rol.Everybody,   3,        6,      1,       0                   ); // certified to new status endorsed [case not previously covered]

	await configPromotion(CheckType.PromissoryNote,          CheckStatus.NotAccepted,            CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Accepted,               CheckStatus.Endorsed,               Rol.Everybody,   3,        6,      1,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Endorsed,               CheckStatus.Delivered,              Rol.Banker,      0,        5,      1,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Deposited,              CheckStatus.Paid,                   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Deposited,              CheckStatus.DepositRejected,        Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.DepositRejected,        CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	// Out of flow TimeOut
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Delivered,              CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Accepted,               CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	// Out of flow Administrator
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Filled,                 CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Filled,                 CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Filled,                 CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Delivered,              CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Delivered,              CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Accepted,               CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Accepted,               CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Deposited,              CheckStatus.SentToHost,             Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Deposited,              CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Deposited,              CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Deposited,              CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.SentToHost,             CheckStatus.Paid,                   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.SentToHost,             CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.SentToHost,             CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.SentToHost,             CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Paid,                   CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.NotAccepted,            CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.NotAccepted,            CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Rejected,               CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Rejected,               CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Locked,                 CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.Issued,                 CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   ); // issued to locked
	// Out of Flow Administrador - Certified

	await configPromotion(CheckType.PromissoryNote,          CheckStatus.PendingCertification,   CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   ); //
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.PendingCertification,   CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   ); //
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.RejectedCertification,  CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   ); //
	await configPromotion(CheckType.PromissoryNote,          CheckStatus.RejectedCertification,  CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   ); //
	console.log("Set promotions to CheckType PromissoryNote")
	// Promotions
	//              checkType,                         from,                               to,                                 Rol,             security, depAcc, secCode, RevertStatus
	//              ---------------------------------  ----------------------------------  ----------------------------------  ---------------  --------  ------  -------  ---------------------
	// Flow type ConformedCheck
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Issued,                 CheckStatus.Issued,                 Rol.CheckOwner | Rol.Banker,  0,        5,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Issued,                 CheckStatus.Filled,                 Rol.CheckOwner | Rol.Banker,  0,        5,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Filled,                 CheckStatus.ReservedFunds,          Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Filled,                 CheckStatus.Delivered,              Rol.Banker,      0,        5,      1,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Filled,                 CheckStatus.RejectedConformation,   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.RejectedConformation,   CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.ReservedFunds,          CheckStatus.Delivered,              Rol.Banker,      0,        0,      1,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Delivered,              CheckStatus.Accepted,               Rol.Everybody,   3,        4,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Delivered,              CheckStatus.NotAccepted,            Rol.Everybody,   3,        0,      0,       CheckStatus.Accepted); // delivered to not accepted
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Accepted,               CheckStatus.Deposited,              Rol.Everybody,   3,        4,      0,       0                   );

	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Accepted,               CheckStatus.PendingCertification,   Rol.Banker,      0,        0,      5,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.PendingCertification,   CheckStatus.Certified,              Rol.Banker,      4,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.PendingCertification,   CheckStatus.RejectedCertification,  Rol.Banker,      4,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Certified,              CheckStatus.Deposited,              Rol.Everybody,   3,        4,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.RejectedCertification,  CheckStatus.ReleasedFunds,          Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Certified,              CheckStatus.Endorsed,               Rol.Everybody,   3,        6,      1,       0                   ); // certified to new status endorsed [case not previously covered]

	await configPromotion(CheckType.ConformedCheck,          CheckStatus.NotAccepted,            CheckStatus.ReleasedFunds,          Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Accepted,               CheckStatus.Endorsed,               Rol.Everybody,   3,        6,      1,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Endorsed,               CheckStatus.Delivered,              Rol.Banker,      0,        5,      1,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.ReleasedFunds,          CheckStatus.DepositRejected,        Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.DepositRejected,        CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Deposited,              CheckStatus.Paid,                   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Deposited,              CheckStatus.ReleasedFunds,          Rol.Banker,      0,        0,      0,       0                   );
	// Out of flow TimeOut
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Delivered,              CheckStatus.ReleasedFunds,          Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Accepted,               CheckStatus.ReleasedFunds,          Rol.Banker,      0,        0,      0,       0                   );
	// Out of flow Administrator
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Filled,                 CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Filled,                 CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Filled,                 CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.ReservedFunds,          CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.ReservedFunds,          CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.ReservedFunds,          CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.ReservedFunds,          CheckStatus.RejectedConformation,   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Delivered,              CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Delivered,              CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Delivered,              CheckStatus.RejectedConformation,   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Accepted,               CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Accepted,               CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Accepted,               CheckStatus.RejectedConformation,   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Deposited,              CheckStatus.SentToHost,             Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Deposited,              CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Deposited,              CheckStatus.RejectedConformation,   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Deposited,              CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Deposited,              CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.SentToHost,             CheckStatus.Paid,                   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.SentToHost,             CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.SentToHost,             CheckStatus.RejectedConformation,   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.SentToHost,             CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.SentToHost,             CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Paid,                   CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.NotAccepted,            CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.NotAccepted,            CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.RejectedConformation,   CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.RejectedConformation,   CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.ReleasedFunds,          CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.ReleasedFunds,          CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Rejected,               CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Rejected,               CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Locked,                 CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.Issued,                 CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   ); // issued to locked
	// Out of Flow Administrador - Certified

	await configPromotion(CheckType.ConformedCheck,          CheckStatus.PendingCertification,   CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   ); //
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.PendingCertification,   CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   ); //
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.RejectedCertification,  CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   ); //
	await configPromotion(CheckType.ConformedCheck,          CheckStatus.RejectedCertification,  CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   ); //
	console.log("Set promotions to CheckType ConformedCheck")
	// Promotions
	//              checkType,                         from,                               to,                                 Rol,             security, depAcc, secCode, RevertStatus
	//              ---------------------------------  ----------------------------------  ----------------------------------  ---------------  --------  ------  -------  ---------------------
	// Flow type ConformedPromissoryNote
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Issued,                 CheckStatus.Issued,                 Rol.CheckOwner | Rol.Banker,  0,        5,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Issued,                 CheckStatus.Filled,                 Rol.CheckOwner | Rol.Banker,  0,        5,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Filled,                 CheckStatus.ReservedFunds,          Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Filled,                 CheckStatus.Delivered,              Rol.Banker,      0,        5,      1,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Filled,                 CheckStatus.RejectedConformation,   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.RejectedConformation,   CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.ReservedFunds,          CheckStatus.Delivered,              Rol.Banker,      0,        0,      1,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Delivered,              CheckStatus.Accepted,               Rol.Everybody,   3,        4,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Delivered,              CheckStatus.NotAccepted,            Rol.Everybody,   3,        0,      0,       CheckStatus.Accepted); // delivered to not accepted
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Accepted,               CheckStatus.Deposited,              Rol.Everybody,   3,        4,      0,       0                   );

	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Accepted,               CheckStatus.PendingCertification,   Rol.Banker,      0,        0,      5,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.PendingCertification,   CheckStatus.Certified,              Rol.Banker,      4,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.PendingCertification,   CheckStatus.RejectedCertification,  Rol.Banker,      4,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Certified,              CheckStatus.Deposited,              Rol.Everybody,   3,        4,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.RejectedCertification,  CheckStatus.ReleasedFunds,          Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Certified,              CheckStatus.Endorsed,               Rol.Everybody,   3,        6,      1,       0                   ); // certified to new status endorsed [case not previously covered]

	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.NotAccepted,            CheckStatus.ReleasedFunds,          Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Accepted,               CheckStatus.Endorsed,               Rol.Everybody,   3,        6,      1,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Endorsed,               CheckStatus.Delivered,              Rol.Banker,      0,        5,      1,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.ReleasedFunds,          CheckStatus.DepositRejected,        Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.DepositRejected,        CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Deposited,              CheckStatus.Paid,                   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Deposited,              CheckStatus.ReleasedFunds,          Rol.Banker,      0,        0,      0,       0                   );
	// Out of flow TimeOut
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Delivered,              CheckStatus.ReleasedFunds,          Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Accepted,               CheckStatus.ReleasedFunds,          Rol.Banker,      0,        0,      0,       0                   );
	// Out of flow Administrator
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Filled,                 CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Filled,                 CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Filled,                 CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.ReservedFunds,          CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.ReservedFunds,          CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.ReservedFunds,          CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.ReservedFunds,          CheckStatus.RejectedConformation,   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Delivered,              CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Delivered,              CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Delivered,              CheckStatus.RejectedConformation,   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Accepted,               CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Accepted,               CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Accepted,               CheckStatus.RejectedConformation,   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Deposited,              CheckStatus.SentToHost,             Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Deposited,              CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Deposited,              CheckStatus.RejectedConformation,   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Deposited,              CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Deposited,              CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.SentToHost,             CheckStatus.Paid,                   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.SentToHost,             CheckStatus.Rejected,               Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.SentToHost,             CheckStatus.RejectedConformation,   Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.SentToHost,             CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.SentToHost,             CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Paid,                   CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.NotAccepted,            CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.NotAccepted,            CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.RejectedConformation,   CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.RejectedConformation,   CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.ReleasedFunds,          CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.ReleasedFunds,          CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Rejected,               CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Rejected,               CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Locked,                 CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   );
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.Issued,                 CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   ); // issued to locked
	// Out of Flow Administrador - Certified

	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.PendingCertification,   CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   ); //
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.PendingCertification,   CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   ); //
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.RejectedCertification,  CheckStatus.Completed,              Rol.Banker,      0,        0,      0,       0                   ); //
	await configPromotion(CheckType.ConformedPromissoryNote, CheckStatus.RejectedCertification,  CheckStatus.Locked,                 Rol.Banker,      0,        0,      0,       0                   ); //
	console.log("Set promotions to CheckType ConformedPromissoryNote")
};

module.exports = async function (deployer, network, accounts) {	
	if (network == "test") return; // test maintains own contracts

	var regulatorname = "Coelsa";

	var bankCode1 = "2038";
	var bankName1 = "Bankia";

	var bankCode2 = "0049";
	var bankName2 = "Santander";

	var inicode = 0;
	var lengthcode = 4;

	var regulatoruser  = accounts[0];
	var bank1Eth  = accounts[1];
	var bank2Eth = accounts[2];

  	//DEPLOY CONTRACTS

  	var regulatorD = await Regulator.new({ from: regulatoruser });
  	var customerD = await Customer.new({ from: regulatoruser });
  	var banker1D = await Banker.new({ from: bank1Eth });
	var banker2D = await Banker.new({ from: bank2Eth });
  	var bankD = await BankStore.new({ from: regulatoruser });
  	var transactionD = await TransactionStore.new({ from: regulatoruser });
  	var receiverD = await ReceiverStore.new({ from: regulatoruser });
  	var identityD = await IdentityStore.new({ from: regulatoruser });
  	var account1D = await AccountStore.new({ from: bank1Eth });
  	var check1D = await CheckStore.new({ from: bank1Eth });
  	var checkmanager1D = await CheckManagerStore.new({ from: bank1Eth });
  	var account2D = await AccountStore.new({ from: bank2Eth });
  	var check2D = await CheckStore.new({ from: bank2Eth });
  	var checkmanager2D = await CheckManagerStore.new({ from: bank2Eth });
  	var checkTypeD = await CheckTypeStore.new({ from: regulatoruser });

  	console.log("Regulator deployed! Contract address: " + regulatorD.address)
	console.log("Customer deployed! Contract address: " + customerD.address)
	console.log("Banker1 deployed! Contract address: " + banker1D.address)
	console.log("Banker2 deployed! Contract address: " + banker2D.address)
	console.log("TransactionStore deployed! Contract address: " + transactionD.address)
	console.log("ReceiverStore deployed! Contract address: " + receiverD.address)
	console.log("IdentityStore deployed! Contract address: " + identityD.address)
	console.log("AccountStore1 deployed! Contract address: " + account1D.address)
	console.log("CheckStore1 deployed! Contract address: " + check1D.address)
	console.log("CheckManager1 deployed! Contract address: " + checkmanager1D.address)
	console.log("AccountStore2 deployed! Contract address: " + account2D.address)
	console.log("CheckStore2 deployed! Contract address: " + check2D.address)
	console.log("CheckManager2 deployed! Contract address: " + checkmanager2D.address)
	console.log("CheckTypeStore deployed! Contract address: " + checkTypeD.address)

  	// LINK CONTRACTS
	 
  	// Linking regulator
  	await transactionD.setBankStoreContract(bankD.address, {from:regulatoruser});
  	await regulatorD.setBankContract(bankD.address, {from:regulatoruser});
  	await regulatorD.setTransactionContract(transactionD.address, {from:regulatoruser});
  	await regulatorD.setRegulatorName(regulatorname,{from:regulatoruser});

 	// Linking customer
  	await receiverD.setBankStore(bankD.address,{from:regulatoruser});
  	await customerD.setReceiverStore(receiverD.address,{from:regulatoruser});
  	await customerD.setIdentityStore(identityD.address,{from:regulatoruser});
  	await customerD.setCheckTypeStore(checkTypeD.address,{from:regulatoruser});

  	// Linking bank1
  	await banker1D.setAccountContract(account1D.address, {from:bank1Eth});
  	await banker1D.setCheckContract(check1D.address, {from:bank1Eth});
  	await banker1D.setCheckManagerContract(checkmanager1D.address, {from:bank1Eth});//??
  	await banker1D.setIdentityStore(identityD.address,{from:regulatoruser});

  	await check1D.setManagerContractAddress(checkmanager1D.address, {from:bank1Eth});
  	await check1D.setAccountStore(account1D.address, {from:bank1Eth});
  	await check1D.setTransactionStore(transactionD.address, {from:bank1Eth});
  	await check1D.setReceiverStore(receiverD.address, {from:bank1Eth});
  	await check1D.setCheckTypeStore(checkTypeD.address,{from:bank1Eth});

  	await checkmanager1D.setAccountStore(account1D.address, {from:bank1Eth});
  	await checkmanager1D.setCheckStore(check1D.address, {from:bank1Eth});

  	///Linking bank2
  	await banker2D.setAccountContract(account2D.address, {from:bank2Eth});
  	await banker2D.setCheckContract(check2D.address, {from:bank2Eth});
  	await banker2D.setCheckManagerContract(checkmanager2D.address, {from:bank2Eth});//??
  	await banker2D.setIdentityStore(identityD.address,{from:regulatoruser});

  	await check2D.setManagerContractAddress(checkmanager2D.address, {from:bank2Eth});
  	await check2D.setTransactionStore(transactionD.address, {from:bank2Eth});
  	await check2D.setAccountStore(account2D.address, {from:bank2Eth});
  	await check2D.setReceiverStore(receiverD.address, {from:bank2Eth});
  	await check2D.setCheckTypeStore(checkTypeD.address,{from:bank2Eth});

  	await checkmanager2D.setAccountStore(account2D.address, {from:bank2Eth});
 	await checkmanager2D.setCheckStore(check2D.address, {from:bank2Eth});

  	// INIT CONTRACTS
  
 	// Adding check types
  	await customerD.addCheckType("Check", "=", 0, {from:regulatoruser});
  	await customerD.addCheckType("ConformedCheck", "=", 0, {from:regulatoruser});
  	await customerD.addCheckType("PromissoryNote", ">", 2, {from:regulatoruser});
  	await customerD.addCheckType("ConformedPromissoryNote", ">", 2, {from:regulatoruser});

  	await bankD.setCodeLocation(inicode, lengthcode);

  	// Init bank 1
	console.log();
	console.log("BANK 1 - Setting Promotions...")
  	await setPromotions(checkmanager1D, bank1Eth);
  	await account1D.setCheckStoreAddress(check1D.address, {from: bank1Eth});
  	await check1D.setManagerContractAddress(checkmanager1D.address, {from : bank1Eth});
  	await account1D.setBankCode(web3.utils.fromAscii(bankCode1), {from: bank1Eth}); 
  	await account1D.setBankStoreContract(bankD.address, {from : bank1Eth});
  	await check1D.setBankCode(web3.utils.fromAscii(bankCode1), {from : bank1Eth});
  	await regulatorD.addBank(bankCode1, bankName1, bank1Eth, banker1D.address, {from:regulatoruser});
  	//await banker1D.addAccount(web3.personal.listAccounts[3], "203800018111111111119", 300000000000, {from:bank1Eth}); // REGISTRAR NUEVO USUARIO, SE PUEDE HACER EN INTERFAZ
  	//await banker1D.addAccount(web3.personal.listAccounts[4], "203800028222222222229", 300000000000, {from:bank1Eth});  // REGISTRAR NUEVO USUARIO, SE PUEDE HACER EN INTERFAZ

  	// Init bank 2
	console.log();
	console.log("BANK 2 - Setting Promotions...")
  	await setPromotions(checkmanager2D, bank2Eth);
  	await account2D.setCheckStoreAddress(check2D.address, {from: bank2Eth});
  	await check2D.setManagerContractAddress(checkmanager2D.address, {from : bank2Eth});
  	await account2D.setBankCode(web3.utils.fromAscii(bankCode2), {from: bank2Eth}); 
  	await account2D.setBankStoreContract(bankD.address, {from : bank2Eth});
  	await check2D.setBankCode(web3.utils.fromAscii(bankCode2), {from : bank2Eth});
  	await regulatorD.addBank(bankCode2, bankName2, bank2Eth, banker2D.address, {from:regulatoruser});
  	//await banker2D.addAccount(web3.personal.listAccounts[5], "004900018111111111130", 300000000000, {from:bank1Eth});  // REGISTRAR NUEVO USUARIO, SE PUEDE HACER EN INTERFAZ
};
