@IsTest
public with sharing class AccountContractStatusUpdateTest {

    @TestSetup
    static void initData(){
        TestDataFactory.createTestAccountsWithContracts();
    }
    
    @isTest
    static void testAccountContractStatus(){
        Test.startTest();
        Database.executeBatch(new AccountContractStatusUpdateBatch(), 200);
        Test.stopTest();
        
        List<Account> accounts = [SELECT Contract_Expire_Date__c, Commercial_Contract_Status__c FROM Account WHERE Name IN ('Test account', 'Test account 2')];
        Account acc1 = accounts[0];
        Account acc2 = accounts[1];

        System.assertEquals('Red', acc2.Commercial_Contract_Status__c, 'Test account 2 status should be equal to Red');
        System.assertEquals(null, acc2.Contract_Expire_Date__c, 'Test account 2 contract expire date should be updated to null');
        System.assertEquals('Amber', acc1.Commercial_Contract_Status__c, 'Test account 1 status should be equal to Amber');
        System.assertNotEquals(null, acc1.Contract_Expire_Date__c, 'Test account 1 contract expire date should be updated');
    }

    @isTest
    static void testAccountContractStatusScheduled(){
        Test.startTest();
        AccountContractStatusUpdateScheduler.startScheduler();
        Test.stopTest();

        List<CronTrigger> cronJobs = [SELECT Id FROM CronTrigger];
        System.assertNotEquals(0, cronJobs.size(), 'The job should be scheduled');
    }
}
    


/*@IsTest
public with sharing class AccountContractStatusUpdateTest {
    @TestSetup
    static void initData(){
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customers').getRecordTypeId();
        Account acc = new Account(RecordTypeId = accRecordTypeId,
                                    Name = 'Text account',
                                    CurrencyIsoCode = 'GBP');
        insert acc;
        Account acc2 = new Account(RecordTypeId = accRecordTypeId,
                                    Name = 'Text account 2',
                                    CurrencyIsoCode = 'GBP',
                                    Contract_Expire_Date__c = Date.today().addDays(-2),
                                    Commercial_Contract_Status__c = 'Green');
        insert acc2;
        Commercial_Contract_Status__c cc1 = new Commercial_Contract_Status__c(Name = 'test 1', 
                                                                                Account__c = acc.Id, 
                                                                                Contract_Status__c = 'Amber',
                                                                                Start_date__c = Date.today().addDays(-2),
                                                                                End_Date__c = Date.today().addDays(2));
        insert cc1;
        Commercial_Contract_Status__c cc2 = new Commercial_Contract_Status__c(Name = 'test 2', 
                                                                                Account__c = acc.Id, 
                                                                                Contract_Status__c = 'Amber',
                                                                                Start_date__c = Date.today().addDays(-4),
                                                                                End_Date__c = Date.today().addDays(-3));
        insert cc2;
    }

    @isTest
    static void testAccountContractStatus(){
        Test.startTest();
        //AccountContractStatusUpdateScheduler.startScheduler();
        Database.executeBatch(new AccountContractStatusUpdateBatch(), 200);
        Test.stopTest();
        Account acc1 = [SELECT Contract_Expire_Date__c, Commercial_Contract_Status__c FROM Account WHERE Name = 'Text account'];
        Account acc2 = [SELECT Contract_Expire_Date__c, Commercial_Contract_Status__c FROM Account WHERE Name = 'Text account 2'];
        System.assertEquals('Red', acc2.Commercial_Contract_Status__c, 'Text account 2 status should be equal to Red');
        System.assertEquals(null, acc2.Contract_Expire_Date__c, 'Test account 2 contract expire date should be updated to null');
        System.assertEquals('Amber', acc1.Commercial_Contract_Status__c, 'Text account status should be equal to Amber');
        System.assertNotEquals(null, acc1.Contract_Expire_Date__c, 'Test account contract expire date should be updated');
    }
    
    @isTest
    static void testAccountContractStatusScheduled(){
        Test.startTest();
        AccountContractStatusUpdateScheduler.startScheduler();
        List<CronTrigger> crn = [SELECT Id FROM CronTrigger];
        Test.stopTest();
        System.assertNotEquals(0, crn.size(), 'Job schold be scheduled');
    }
}*/