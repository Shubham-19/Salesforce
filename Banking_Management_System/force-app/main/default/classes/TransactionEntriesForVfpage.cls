public class TransactionEntriesForVfpage {
    public Decimal amountFrom{get;set;}
    public Decimal amountUpto{get;set;}   
    public List<Transaction_Entry__c> opp{set;get;}   

    
    public TransactionEntriesForVfpage(){
        String initiailMessage = 'Plese enter values in the fields above to see the data.';
    }
    
    public void dynamicSearch(){
        List<String> tempList = new List<String>();
        Map<String, String> mapValues = new Map<String, String>{'amountFrom'=> String.valueOf(amountFrom), 'amountUpto'=> String.valueOf(amountUpto)};
        Map<String, String> mapOperators = new Map<String, String>{'amountFrom'=> 'Amount__c >= ', 'amountUpto'=> 'Amount__c <= '};
        String remainingQuery = ' WHERE ';
        String query ='SELECT Id, Name, Amount__c, Type__c, Status__c FROM Transaction_Entry__c';
        for(String str : mapOperators.keySet()){
            if(mapValues.get(str) != null && mapValues.get(str) != '0'){
                tempList.add(mapOperators.get(str) + ':' + str);
            }
            System.debug(tempList);
        }
        remainingQuery += String.join(tempList, ' AND ');
        List<Boolean> boolList = new List<Boolean>{amountFrom != null && amountUpto != null};
        System.debug('boolList: ' + boolList);
        Boolean validEntries = true;
        if(boolList[0]){
            validEntries = (amountFrom <= amountUpto) ? true : false;
        }
        if(validEntries){
            query += remainingQuery;
            System.debug(query);
            opp=Database.query(query);
        }
        else{
            System.debug('Error with the fields');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, 'TRY AGAIN! There is something wrong with the data entered, please check and fill the entries carefully.'));
        }
    }
}