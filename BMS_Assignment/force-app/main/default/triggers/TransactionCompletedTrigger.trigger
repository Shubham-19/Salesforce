trigger TransactionCompletedTrigger on Transaction_Entry__c (after insert) {
    if (Trigger.isAfter){
        if(Trigger.isInsert){
            TransactionCompletedTriggerHandler.TransactionCompletedTriggerHandlerMethod(Trigger.New);
        }
    }  
}