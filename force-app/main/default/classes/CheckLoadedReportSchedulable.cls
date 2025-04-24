/* -----------------------------------------------------------------------------------------------------------------------
   Name:        CheckLoadedReportSchedulable.cls
   Description: Schedulable class to check records created today in the Dispatch_Staging__c object and send notifications.
   
   Date         Version Author    Summary of Changes
   -----------  ------- --------- ------------------------------------------------------------------------------
   Sep 2024     1.0     Globant   Initial Release
----------------------------------------------------------------------------------------------------------------------- */

public class CheckLoadedReportSchedulable implements Schedulable {

    /**
     * Executes the scheduled job to check for records created today in the Dispatch_Staging__c object 
     * and send notification emails.
     * 
     * @param ctx SchedulableContext - Represents the context in which the job is scheduled.
     */
    public void execute(SchedulableContext ctx) {
        List<Dispatch_Staging__c> loadDispatchStaging = [
            SELECT Id
            FROM Dispatch_Staging__c
            WHERE CreatedDate = TODAY
        ];
     
        SendNotificationEmail.sendEmailsToUsers(loadDispatchStaging); 
    }
}

// TODO remove once it has been tested/validated/QA-ed
/*public class CheckLoadedReportSchedulable implements Schedulable{

    public void execute (SchedulableContext ctx) {
        
        List<Dispatch_Staging__c> loadDispatchStaging = [
            SELECT id
            FROM Dispatch_Staging__c
            WHERE CreatedDate = TODAY
        ];
     
        SendNotificationEmail.sendEmailsToUsers(loadDispatchStaging); 
             
    }
 
}*/