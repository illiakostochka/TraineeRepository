trigger AccountContactTrigger on AccountContact__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    if(Trigger.isInsert){
        if(Trigger.isBefore && !CheckRecursive.firstTriggerCall){
            CheckRecursive.firstTriggerCall = true;
            TriggerHandler.beforeInsert(Trigger.new);
        } else if(Trigger.isAfter){ }
    } else if(Trigger.isUpdate){
        if(Trigger.isBefore && !CheckRecursive.firstTriggerCall){
            CheckRecursive.firstTriggerCall = true;
            TriggerHandler.beforeUpdate(Trigger.new, Trigger.old);
        } else if(Trigger.isAfter){

        }
    } else if(Trigger.isDelete){
        if(Trigger.isBefore){
            TriggerHandler.beforeDelete(Trigger.old);
        } else if(Trigger.isAfter){

        }
    } else if(Trigger.isUndelete){
        if(Trigger.isAfter){
            TriggerHandler.afterUndelete(Trigger.new);
        }
    }
}
// some comment to change file