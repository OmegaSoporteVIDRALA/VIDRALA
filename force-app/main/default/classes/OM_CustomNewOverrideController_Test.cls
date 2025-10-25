@IsTest
private class OM_CustomNewOverrideController_Test {
    
    @testSetup
    static void setupData() {
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customers').getRecordTypeId();

        Account parentAcc = new Account(
            Name = 'Parent Account',
            SAP_Account_Number__c = '11268',
            RecordTypeId = customerRecordTypeId,
            OM_VID_SalesOrganizations__c = 'VD10'
        );
        insert parentAcc;
        
        Account childAcc = new Account(
            Name = 'Child Account',
            RecordTypeId = customerRecordTypeId,
            ParentId = parentAcc.Id,
            SAP_Account_Number__c = '11269',
            OM_VID_SalesOrganizations__c = 'VD10'
        );
        insert childAcc;
    }
  
    @IsTest
    static void testGetAccountParent() {
        Account child = [SELECT Id, Name FROM Account WHERE SAP_Account_Number__c = '11269' LIMIT 1];
        
        Test.startTest();
        Account result = OM_CustomNewOverrideController.getAccountWithParent(child.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        System.assertEquals(child.Id, result.Id, 'Debe devolver la cuenta hija');
        System.assertNotEquals(null, result.ParentId, 'La cuenta hija debe tener padre');
        System.assertEquals('Customers', result.RecordType.DeveloperName, 'El RecordType debe ser Customers');
    }

    @IsTest
    static void testGetUserProfile() {
        Test.startTest();
        Id profileId = OM_CustomNewOverrideController.getUserProfile();
        Test.stopTest();

        System.assertNotEquals(null, profileId, 'El método debe devolver un Id de perfil');
        System.assertEquals(UserInfo.getProfileId(), profileId, 'Debe devolver el ProfileId del usuario actual');
    }
}