/* -----------------------------------------------------------------------------------------------------------------------
   Name:        AccountContractStatusUpdateScheduler.cls
   Description: Schedules the AccountContractStatusUpdateBatch to run at 1 AM daily.

   Date         Version Author    Summary of Changes
   -----------  ------- --------- ------------------------------------------------------------------------------
   Sep 2024     1.0     Globant   Initial Release
------------------------------------------------------------------------------------------------------------------------ */

global with sharing class AccountContractStatusUpdateScheduler implements Schedulable {
    public static String CRON_EXP = '0 0 1 1/1 * ? *';

    /**
     * Executes the scheduled batch job.
     * 
     * @param ctx SchedulableContext - Represents the context in which the job is scheduled.
     */
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new AccountContractStatusUpdateBatch(), 200);
    }

    /**
     * Starts the scheduler for the batch job.
     */
    public static void startScheduler(){
        System.schedule('AccountContractStatusUpdate' + String.valueOf(Date.today()), CRON_EXP, new AccountContractStatusUpdateScheduler());
    }
}

// TODO remove once it has been tested/validated/QA-ed
/*global with sharing class AccountContractStatusUpdateScheduler implements Schedulable {
    public static String CRON_EXP = '0 0 1 1/1 * ? *';
   
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new AccountContractStatusUpdateBatch(), 200);
    }

    public static void startScheduler(){
        System.schedule('AccountContractStatusUpdate' + String.valueOf(Date.today()) , CRON_EXP, new AccountContractStatusUpdateScheduler());
    }
}*/