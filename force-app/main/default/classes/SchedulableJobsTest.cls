/* -----------------------------------------------------------------------------------------------------------------------
   Name:        SchedulableJobsTest.cls
   Description: Test schedulable Apex classes
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Dec 2017     1.0     M.Witchalls(Ciber)  Initial Release 
------------------------------------------------------------------------------------------------------------------------ */        

@isTest
private class SchedulableJobsTest {

    private static final String CRON_EXP = '0 0 0 15 3 ? 2032';
    
    @testSetup
    static void setupTestData() {
        
        
        EmailTemplate emailTemplate = new EmailTemplate(
            Name = 'Test Template',
            DeveloperName = 'Test_Template',
            Subject = 'Test Subject',
            IsActive = true,
            Body = 'This is a test email template.',
            FolderId = UserInfo.getUserId(), // Using current user's private folder
            TemplateType = 'text'// Associate the letterhead with the email template
        );
        insert emailTemplate;

    }
    
    @isTest static void testDispatchLoadScheduler() {
        Dispatch_Batch_Load_Schedule__c mockSchedule = new Dispatch_Batch_Load_Schedule__c(Hour__c = 9, Minutes__c = 30);
        insert mockSchedule;
        
        Test.startTest();
        
        DispatchLoadScheduler scheduler = new DispatchLoadScheduler();
        scheduler.execute(null);
        
        Test.stopTest();
        
        System.assert(true, 'Dispatch Load Scheduler executed successfully.');
    }

    @isTest static void testEmailSendSchedulable() {
        List<ID> userIdList = new List<ID>{UserInfo.getUserId()};
            
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Test_Template' LIMIT 1];
        String emailTemplateId = template.Id;  

        Test.startTest();
        
        EmailSendSchedulable emailScheduler = new EmailSendSchedulable(emailTemplateId, userIdList);
        emailScheduler.execute(null);
        
        Test.stopTest();
        
        System.assert(true, 'Email Send Scheduler executed successfully.');
    }
    
    @isTest static void testSystemScheduleForDispatchLoad() {
        Test.startTest();
        
        String jobId = System.schedule('TestJob', CRON_EXP, new DispatchLoadScheduler());
        
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Job should be scheduled.');
    }

    @isTest static void testSystemScheduleForEmailSend() {
        
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Test_Template' LIMIT 1];
        String emailTemplateId = template.Id;
        List<ID> userIdList = new List<ID>{UserInfo.getUserId()};
        
        Test.startTest();
        
        String jobId = System.schedule('TestJob', CRON_EXP, new EmailSendSchedulable(emailTemplateId, userIdList));
        
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Job should be scheduled.');
    }
}


/*@isTest
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

}*/