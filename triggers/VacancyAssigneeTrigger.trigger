trigger VacancyAssigneeTrigger on Vacancy__c (after insert, after update) {
    if (Trigger.isInsert) {
        if (Trigger.isAfter) {
            VacancyHandler.afterInsert(Trigger.newMap);
        }
    }
    if (Trigger.isUpdate) {
        if (Trigger.isAfter) {
            VacancyHandler.afterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }
}