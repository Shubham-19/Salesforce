public class TransactionEntryTriggerHandler {
    public static void updateContact(List<Transaction_Entry__c> newEntries){
        List<Contact> contactsToUpdate = new List<Contact>();
        Map<Id, Decimal> contactAndAmount = new Map<Id, Decimal>();
        Map<Id, Transaction_Entry__c> contactAndTx = new Map<Id, Transaction_Entry__c>();

        Map<Id, List<Decimal>> totalTxDebitMap = new Map<Id, List<Decimal>>();
        Map<Id, List<Decimal>> totalTxCreditMap = new Map<Id, List<Decimal>>();
        Map<Id, Integer> totalTransactions = new Map<Id, Integer>();

        Map<Id, List<Decimal>> monthlyTxCreditMap = new Map<Id, List<Decimal>>();
        Map<Id, List<Decimal>> monthlyTxDebitMap = new Map<Id, List<Decimal>>();
        Map<Id, Integer> totalMonthlyTransactions = new Map<Id, Integer>();

        Map<Id, List<Decimal>> dailyTxCreditMap = new Map<Id, List<Decimal>>();
        Map<Id, List<Decimal>> dailyTxDebitMap = new Map<Id, List<Decimal>>();
        Map<Id, Integer> totalDailyTransactions = new Map<Id, Integer>();
        //Map<Id, Decimal> totalTransactionsOnContact = new Map<Id, Decimal>();
       
/*
        Integer totalTransactions = 0;
        Decimal totalDebitTransactions = 0;
        Integer totalMonthlyTransactions = 0;
        Decimal totalMonthlyDebitAmount = 0;
        Integer totalTransactionsToday = 0;
        Decimal totalDailyDebitAmount = 0;
*/

        List<String>listOfErrors = new List<String>{'Your debit limit per transaction is ', 'Transaction Limit Reached'};
        
        for(Transaction_Entry__c tx : newEntries){
            contactAndTx.put(tx.Contact__c, tx);
        }

        

        AggregateResult[] totalTransactionsOnContact = [ SELECT COUNT(Name) total, SUM(Amount__c) totalAmount, Contact__c contactId, Type__c type
                                                             FROM Transaction_Entry__c
                                                             WHERE Contact__c IN :contactAndTx.keySet() 
                                                             GROUP BY Contact__c, Type__c
                                                        ];

        if(totalTransactionsOnContact.size() > 0){
            for(AggregateResult ar : totalTransactionsOnContact){
                List<Decimal> tempList = new List<Decimal>();
                tempList.add((Decimal)ar.get('total'));
                tempList.add((Decimal)ar.get('totalAmount'));
                if((String)ar.get('type') == 'Debit'){
                    totalTxDebitMap.put((Id)ar.get('contactId'), tempList);
                }else{
                    totalTxCreditMap.put((Id)ar.get('contactId'), tempList);
                }
            }

            

            Integer currentMonth = Date.today().month();

            

            AggregateResult[] monthlyResults = [ SELECT COUNT(Name) numTxMonthly,  SUM(Amount__c) totalDebitMonthly, CALENDAR_MONTH(Transaction_Date__c), Contact__c contactId, Type__c type
                                                FROM Transaction_Entry__c
                                                WHERE Contact__c IN :contactAndTx.keySet() AND CALENDAR_MONTH(Transaction_Date__c) = :currentMonth
                                                GROUP BY Contact__c, CALENDAR_MONTH(Transaction_Date__c), Type__c];

            if(monthlyResults.size() > 0){
                for(AggregateResult ar : monthlyResults){
                    List<Decimal> tempList = new List<Decimal>();
                    tempList.add((Decimal)ar.get('numTxMonthly'));
                    tempList.add((Decimal)ar.get('totalDebitMonthly'));
                    if((String)ar.get('type') == 'Debit'){
                        monthlyTxDebitMap.put((Id)ar.get('contactId'), tempList);
                    }else{
                        monthlyTxCreditMap.put((Id)ar.get('contactId'), tempList);
                    }
                }

                

                Date todayDate = Date.today();

                AggregateResult[] dailyResults = [ SELECT COUNT(Name) numTxDaily,  SUM(Amount__c) totalDebitDaily, DAY_IN_YEAR(Transaction_Date__c), Contact__c contactId, Type__c type
                                                    FROM Transaction_Entry__c
                                                    WHERE Contact__c IN :contactAndTx.keySet() AND Transaction_Date__c = :todayDate
                                                    GROUP BY Contact__c, DAY_IN_YEAR(Transaction_Date__c), Type__c];

                if(dailyResults.size() > 0){
                    for(AggregateResult ar : dailyResults){
                        List<Decimal> tempList = new List<Decimal>();
                        tempList.add((Decimal)ar.get('numTxDaily'));
                        tempList.add((Decimal)ar.get('totalDebitDaily'));
                        if((String)ar.get('type') == 'Debit'){
                            dailyTxDebitMap.put((Id)ar.get('contactId'), tempList);
                        }else{
                            dailyTxCreditMap.put((Id)ar.get('contactId'), tempList);
                        }
                    }

                    
                }
            }
        }

        for(Id conId : contactAndTx.keySet()){
            System.debug('');
            if(totalTxCreditMap.isEmpty() || totalTxDebitMap.isEmpty()){
                if(totalTxCreditMap.isEmpty()){
                    if(totalTxDebitMap.keySet().contains(conId)){
                        totalTransactions.put(conId, (Integer)totalTxDebitMap.get(conId)[0]);
                    }
                    else{
                        totalTxDebitMap.put(conId, new List<Decimal>{0, 0});
                        totalTransactions.put(conId, 0);
                    }
                }
                else if(totalTxDebitMap.isEmpty()){
                    if(totalTxCreditMap.keySet().contains(conId)){
                        totalTransactions.put(conId, (Integer)totalTxCreditMap.get(conId)[0]);
                    }
                    else{
                        totalTxCreditMap.put(conId, new List<Decimal>{0, 0});
                        totalTransactions.put(conId, 0);
                    }
                    totalTxDebitMap.put(conId, new List<Decimal>{0, 0});
                }
            }
            else{
                if(totalTxCreditMap.keySet().contains(conId) && totalTxDebitMap.keySet().contains(conId)){
                    totalTransactions.put(conId, (Integer)(totalTxCreditMap.get(conId)[0] + totalTxDebitMap.get(conId)[0]));
                }
                else{
                    totalTxDebitMap.put(conId, new List<Decimal>{0, 0});
                    totalTxCreditMap.put(conId, new List<Decimal>{0, 0});
                    totalTransactions.put(conId, 0);
                }
            }
        }

        for(Id conId : contactAndTx.keySet()){
            if(monthlyTxCreditMap.isEmpty() || monthlyTxDebitMap.isEmpty()){
                if(monthlyTxCreditMap.isEmpty()){
                    if(monthlyTxDebitMap.keySet().contains(conId)){
                        totalMonthlyTransactions.put(conId, (Integer)monthlyTxDebitMap.get(conId)[0]);
                    }
                    else{
                        monthlyTxDebitMap.put(conId, new List<Decimal>{0, 0});
                        totalMonthlyTransactions.put(conId, 0);
                    }
                }
                else if(monthlyTxDebitMap.isEmpty()){
                    if(monthlyTxCreditMap.keySet().contains(conId)){
                        totalMonthlyTransactions.put(conId, (Integer)monthlyTxCreditMap.get(conId)[0]);
                    }
                    else{
                        monthlyTxCreditMap.put(conId, new List<Decimal>{0, 0});
                        totalMonthlyTransactions.put(conId, 0);
                    }
                
                    monthlyTxDebitMap.put(conId, new List<Decimal>{0, 0});
                }
            }
            else{
                if(monthlyTxCreditMap.keySet().contains(conId) && monthlyTxDebitMap.keySet().contains(conId)){
                    totalMonthlyTransactions.put(conId, (Integer)(monthlyTxCreditMap.get(conId)[0] + monthlyTxDebitMap.get(conId)[0]));
                }
                else{
                    monthlyTxDebitMap.put(conId, new List<Decimal>{0, 0});
                    monthlyTxCreditMap.put(conId, new List<Decimal>{0, 0});
                    totalMonthlyTransactions.put(conId, 0);
                }
            }
        }

        for(Id conId : contactAndTx.keySet()){
            if(dailyTxCreditMap.isEmpty() || dailyTxDebitMap.isEmpty()){
                if(dailyTxCreditMap.isEmpty()){
                    if(dailyTxDebitMap.keySet().contains(conId)){
                        totalDailyTransactions.put(conId, (Integer)dailyTxDebitMap.get(conId)[0]);
                    }
                    else{
                        dailyTxDebitMap.put(conId, new List<Decimal>{0, 0});
                        totalDailyTransactions.put(conId, 0);
                    }
                }
                else if(dailyTxDebitMap.isEmpty()){
                    if(dailyTxCreditMap.keySet().contains(conId)){
                        totalDailyTransactions.put(conId, (Integer)dailyTxCreditMap.get(conId)[0]);
                    }
                    else{
                        dailyTxCreditMap.put(conId, new List<Decimal>{0, 0});
                        totalDailyTransactions.put(conId, 0);
                    }
                
                    dailyTxDebitMap.put(conId, new List<Decimal>{0, 0});
                }
            }
            else{
                if(dailyTxCreditMap.keySet().contains(conId) && dailyTxDebitMap.keySet().contains(conId)){
                    totalDailyTransactions.put(conId, (Integer)(dailyTxCreditMap.get(conId)[0] + dailyTxDebitMap.get(conId)[0]));
                }
                else{
                    dailyTxCreditMap.put(conId, new List<Decimal>{0, 0});
                    totalDailyTransactions.put(conId, 0);
                }
            }
        }


        Map<Id, Id> limitAndContact = new Map<Id, Id>();
        for(Contact con : [SELECT Id, Transaction_Limit__c FROM Contact WHERE Id = :contactAndTx.keySet()]){
            limitAndContact.put(con.Transaction_Limit__c, con.Id);
        }
        
        Map<Transaction_Entry__c, Transaction_Limit__c> txAndLimit = new Map<Transaction_Entry__c, Transaction_Limit__c>();
        for(Transaction_Limit__c tl : [SELECT Id, Maximum_Debit_per_Transaction__c, Maximum_Transactions_Allowed_per_Day__c, Maximum_Debit_Allowed_per_Day__c, Maximum_Transactions_Allowed_per_Month__c, Maximum_Debit_Allowed_per_Month__c FROM Transaction_Limit__c WHERE Id IN :limitAndContact.keySet()]){
            txAndLimit.put(contactAndTx.get(limitAndContact.get(tl.Id)), tl);
        }
        
        System.debug('totalTxDebitMap: ' + totalTxDebitMap);
        System.debug('totalTxCreditMap: ' + totalTxCreditMap);
        System.debug('totalTransactions: ' + totalTransactions);
        System.debug('monthlyTxCreditMap: ' + monthlyTxCreditMap);
        System.debug('monthlyTxDebitMap: ' + monthlyTxDebitMap);
        System.debug('totalMonthlyTransactions: ' + totalMonthlyTransactions);
        System.debug('dailyTxCreditMap: ' + dailyTxCreditMap);
        System.debug('dailyTxDebitMap: ' + dailyTxDebitMap);
        System.debug('totalDailyTransactions: ' + totalDailyTransactions);

        for(Transaction_Entry__c entry : newEntries){
            if(withinLimitations(entry, txAndLimit, totalTxDebitMap, totalTxCreditMap, totalTransactions, monthlyTxCreditMap, monthlyTxDebitMap, totalMonthlyTransactions, dailyTxCreditMap, dailyTxDebitMap, totalDailyTransactions)){
                System.debug('New Entry...');
                Decimal temp = 0;
                contactAndTx.put(entry.Contact__c, entry);
               
                if(entry.Type__c == 'Credit' && entry.Status__c == 'Pending'){
                    System.debug('Credit Successful');
                    temp += entry.Amount__c;
                }
               
                if(entry.Type__c == 'Debit' && entry.Status__c == 'Pending'){
                    System.debug('Debit Successful');
                    temp -= entry.Amount__c;
                }
               
                if(entry.Status__c == 'Cancelled'){
                    if(entry.Type__c == 'Debit'){
                        temp += entry.Amount__c;
                    }
                    else{
                        temp -= entry.Amount__c;
                    }
                }
               
                contactAndAmount.put(entry.Contact__c, temp);
            }
           
        }
       
        if(contactAndAmount.keySet().size() > 0){
            for(Contact con : [SELECT Available_Balance__c, Id FROM Contact WHERE Id IN :contactAndAmount.keySet() AND Status__c = 'Active']){
                System.debug('Contact to be updated: ' + con);
                System.debug('Amount to be added: ' + contactAndAmount.get(con.Id));
               
                if(contactAndAmount.get(con.Id) < 0 && con.Available_Balance__c >= 3000){
                    if(con.Available_Balance__c < (-1*contactAndAmount.get(con.Id))){
                        contactAndTx.get(con.Id).addError('Amount to be debited is more than the available balance');
                    }else{
                        con.Available_Balance__c += contactAndAmount.get(con.Id);
                    }
                }else if(contactAndAmount.get(con.Id) > 0){
                    con.Available_Balance__c += contactAndAmount.get(con.Id);
                }else{
                    contactAndTx.get(con.Id).addError('The min. balance required is not sufficient to make the transaction');
                }
               
                if(contactAndTx.get(con.Id).Status__c == 'Pending'){
                    contactAndTx.get(con.Id).Status__c = 'Completed';
                }
                contactsToUpdate.add(con);
            }
           
            upsert contactsToUpdate;
        }
    }
   
    public static Boolean withinLimitations(Transaction_Entry__c newTx, Map<Transaction_Entry__c, Transaction_Limit__c> txAndLimit, Map<Id, List<Decimal>> totalTxDebitMap, Map<Id, List<Decimal>> totalTxCreditMap, Map<Id, Integer> totalTransactions, Map<Id, List<Decimal>> monthlyTxCreditMap, Map<Id, List<Decimal>> monthlyTxDebitMap, Map<Id, Integer> totalMonthlyTransactions, Map<Id, List<Decimal>> dailyTxCreditMap, Map<Id, List<Decimal>> dailyTxDebitMap, Map<Id, Integer> totalDailyTransactions){
        
        Id conId = newTx.Contact__c;
        Transaction_Limit__c tl = txAndLimit.get(newTx);
        
        Integer countLimitations = 0;
        
        if(totalTransactions.get(conId) > 0){
            if(newTx.Type__c == 'Debit'){
                if (totalTxDebitMap.get(conId)[0] > 0) {
                    if(validDebit(newTx, tl)){
                        if(totalDailyTransactions.get(conId) < tl.Maximum_Transactions_Allowed_per_Day__c){
                            if(newTx.Amount__c <= tl.Maximum_Debit_Allowed_per_Day__c - dailyTxDebitMap.get(conId)[1]){
                                if(totalMonthlyTransactions.get(conId) < tl.Maximum_Transactions_Allowed_per_Month__c){
                                    if(newTx.Amount__c <= tl.Maximum_Debit_Allowed_per_Month__c - monthlyTxDebitMap.get(conId)[1]){
                                        return true;
                                    }
                                    else{
                                        newTx.addError('Monthly Debit limit exceeded.');
                                        return false;
                                    }
                                }else{
                                    newTx.addError('Monthly Transaction limit exceeded.');
                                    return false;
                                }
                            }else{
                                newTx.addError('Daily Debit limit exceeded');
                                return false;
                            }
                        }else{
                            newTx.addError('Daily Transaction limit exceeded.');
                            return false;
                        }
                    }else {
                        return false;
                    }
                }else{
                    if(validDebit(newTx, tl)){
                        return true;
                    }else {
                        return false;
                    }
                }  
            }
            else {
                if(totalDailyTransactions.get(conId) < tl.Maximum_Transactions_Allowed_per_Day__c){
                    if(totalMonthlyTransactions.get(conId) < tl.Maximum_Transactions_Allowed_per_Month__c){
                        return true;
                    }else{
                        newTx.addError('Monthly Transaction limit exceeded.');
                        return false;
                    }
                }else{
                    newTx.addError('Daily Transaction limit exceeded.');
                    return false;
                }
            }   
        }
        else{
            if(newTx.Type__c == 'Debit'){
                if(validDebit(newTx, tl)){
                    return true;
                }else {
                    return false;
                }
            }
            else{
                return true;
            }
        }
    }

    public static Boolean validDebit(Transaction_Entry__c tx, Transaction_Limit__c tl){
        if(tx.Type__c == 'Debit' && tx.Amount__c <= tl.Maximum_Debit_per_Transaction__c){
            return true;
        }
        else if(tx.Type__c == 'Debit' && tx.Amount__c >= tl.Maximum_Debit_per_Transaction__c){
            tx.addError('Your one time debit limit is '  + tl.Maximum_Debit_per_Transaction__c + ' only.');
            return false;
        }
        return true;
    }
}