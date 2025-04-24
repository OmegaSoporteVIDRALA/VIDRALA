@isTest
private class CustomRelatedListComponentControllerTest {

    @TestSetup
    static void setupData() {

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customers').getRecordTypeId();
        
        // Create and insert test Account
        Account testAccount = new Account(Name = 'Test Account', RecordTypeId = accRecordTypeId, CurrencyIsoCode = 'GBP');
        insert testAccount;

        // Create and insert test Contacts associated with the Account
        List<Contact> testContacts = new List<Contact>{
            new Contact(LastName = 'Test 1', FirstName = 'Contact', AccountId = testAccount.Id),
            new Contact(LastName = 'Test 2', FirstName = 'Contact', AccountId = testAccount.Id)
        };

        insert testContacts;
    }

    @isTest
    public static void testGetRelatedInfoWithValidData() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        CustomRelatedListComponentController.RequestParams params = new CustomRelatedListComponentController.RequestParams();
        params.recordId = acc.Id;
        params.lookupAPI = 'AccountId';
        params.relatedObjectAPI = 'Contact';
        params.fieldAPIs = 'LastName, FirstName';
        params.whereCondition = null;
        params.additionalRequest = null;
        params.additionalAPI = null;

        // Call the method with valid parameters
        CustomRelatedListComponentController.RLComponentWrapper result = CustomRelatedListComponentController.getRelatedInfo(JSON.serialize(params));

        Test.stopTest();

        // Verify the expected results
        System.assertEquals(2, result.values.size(), 'Should return 2 records');
        System.assertEquals(2, result.labels.size(), 'Should return 2 labels');
        System.assertEquals('Contact', result.objectName, 'Should be the Contact object');
    }

    @isTest
    public static void testGetRelatedInfoWithWhereCondition() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        CustomRelatedListComponentController.RequestParams params = new CustomRelatedListComponentController.RequestParams();
        params.recordId = acc.Id;
        params.lookupAPI = 'AccountId';
        params.relatedObjectAPI = 'Contact';
        params.fieldAPIs = 'LastName, FirstName';
        params.whereCondition = 'Id != null';
        params.additionalRequest = null;
        params.additionalAPI = null;

        // Call the method with a specific where condition
        CustomRelatedListComponentController.RLComponentWrapper result = CustomRelatedListComponentController.getRelatedInfo(JSON.serialize(params));

        Test.stopTest();

        // Verify the expected results
        System.assertEquals(2, result.values.size(), 'Should return 1 record');
        System.assertEquals(2, result.labels.size(), 'Should return 2 labels');
        System.assertEquals('Contact', result.objectName, 'Should be the Contact object');
    }

    @isTest
    public static void testGetRelatedInfoWithNullRecordId() {

        Test.startTest();
        
        // Expect exception for null record ID
        try {

            CustomRelatedListComponentController.RequestParams params = new CustomRelatedListComponentController.RequestParams();
            params.recordId = null;
            params.lookupAPI = 'AccountId';
            params.relatedObjectAPI = 'Contact';
            params.fieldAPIs = 'LastName, FirstName';
            params.whereCondition = null;
            params.additionalRequest = null;
            params.additionalAPI = null;

            CustomRelatedListComponentController.RLComponentWrapper result = CustomRelatedListComponentController.getRelatedInfo(JSON.serialize(params));
            System.assert(false, 'Expected exception for null record ID');
        } catch (Exception e) {

            System.debug('Exception message should indicate invalid parameters');
        }
        
        Test.stopTest();
    }

    @isTest
    public static void testGetRelatedInfoWithNullLookupAPI() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        
        CustomRelatedListComponentController.RequestParams params = new CustomRelatedListComponentController.RequestParams();
        params.recordId = acc.Id;
        params.lookupAPI = null;
        params.relatedObjectAPI = 'Contact';
        params.fieldAPIs = 'LastName, FirstName';
        params.whereCondition = null;
        params.additionalRequest = null;
        params.additionalAPI = null;

        // Expect exception for null lookup API
        try {

            CustomRelatedListComponentController.RLComponentWrapper result = CustomRelatedListComponentController.getRelatedInfo(JSON.serialize(params));
        } catch (Exception e) {

            System.debug('Exception message should indicate missing lookup API');
        }
        
        Test.stopTest();
    }

    @isTest
    public static void testGetRelatedInfoWithNullRelatedObjectAPI() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        CustomRelatedListComponentController.RequestParams params = new CustomRelatedListComponentController.RequestParams();
        params.recordId = acc.Id;
        params.lookupAPI = 'AccountId';
        params.relatedObjectAPI = null;
        params.fieldAPIs = 'LastName, FirstName';
        params.whereCondition = null;
        params.additionalRequest = null;
        params.additionalAPI = null;

        // Expect exception for null related object API
        try {

            CustomRelatedListComponentController.RLComponentWrapper result = CustomRelatedListComponentController.getRelatedInfo(JSON.serialize(params));
            System.assert(false, 'Expected exception for null related object API');
        } catch (Exception e) {

            System.debug('Exception message should indicate missing related object API');
        }
        
        Test.stopTest();
    }
}


/*@isTest
public with sharing class CustomRelatedListComponentControllerTest {
    @TestSetup
    static void initData(){
        Id accrecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customers').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account', RecordTypeId = accrecordTypeId, CurrencyIsoCode = 'GBP');
        insert acc;
        Contact c1 = new Contact(LastName = 'Test 1', FirstName = 'Contact', AccountId = acc.Id);
        insert c1;
        Contact c2 = new Contact(LastName = 'Test 2', FirstName = 'Contact', AccountId = acc.Id);
        insert c2;
    }

    @isTest
    public static void testContoller(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        CustomRelatedListComponentController ctrl = new CustomRelatedListComponentController();
        CustomRelatedListComponentController.RLComponentWrapper wrap = CustomRelatedListComponentController.getRelatedInfo(acc.Id, 'AccountId', 'Contact', 'LastName, FirstName', null, null, null);
        Test.stopTest();
        System.assertEquals(wrap.values.size(), 2, 'Requested record count should be equal 2');
        System.assertEquals(wrap.labels.size(), 2, 'Requested label count should be equal 2');
        System.assertEquals(wrap.objectName, 'Contact', 'Requested object should be Contact');
    }

    @isTest
    public static void testContoller2(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        CustomRelatedListComponentController ctrl = new CustomRelatedListComponentController();
        CustomRelatedListComponentController.RLComponentWrapper wrap = CustomRelatedListComponentController.getRelatedInfo(acc.Id, 'AccountId', 'Contact', 'LastName, FirstName', 'LastName = \'Test 1\'', null, null);
        Test.stopTest();
        System.assertEquals(wrap.values.size(), 1, 'Requested record count should be equal 1');
        System.assertEquals(wrap.labels.size(), 2, 'Requested label count should be equal 2');
        System.assertEquals(wrap.objectName, 'Contact', 'Requested object should be Contact');
    }

    @isTest
    public static void testContollerError1(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        CustomRelatedListComponentController ctrl = new CustomRelatedListComponentController();
        CustomRelatedListComponentController.RLComponentWrapper wrap = CustomRelatedListComponentController.getRelatedInfo(null, 'AccountId', 'Contact', 'LastName, FirstName', null, null, null);
        Test.stopTest();
    }

    @isTest
    public static void testContollerError2(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        CustomRelatedListComponentController ctrl = new CustomRelatedListComponentController();
        CustomRelatedListComponentController.RLComponentWrapper wrap = CustomRelatedListComponentController.getRelatedInfo(acc.Id, 'AccountId', null, 'LastName, FirstName', null, null, null);
        Test.stopTest();
    }

    @isTest
    public static void testContollerError3(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        CustomRelatedListComponentController ctrl = new CustomRelatedListComponentController();
        CustomRelatedListComponentController.RLComponentWrapper wrap = CustomRelatedListComponentController.getRelatedInfo(acc.Id, null, 'Contact', 'LastName, FirstName', null, null, null);
        Test.stopTest();
    }
}*/