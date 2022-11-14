public class TriggerHandler {
	public static void beforeInsert(List<AccountContact__c> newRecordList) {
        Set<Id> uniqueContactSetFromTrigger = new Set<Id>();
        for(AccountContact__c currentRecordToAddInSet : newRecordList){
            uniqueContactSetFromTrigger.add(currentRecordToAddInSet.Contact__c);
        }
		List<AccountContact__c> accountContactListFromDB = [	// has to form list of AccountContact records
				SELECT 	Name,									// with Contacts same as the ones to be inserted
						isPrimary__c,
						Account__c,
						Contact__c
				FROM 	AccountContact__c
				WHERE 	Contact__c IN : uniqueContactSetFromTrigger];
		List<AccountContact__c> accountContactListToBeUpdated = new List<AccountContact__c>();	// list with DB AC records
		// At this moment we have Lists of AccountContacts` records from Trigger and from DB
		for(AccountContact__c currentRecordFromTrigger : newRecordList){
			if(currentRecordFromTrigger.isPrimary__c){
				for(AccountContact__c currentRecordFromDB : accountContactListFromDB){
					if(currentRecordFromDB.isPrimary__c && currentRecordFromDB.Contact__c == currentRecordFromTrigger.Contact__c){
						currentRecordFromDB.isPrimary__c = false;
						accountContactListToBeUpdated.add(currentRecordFromDB);
					}
				}
			} else if(!currentRecordFromTrigger.isPrimary__c){			// if we insert single record with new Contact__c
				if(accountContactListFromDB.size()>0){					// cycle has nothing to compare with
					for(AccountContact__c currentRecordFromDB : accountContactListFromDB){
						if(currentRecordFromTrigger.isPrimary__c != currentRecordFromDB.isPrimary__c){
							continue;
						} else {currentRecordFromTrigger.isPrimary__c = true;}
					}
				} else {currentRecordFromTrigger.isPrimary__c = true;}
			}
		}
		/* 	this algorithm already removes isPrimary from older record
			and changes isPrimary->true if the inserted record is first for this Contact.
			But doesnt take into account the possibility of inserting records
			with the same Contact__c -> multiple records with isPrimary=true
		 	TODO:? unique AccountContact__c records with equal Contact__c */
		if(accountContactListToBeUpdated.size()>0){
			update accountContactListToBeUpdated;
			System.debug(accountContactListToBeUpdated.size() + ' records were updated.');
		}
	}
	public static void beforeUpdate(List<AccountContact__c> newRecordList, List<AccountContact__c> oldRecordList) {
		Set<Id> uniqueContactSetFromTrigger = new Set<Id>();
		for(AccountContact__c currentRecordToAddInSet : newRecordList){
			uniqueContactSetFromTrigger.add(currentRecordToAddInSet.Contact__c);
		}
		List<AccountContact__c> accountContactListFromDB = [	// has to form list of AccountContact records
				SELECT 	Name,									// with Contacts same as the ones to be inserted
						isPrimary__c,
						Account__c,
						Contact__c,
						CreatedDate
				FROM 	AccountContact__c
				WHERE 	Contact__c IN : uniqueContactSetFromTrigger];

		List<AccountContact__c> recordListForParticularContactFromDB = new List<AccountContact__c>();
		// list for further temporary storage of contacts to be sorted by CreatedDate

		List<AccountContact__c> recordListToBeUpdated = new List<AccountContact__c>();
		// list of changed DB records to be Updated

		for(AccountContact__c currentRecordFromTriggerNew : newRecordList){
			for(AccountContact__c currentRecordFromTriggerOld : oldRecordList){
				// Here we check if isPrimary__c status was changed in Trigger.new
				if(currentRecordFromTriggerOld.isPrimary__c != currentRecordFromTriggerNew.isPrimary__c
				&& currentRecordFromTriggerOld.Id == currentRecordFromTriggerNew.Id){

					/* 	Loop below forms list of non-updated records from BD
						with Contact__c equal to Contact__c in updated one */
					for(AccountContact__c currentRecordFromDB : accountContactListFromDB){
						if(currentRecordFromTriggerNew.Contact__c == currentRecordFromDB.Contact__c
						&& currentRecordFromTriggerNew.Id != currentRecordFromDB.Id){
							recordListForParticularContactFromDB.add(currentRecordFromDB);
						}
					}
					if(!currentRecordFromTriggerNew.isPrimary__c){
						/* 	Conditions below determine the isPrimary field behavior
                       		when isPrimary in Updated record is changed to 'false'.
                        	If record is only one for particular Contact__c - isPrimary has to be true.
                        	If there are records in DB for particular Contact__c -
                        	isPrimary will be true for the last one by CreationDate. */
						if(recordListForParticularContactFromDB.size()==0){
							currentRecordFromTriggerNew.addError('The only workplace is always Primary.');
						} else if(recordListForParticularContactFromDB.size()>1){
							Integer indexForRecordWithLatestCreatedDate = 0;	// will be used in loop below
							for(Integer i=0; i<recordListForParticularContactFromDB.size(); i++){
								if(recordListForParticularContactFromDB.get(i).CreatedDate > recordListForParticularContactFromDB.get(indexForRecordWithLatestCreatedDate).CreatedDate){
									indexForRecordWithLatestCreatedDate = i;
								}
							}
							recordListForParticularContactFromDB.get(indexForRecordWithLatestCreatedDate).isPrimary__c = true;
							recordListToBeUpdated.add(recordListForParticularContactFromDB.get(indexForRecordWithLatestCreatedDate));
						} else if(recordListForParticularContactFromDB.size() == 1){
							recordListForParticularContactFromDB.get(0).isPrimary__c = true;
							recordListToBeUpdated.add(recordListForParticularContactFromDB.get(0));
						}
					}
					if(currentRecordFromTriggerNew.isPrimary__c){
						/* 	Conditions below determine the isPrimary field behavior
                       		when isPrimary in Updated record is changed to 'true'.
                        	isPrimary fields in all records with same particular Contact__c
                        	have to change to 'false'. */
						for(AccountContact__c currentRecordToBeChanged : recordListForParticularContactFromDB){
							currentRecordToBeChanged.isPrimary__c = false;
							recordListToBeUpdated.add(currentRecordToBeChanged);
						}
					}


				}
				recordListForParticularContactFromDB.clear();
			}
		//TODO:? unique AccountContact__c records with equal Contact__c.
		}
		if(recordListToBeUpdated.size()>0){
			update recordListToBeUpdated;
		}
	}
	public static void beforeDelete(List<AccountContact__c> deletedRecordList){
		Set<Id> uniqueContactSetFromTrigger = new Set<Id>();
		for(AccountContact__c currentRecordToAddInSet : deletedRecordList){
			uniqueContactSetFromTrigger.add(currentRecordToAddInSet.Contact__c);
		}
		List<AccountContact__c> accountContactListFromDB = [	// has to form list of AccountContact records
				SELECT 	Name,									// with Contacts same as the ones to be restored
						isPrimary__c,
						Account__c,
						Contact__c,
						CreatedDate
				FROM 	AccountContact__c
				WHERE 	Contact__c IN : uniqueContactSetFromTrigger];

		List<AccountContact__c> recordListForParticularContactFromDB = new List<AccountContact__c>();

		List<AccountContact__c> recordListToUpdate = new List<AccountContact__c>();
		/*	Conditions below determine that
			if the deleted record was the only one
			for particular Contact__c - nothing changes.
			If there are existing contacts in DB for Contact__c
			isPrimary->true for the last one by CreationDate. */
		for(AccountContact__c currentDeletedRecord : deletedRecordList){
			for(AccountContact__c currentRecordFromDB : accountContactListFromDB){
				if(currentDeletedRecord.Contact__c == currentRecordFromDB.Contact__c
				&& currentDeletedRecord.Id != currentRecordFromDB.Id
				&& currentDeletedRecord.isPrimary__c){
					recordListForParticularContactFromDB.add(currentRecordFromDB);
				}
			}
			if(recordListForParticularContactFromDB.size()>0){
				Integer indexForRecordWithLastCreatedDate = 0;
				for(Integer i=0; i<recordListForParticularContactFromDB.size(); i++){
					if(recordListForParticularContactFromDB.get(i).CreatedDate > recordListForParticularContactFromDB.get(indexForRecordWithLastCreatedDate).CreatedDate){
						indexForRecordWithLastCreatedDate = i;
					}
				}
				recordListForParticularContactFromDB.get(indexForRecordWithLastCreatedDate).isPrimary__c = true;
				// Statement below doesn`t wanna work because of Read-only for some reason
				// currentDeletedRecord.isPrimary__c = false;	// because in Undelete it will be ReadOnly
				recordListToUpdate.add(recordListForParticularContactFromDB.get(indexForRecordWithLastCreatedDate));
			}
		}
		if(recordListToUpdate.size()>0){
			update recordListToUpdate;
		}
	}
	public static void afterUndelete(List<AccountContact__c> restoredRecordList){
		Set<Id> uniqueContactSetFromTrigger = new Set<Id>();
		for(AccountContact__c currentRecordToAddInSet : restoredRecordList){
			uniqueContactSetFromTrigger.add(currentRecordToAddInSet.Contact__c);
		}
		List<AccountContact__c> accountContactListFromDB = [	// has to form list of AccountContact records
				SELECT 	Name,									// with Contacts same as the ones to be restored
						isPrimary__c,
						Account__c,
						Contact__c,
						CreatedDate
				FROM 	AccountContact__c
				WHERE 	Contact__c IN : uniqueContactSetFromTrigger];

		List<AccountContact__c> recordListForParticularContact = new List<AccountContact__c>();
		// List below contains records to be updated after restoration
		List<AccountContact__c> recordListToBeUpdated = new List<AccountContact__c>();
		/*	Condition below determines that
			if restored record will be the only one -?????? */
		for(AccountContact__c currentRecordFromTrigger : restoredRecordList){
			for(AccountContact__c currentRecordFromDB : accountContactListFromDB){
				if(currentRecordFromDB.Contact__c == currentRecordFromTrigger.Contact__c){
					recordListForParticularContact.add(currentRecordFromDB);
				}
			}
			if(recordListForParticularContact.size()>0){		// It will mean that there already is record in DB
				continue;										// which has isPrimary = true
			} else if(recordListForParticularContact.size()==0) {
				//currentRecordFromTrigger.isPrimary__c = false;  ------ can`t change because of Read-only in Undelete
			}
			recordListToBeUpdated.add(currentRecordFromTrigger);
			recordListForParticularContact.clear();
		}
		if(recordListToBeUpdated.size()>0){
			update recordListToBeUpdated;
		}
	}
}