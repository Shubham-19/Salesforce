trigger ContactTrigger on Contact (before delete) {
    if(Trigger.isBefore){
        if(Trigger.isDelete){
            ContactTriggerHandler.contactDelete(Trigger.old);
        }
    }
}