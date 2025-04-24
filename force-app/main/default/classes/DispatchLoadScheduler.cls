/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchLoadScheduler.cls
   Description: Schedule the schedulable job 
                to schedule the batch job to upsert records from the Dispatch Staging object to the Dispatch object
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Sep 2024     2.0     Globant             Code Refactoring
------------------------------------------------------------------------------------------------------------------------ */

global class DispatchLoadScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Dispatch_Batch_Load_Schedule__c cs = Dispatch_Batch_Load_Schedule__c.getInstance();
        
        DateTime now = system.now();
        String day = String.valueOf(now.day());
        String month = String.valueOf(now.month());
        String year = String.valueOf(now.year());
        String hour = (cs == null) ? '8' : String.valueOf(cs.Hour__c);
        String minute = (cs == null) ? '0' : String.valueOf(cs.Minutes__c);
    
        String strJobName = 'DispatchBatchLoad-' + year + '-' + month + '-' + day;
        
        String strSchedule = String.format('0 {0} {1} {2} {3} ? {4}', new List<String>{minute, hour, day, month, year});
        
        DispatchLoadSchedulable job = new DispatchLoadSchedulable(); 
        if (!Test.isRunningTest()){
            String jobID = system.schedule(strJobName, strSchedule, job);
        }  
    }
}

/*global class DispatchLoadScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Dispatch_Batch_Load_Schedule__c cs = Dispatch_Batch_Load_Schedule__c.getInstance();
        String day = string.valueOf(system.now().day());
        String month = string.valueOf(system.now().month());
        String year = string.valueOf(system.now().year());
        String hour = (cs == null) ? '8' : string.valueOf(cs.Hour__c);
        String minute = (cs == null) ? '0' : string.valueOf(cs.Minutes__c);
    
        String strJobName = 'DispatchBatchLoad-' + year + '-' + month + '-' + day;
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        system.debug('cron string: '+strSchedule); 
        
        DispatchLoadSchedulable job = new DispatchLoadSchedulable(); 
        if (!Test.isRunningTest()) String jobID = system.schedule(strJobName, strSchedule, job); 
    }
}*/