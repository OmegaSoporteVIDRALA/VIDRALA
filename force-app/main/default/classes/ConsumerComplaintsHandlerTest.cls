@isTest
public with sharing class ConsumerComplaintsHandlerTest {
    
    @TestSetup
    static void makeData() {
        // Using TestDataFactory to create test data
        Account acc = TestDataFactory.createActiveCustomerAccount();
        insert acc;

    }

    @isTest
    public static void testInsert() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test account' LIMIT 1];
        List<Consumer_Complaint__c> complaints = new List<Consumer_Complaint__c>();

        complaints.add(TestDataFactory.createConsumerComplaint(acc.Id, 'Unknown', 'Yes'));
        complaints.add(TestDataFactory.createConsumerComplaint(acc.Id, 'Elton', 'Yes'));
        complaints.add(TestDataFactory.createConsumerComplaint(acc.Id, 'Derrylin', 'Yes'));
        complaints.add(TestDataFactory.createConsumerComplaint(acc.Id, 'Corsico', 'Yes'));

        Test.startTest();
        insert complaints;
        Test.stopTest();

        // Assert to ensure records were inserted correctly
        List<Consumer_Complaint__c> insertedComplaints = [SELECT Id, Customer__c, Plant__c FROM Consumer_Complaint__c WHERE Customer__c = :acc.Id];
        System.assertEquals(4, insertedComplaints.size(), 'Four consumer complaints should have been inserted.');
    }

    @isTest
    public static void testUpdate() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test account' LIMIT 1];
        
        // Fetch existing complaints created in TestSetup
        List<Consumer_Complaint__c> complaints = [SELECT Id, Complaint_Type_Confirmed_Date__c FROM Consumer_Complaint__c WHERE Customer__c = :acc.Id];

        // Update complaints with a confirmed date
        Test.startTest();
        for (Consumer_Complaint__c complaint : complaints) {
            complaint.Complaint_Type_Confirmed_Date__c = System.today().addDays(-1);
        }
        update complaints;
        Test.stopTest();

        // Assert that the complaints were updated with the correct date
        List<Consumer_Complaint__c> updatedComplaints = [SELECT Complaint_Type_Confirmed_Date__c FROM Consumer_Complaint__c WHERE Customer__c = :acc.Id];
        for (Consumer_Complaint__c complaint : updatedComplaints) {
            System.assertEquals(System.today().addDays(-1), complaint.Complaint_Type_Confirmed_Date__c, 'Complaint Type Confirmed Date should be updated.');
        }
    }
}



/*@isTest
public with sharing class ConsumerComplaintsHandlerTest {
    @TestSetup
    static void makeData(){
        Account acc = new Account();
        acc.Name = 'testAccount';
        insert acc;
    }

    @isTest
    public static void testInsert() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Consumer_Complaint__c> ccs = new List<Consumer_Complaint__c>();
        Consumer_Complaint__c cc1 = new Consumer_Complaint__c();
        cc1.Customer__c = acc.Id;
        cc1.Plant__c = 'Unknown';
        cc1.Manufacturing_Fault_Present__c = 'Yes';
        Consumer_Complaint__c cc2 = new Consumer_Complaint__c();
        cc2.Customer__c = acc.Id;
        cc2.Plant__c = 'Elton';
        cc2.Manufacturing_Fault_Present__c = 'Yes';
        Consumer_Complaint__c cc3 = new Consumer_Complaint__c();
        cc3.Customer__c = acc.Id;
        cc3.Plant__c = 'Derrylin';
        cc3.Manufacturing_Fault_Present__c = 'Yes';
        Consumer_Complaint__c cc4 = new Consumer_Complaint__c();
        cc4.Customer__c = acc.Id;
        cc4.Plant__c = 'Corsico';
        cc4.Manufacturing_Fault_Present__c = 'Yes';
        ccs.add(cc1);
        ccs.add(cc2);
        ccs.add(cc3);
        ccs.add(cc4);
        Test.startTest();
        insert ccs;
        Test.stopTest();
    }

    @isTest
    public static void testUpdate() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Consumer_Complaint__c> ccs = new List<Consumer_Complaint__c>();
        Consumer_Complaint__c cc1 = new Consumer_Complaint__c();
        cc1.Customer__c = acc.Id;
        cc1.Plant__c = 'Unknown';
        cc1.Manufacturing_Fault_Present__c = 'Yes';
        Consumer_Complaint__c cc2 = new Consumer_Complaint__c();
        cc2.Customer__c = acc.Id;
        cc2.Plant__c = 'Elton';
        cc2.Manufacturing_Fault_Present__c = 'Yes';
        Consumer_Complaint__c cc3 = new Consumer_Complaint__c();
        cc3.Customer__c = acc.Id;
        cc3.Plant__c = 'Derrylin';
        cc3.Manufacturing_Fault_Present__c = 'Yes';
        Consumer_Complaint__c cc4 = new Consumer_Complaint__c();
        cc4.Customer__c = acc.Id;
        cc4.Plant__c = 'Corsico';
        cc4.Manufacturing_Fault_Present__c = 'Yes';
        ccs.add(cc1);
        ccs.add(cc2);
        ccs.add(cc3);
        ccs.add(cc4);
        insert ccs;
        Test.startTest();
        for(Consumer_Complaint__c cc : ccs) {
            cc.Complaint_Type_Confirmed_Date__c = System.today().addDays(-1);
        }
        update ccs;
        Test.stopTest();
    }
}*/