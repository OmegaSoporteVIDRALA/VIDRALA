@isTest
public class OM_VID_AccountTRGHandler_UT {
    
    @isTest static void testHandlerMethod_InsertMethods(){ 
        Test.StartTest();
        OM_VID_TestUtils.createAccountsWithContacts(1);
        
        List<Account> destinatarios = [SELECT ID FROM Account WHERE RecordTypeId =: OM_Utils.RecordTypes.getRecordTypeByDevName('Account', 'OM_VID_Destinatario')];
        //Assert.areEqual(acc.Phone, '+34 523456789', 'Account phone number hasn\'t got the expected format');
        Assert.areEqual(destinatarios.size(), 1);
        Test.StopTest();
    }
    
    @isTest 
    static void test_setOwnerId() {
        
        Id customerRecordTypeId = OM_Utils.RecordTypes.getRecordTypeByDevName('Account', 'OM_VID_Destinatario');
        
        
       User owner = OM_VID_TestUtils.createVidralaUser();
       insert owner;
		
        
       Account parent = new Account(
            Name = 'Test Parent Account',
            SAP_Account_Number__c = '11268',
            RecordTypeId = customerRecordTypeId,
            OM_VID_SalesOrganizations__c = 'VD10',
           	OwnerId = owner.Id
        );
        insert parent;
    
       Account hija = new Account(
            Name = 'Test Account',
            RecordTypeId = customerRecordTypeId,
            ParentId = parent.Id,
            SAP_Account_Number__c = '11269',
            OM_VID_SalesOrganizations__c = 'VD10' 
        );
    
        List<Account> newList = new List<Account>{hija};
    
        Test.startTest();
        OM_VID_AccountTRGHandlerMethods.setOwnerId(newList);
        Test.stopTest();
    
        System.assertEquals(parent.OwnerId, newList[0].OwnerId, 'El OwnerId del destinatario debe ser igual al del ParentAccount');
    }
}