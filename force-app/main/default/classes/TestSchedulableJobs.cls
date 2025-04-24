/* -----------------------------------------------------------------------------------------------------------------------
   Name:        TestSchedulableJobs.cls
   Description: Test schedulable Apex classes
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Dec 2017     1.0     M.Witchalls(Ciber)  Initial Release 
------------------------------------------------------------------------------------------------------------------------ */        
@isTest
private class TestSchedulableJobs {
 
    // CRON expression: midnight on March 15 2022.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    private static String CRON_EXP = '0 0 0 15 3 ? 2032';
 
    @isTest static void testDispatchLoad() {
        
        Test.startTest();
 
        // Schedule the test job
        String jobId = System.schedule(
            'ScheduleDispatchLoadTest',
            CRON_EXP,
            new DispatchLoadScheduler()
        );
          
        // Get the information from the CronTrigger API object
        CronTrigger ct = [
            SELECT 
                Id, CronExpression, TimesTriggered, NextFireTime
            FROM 
                CronTrigger 
            WHERE id = :jobId
        ];
 
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);
        
        Test.stopTest();
 
        // The scheduled job will execute after Test.stopTest(), 
    }
 
    @isTest static void testEmailSend() {
        
        ID emailTemplateId = null;
        List<ID> userIdList = new List<ID>{UserInfo.getUserId()};
        
        Test.startTest();
 
        // Schedule the test job
        String jobId = System.schedule(
            'ScheduleEmailSendTest',
            CRON_EXP,
            new EmailSendSchedulable(emailTemplateId, userIdLIst)
        );
        
        Test.stopTest();
 
        // The scheduled job will execute after Test.stopTest(), 
    }

}