trigger TransactionEntryTrigger on Transaction_Entry__c (before insert, before update) {
    if (Trigger.isBefore){
        if(Trigger.isUpdate || Trigger.isInsert){
            TransactionEntryTriggerHandler.updateContact(Trigger.New);
        }
    }
}