trigger TestApexTrigger on Invoice__c (before insert) {
// this trigger should be retrieved by Illuminated Cloud
    Integer someVariable;
    // this trigger should be pushed to branch "feature_1" in github
}