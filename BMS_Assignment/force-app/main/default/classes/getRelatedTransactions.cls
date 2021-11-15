public with sharing class getRelatedTransactions {
    
    @AuraEnabled(cacheable=true)
    public static List<Transaction_Entry__c> getTransactions(String contactId, String value) {
        System.debug('contactId and value: ' + contactId + ' ' + value);
        Integer recordLimit = Integer.valueof(value.trim());
        return [SELECT Name, Amount__c, Type__c, Status__c, Contact__c, Id
                FROM Transaction_Entry__c 
                WHERE Contact__c=:contactId
                LIMIT :recordLimit
            ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Transaction_Entry__c> getTransactionsByDate(String contactId, String date1, String date2, String searchKey, String sortBy, String sortDirection){
        System.debug('Start Date: ' + date1 + ' End Date: ' + date2);
        Date dt1 = Date.valueOf(date1);
        Date dt2 = Date.valueof(date2);
        System.debug('After conversion Start Date: ' + dt1 + ' End Date: ' + dt2);
        
        // return [SELECT Name, Amount__c, Type__c, Status__c, Contact__c, Id
        //         FROM Transaction_Entry__c
        //         WHERE Contact__c =:contactId and Transaction_Date__c >= :dt1 and Transaction_Date__c <= :dt2
        // ];

        String query = 'SELECT Name, Amount__c, Type__c, Status__c, Contact__c, Id FROM Transaction_Entry__c';
        if ( searchKey != null && searchKey != '' ) {
            String key = '%' + searchKey + '%';
            query += ' WHERE Contact__c =:contactId and Transaction_Date__c >= :dt1 and Transaction_Date__c <= :dt2 and Name LIKE :key';
        }
        if ( sortBy != null && sortDirection != null ) {
            query += ' ORDER BY ' + sortBy + ' ' + sortDirection;
        }
        System.debug('Query-------> ' + query);

        return Database.query( query );

    }

    @AuraEnabled
    public static void emailWithAttachment(String contactId, String blobPDF){
        // Mail master list
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();       
                
        // Step 2: Set list of people who should get the email
        List<String> sendTo = new List<String>();
        Contact con = [SELECT Id, Email FROM Contact WHERE Id = :contactId];
        System.debug('Contact: ' + con);
        sendTo.add(String.valueOf(con.Email));
        mail.setToAddresses(sendTo);
        System.debug(mail.toAddresses);
        
        // Step 3: Set subject
        mail.setSubject('PDF file for a Recent Transaction'); //Subject of the mail and the body of the mail

        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName('attachment.pdf');
        efa.setBody(EncodingUtil.base64Decode(blobPDF));
        // System.debug('blobPDF: ' + blobPDF);

        mail.setPlainTextBody('Please find attached the required PDF file.');
        
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});

        // Step 4. Add your email to the master list
        mails.add(mail);

        System.debug(mails);
        Messaging.sendEmail(mails);
    }
}