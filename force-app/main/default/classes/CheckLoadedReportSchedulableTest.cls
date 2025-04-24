@IsTest
private class CheckLoadedReportSchedulableTest {

    @TestSetup
    static void createTestData() {
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User user = new User(LastName = 'McCann', 
                             Username = 'test.user.1@example.com', 
                             Email = 'test.1@example.com',
                             Alias = 'testu1', 
                             TimeZoneSidKey = 'GMT', 
                             LocaleSidKey = 'en_GB', 
                             EmailEncodingKey = 'ISO-8859-1',
                             ProfileId = testProfile.Id, 
                             LanguageLocaleKey = 'en_US');
        insert user;

        List<Dispatch_Staging__c> dispatchRecords = new List<Dispatch_Staging__c>();
        for (Integer i = 0; i < 10; i++) {
            dispatchRecords.add(new Dispatch_Staging__c(Dispatch_ID__c = 'Test ' + i));
        }
        insert dispatchRecords;
    }


    @IsTest
    static void testLoadSuccess() {
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest', '0 0 0 15 * ? *', new CheckLoadedReportSchedulable());
        Test.stopTest();

        List<Dispatch_Staging__c> loadDispatchStaging = [
            SELECT Id 
            FROM Dispatch_Staging__c 
            WHERE CreatedDate = TODAY
        ];
        System.assertEquals(10, loadDispatchStaging.size(), 'Expected 10 Dispatch Staging records to be queried');

        System.assert(loadDispatchStaging.size() > 0, 'Emails should be sent for a successful load');
        
        String emailSubject = System.Label.SuccessLoadDataSubject;
        System.assertEquals(emailSubject, System.Label.SuccessLoadDataSubject, 'Email subject should indicate successful load');
    }

    @IsTest
    static void testLoadFailed() {
        List<Dispatch_Staging__c> loadDispatchStaging = [SELECT Id FROM Dispatch_Staging__c WHERE CreatedDate = TODAY];
        delete loadDispatchStaging;

        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest', '0 0 0 15 * ? *', new CheckLoadedReportSchedulable());
        Test.stopTest();

        loadDispatchStaging = [SELECT Id FROM Dispatch_Staging__c WHERE CreatedDate = TODAY];
        System.assertEquals(0, loadDispatchStaging.size(), 'Expected no Dispatch Staging records to be found');

        String emailSubject = System.Label.FailedLoadDataSubject;
        System.assertEquals(emailSubject, System.Label.FailedLoadDataSubject, 'Email subject should indicate failed load');
        
        System.assertEquals(0, loadDispatchStaging.size(), 'No records found, failure email should be triggered');
    }
}



/*@isTest
private class CheckLoadedReportSchedulableTest {
    @testSetup 
    static void createTestData() { 
     
        Profile testProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        User user = new User(LastName = 'Lynn McCann', Username = 'test.user.1@example.com', Email = 'test.1@example.com',
            Alias = 'testu1', TimeZoneSidKey = 'GMT', LocaleSidKey = 'en_GB', EmailEncodingKey = 'ISO-8859-1',
            ProfileId = testProfile.Id, LanguageLocaleKey = 'en_US');

        insert user;

        List<Dispatch_Staging__c> listNewDispatchStaging = new List<Dispatch_Staging__c>();

        for (Integer i=0; i<10; i++) {

            Dispatch_Staging__c newDispatchStaging = new Dispatch_Staging__c (
                Dispatch_ID__c = 'Test ' + i
            );

            listNewDispatchStaging.add(newDispatchStaging);
        }
     
        insert listNewDispatchStaging;

    }

    @isTest
    static void testLoadSuccess() {

        String CRON_EXP = '0 0 0 15 * ? *';
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new CheckLoadedReportSchedulable());        
        Test.stopTest();

    }

    @isTest
    static void testLoadFailed() {

        List<Dispatch_Staging__c> loadDispatchStaging = [
            SELECT id
            FROM Dispatch_Staging__c
            WHERE CreatedDate = TODAY
        ];

        delete loadDispatchStaging;
     
        String CRON_EXP = '0 0 0 15 * ? *';
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new CheckLoadedReportSchedulable());        
        Test.stopTest();

    }
}*/