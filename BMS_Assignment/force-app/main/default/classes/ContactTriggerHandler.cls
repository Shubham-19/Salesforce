public class ContactTriggerHandler {
    public static void contactDelete(List<Contact> newReq){
        System.debug('NewReq: ' + newReq);
        List<Contact> listOfcontactsToDelete = new List<Contact>();
        Id[] Ids = new List<Id>();
        for(Contact con : newReq){
            Ids.add(con.Id);
        }

        Map<Id, Integer> contactAndNumberOfTx = new Map<Id, Integer>();
        for(Contact c : [SELECT Id, (SELECT Name, Amount__c FROM Transaction_Entries__r) FROM Contact WHERE Id IN :Ids]){
            contactAndNumberOfTx.put(c.Id, c.Transaction_Entries__r.size());
        }
        System.debug('contactAndNumberOfTx: ' + contactAndNumberOfTx);
        for(Contact con : newReq){
            System.debug('Contact: ' + con);
            System.debug('contactAndNumberOfTx.get(con.Id): ' + contactAndNumberOfTx.get(con.Id));
            if(contactAndNumberOfTx.get(con.Id) > 0){
                System.debug('Contact can\'t be deleted!');
                con.addError('This Contact can\'t be deleted as there are transactions linked to it.');
            }
        }
    }
}