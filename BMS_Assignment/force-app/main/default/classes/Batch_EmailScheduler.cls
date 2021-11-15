global class Batch_EmailScheduler implements Database.Batchable<sObject>, Database.Stateful{
   global List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Starting.......');
        Date dateToday = Date.today();
        System.debug('Today\'s Date: ' + dateToday);
        Date firstDateOfTheMonth = dateToday.toStartofMonth();
        System.debug('First Date of the Month: ' + firstDateOfTheMonth);
        Date lastDateOfTheMonth = dateToday.addMonths(1).toStartofMonth().addDays(-1);
        System.debug('Last Date of the Month: ' + lastDateOfTheMonth);
        List<ID>ids = new list<Id>{'0035j000004jaQ5AAI'};
        return Database.getQueryLocator('SELECT Id, Status__c, Available_Balance__c, Email, Account_Number__c,(SELECT Transaction_Date__c, Amount__c, Type__c FROM Transaction_Entries__r WHERE Transaction_Date__c >= :firstDateOfTheMonth AND Transaction_Date__c <= :lastDateOfTheMonth ) FROM Contact WHERE Email != null AND Id IN :ids');
        
    }
    global void execute(Database.BatchableContext bc, List<Contact> listOfContacts){
        // Getting transactions for the present month for each contact
        for(Contact con : listOfContacts){
            System.debug('Checking Contact: ' + con);
            if(con.Status__c == 'Active'){
                System.debug('The status is Active');              
             
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();      
                
                // Set list of people who should get the email
                List<String> sendTo = new List<String>();
                
                sendTo.add(String.valueOf(con.Email));
                System.debug(sendTo);
                mail.setToAddresses(sendTo);
                System.debug(mail.toAddresses);
                // Set subject
                mail.setSubject('Account Statement for this Month'); //Subject of the mail and the body of the mail
                
                // Set the body of the email
                String body = 'Your Available Balance is '+con.Available_Balance__c +
                    '<tr>' +
                    '<th style="border: 1px solid black;">Account Name</th>' +
                    '<th style="border: 1px solid black;">Amount</th>' +
                    '<th style="border: 1px solid black;">Type</th>' +
                    '<th style="border: 1px solid black;">Transaction Date</th>' +
                    '</tr>';
                
                for(Transaction_Entry__c tx : con.Transaction_Entries__r){
                    body += '<tr>' + 
                        '<td style="border: 1px solid black;">' + con.Account_Number__c + '</td>' +
                        '<td style="border: 1px solid black;">' + tx.Amount__c + '</td>' +
                        '<td style="border: 1px solid black;">' + tx.Type__c + '</td>' +
                        '<td style="border: 1px solid black;">' + tx.Transaction_Date__c + '</td>' +
                        '</tr>';      
                    System.debug('E-mail Body: ' + body);
                    mail.setHtmlBody(body);
                    
                    // Add your email to the master list
                    
                }
                mails.add(mail);
            }    
        }
    }  
    global void finish(Database.BatchableContext bc){
        //Send all emails in the master list
        System.debug(mails);
        try{
            //Messaging.sendEmail(mails);
        }
        catch(Exception error){
            System.debug(error);
        }
    }
}