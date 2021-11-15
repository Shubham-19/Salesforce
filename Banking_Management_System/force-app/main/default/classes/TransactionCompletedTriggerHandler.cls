public with sharing class TransactionCompletedTriggerHandler {
    public static void TransactionCompletedTriggerHandlerMethod(List<Transaction_Entry__c> newEntries) {
        //set<Id> setOfIds= new set<Id>();
        Id txId;
        if(newEntries !=null ){
            for(Transaction_Entry__c tx:newEntries){
                if(tx.Contact__c!=null){
                    txId = tx.Contact__c;
                    //txId.add(tx.Contact__c);
                }
            }    
        }
       
        //get all email in the list
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Contact>listOfContact = [SELECT Id, Email,LastName, Available_Balance__c
                                      FROM Contact
                                      WHERE Id = :txId];
        map<Id, List<string> > mapOfIds = new map<Id, List<string>>();
        for (Contact tx : listOfContact) {
            List<String> listOfString = new List<String>();
            System.debug('tx.Email'+ tx.Email);
            System.debug('tx.LastName'+ tx.LastName);
            //System.debug('tx.Status__c'+ tx.Status__c);
            if (tx.Email != null && tx.LastName != null) {
                listOfString.add(string.valueof(tx.Available_Balance__c));
                listOfString.add(tx.Email);
                mapOfIds.put(tx.Id,listOfString);
               
            }
        }
        System.debug('mapOfIds.put: '+mapOfIds);
        
        List<Transaction_Entry__c>listOfTx = [SELECT Id, Status__c, Contact__c, Type__c, Amount__c, CreatedDate FROM Transaction_Entry__c WHERE Id IN :newEntries];
        System.debug('listOfTx: '+listOfTx);
        for(Transaction_Entry__c te : listOfTx){
            if (te.Status__c == 'Completed'){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
               
               
                // Step 2: Set list of people who should get the email
                List<String> sendTo = new List<String>();
                sendTo.add(mapOfIds.get(te.Contact__c)[1]);
                mail.setToAddresses(sendTo);
               
               
                // Step 3. Set email contents - you can use variables!
                mail.setSubject('Your contact detail are added'); //Subject of the mail and the body of the mail
                String body = 'Your A/c ' + te.Id + ' is ' + te.Type__c + ' by Rs. '+ te.Amount__c + ' on ' + te.CreatedDate + ' .Available Bal: Rs. '+ mapOfIds.get(te.Contact__c)[0] + '.';
                mail.setHtmlBody(body);
         
               
                // Step 4. Add your email to the master list
                mails.add(mail);
               
            }
        }
        // Step 5: Send all emails in the master list
        System.debug(mails);

        //Messaging.sendEmail(mails);
    }
}