global class EmailScheduler implements Schedulable {
   
   // public static String sched = '0 09 04 28 10 ? 2021';
    global void execute(SchedulableContext ctx) {
       // Id batchId = Database.executeBatch(new Batch_EmailScheduler());
        Batch_EmailScheduler d1 = new Batch_EmailScheduler();
        Database.executeBatch(d1);    
    }
}