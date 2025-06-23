@isTest
public class OM_Utils_UT {

    /* @TestSetup static void makeData(){
        WSRecipientList__mdt mdtRecord = new WSRecipientList__mdt();
        mdtRecord.Origin__c = Utils.SandboxName;
        mdtRecord.Class__c = 'OS_CreateCustomerEBX';
        insert mdtRecord;
    } */

    @isTest static void globalVariableTest(){
        OM_Utils.shouldSkipTriggerGlobal = false;
    }
    
    @isTest static void singletonPatternTest(){
        User CurrentUserRecord = OM_Utils.CurrentUserRecord;
        Organization Org = OM_Utils.Org;
    }
    
    @isTest static void profilesClassTest(){
        OM_Utils.Profiles.getProfileIdFromName('System Administrator');
        try{OM_Utils.Profiles.getProfileIdFromName('System Administrator Fake');}catch(Exception e){System.debug('Catched Exception Test: ' + e.getMessage());}
        
        OM_Utils.Profiles.getGroupsByName();
        
        OM_Utils.Profiles.isCurrentUserAdmin();
    }
    
    @isTest static void stringClassTest(){
        Assert.areEqual('Hello world with a …', OM_Utils.Strings.abbreviate('Hello world with a test', 20), 'It should abbreviate');
        Assert.areEqual('Hello world with end', OM_Utils.Strings.abbreviate('Hello world with end', 20), 'It should not abbreviate until 20 characters');
        
        Assert.areEqual('Jan', OM_Utils.Strings.getMonthAbbreviation(1), 'It should work');
        Assert.areNotEqual('Aug', OM_Utils.Strings.getMonthAbbreviation(2), 'It should not work');

    }
    

    @isTest static void integrationMsgTest(){
        OM_Utils.IntegrationMsg.createRESTIntegrationMsg(OM_Utils.IntegrationMsg.OUTBOUND, 'www.test.com', 'POST');
        OM_Utils.IntegrationMsg.addBody('request body', 'response body');
        OM_Utils.IntegrationMsg.addStatusAndRecord(OM_Utils.IntegrationMsg.ERROR, '001215', null, null);
        OM_Utils.IntegrationMsg.insertRecord();

        OM_Utils.IntegrationMsg.intMsg = new IntegrationMessage__c(); // To clean the structure

        OM_Utils.IntegrationMsg.createSOAPIntegrationMsg(OM_Utils.IntegrationMsg.INBOUND, 'www.test.com', 'SOAP_Method');
        OM_Utils.IntegrationMsg.addBody('This is my request');
        OM_Utils.IntegrationMsg.addResponse('This is my request');
        OM_Utils.IntegrationMsg.addStatusAndRecord(OM_Utils.IntegrationMsg.SUCCESS, '02215', null, null);
        OM_Utils.IntegrationMsg.insertRecord();
    }

    @isTest static void dmlOperationsTest(){

        User otherUser = [SELECT Id FROM User WHERE username like '%omegacrmconsulting%' LIMIT 1];
        
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test' + i,
                LastName = 'Lead',
                Company = 'Test bio' + i,
                OwnerId = UserInfo.getUserId()));
        }

        testLeads.add( // Wrong record
            new Lead(Company = 'Test bio _ with errors',OwnerId = UserInfo.getUserId())
        );
        
        Test.startTest();
        OM_Utils.DmlResults.getErrorsMap(Database.insert(testLeads, false), testLeads, null);
        OM_Utils.DmlResults.getErrorsMap(Database.upsert(testLeads, false), testLeads, null);
        OM_Utils.DmlResults.getErrorsMap(Database.upsert(testLeads[0], false), testLeads[0], null);
        
        System.runAs(otherUser){
            List<Lead> auxList = new List<Lead>{testLeads[0]};
            OM_Utils.DmlResults.getErrorsMap(Database.delete(auxList, false), auxList, null);
        }
        Test.stopTest();
    }

    @isTest static void recordTypesTest(){
        OM_Utils.RecordTypes.getRecordTypeByDevName('Account',  'Customers');
        OM_Utils.RecordTypes.getRecordTypeByDevName('Opportunity', 'Fifty Master Opportunity');

        try{
            OM_Utils.RecordTypes.getRecordTypeByDevName('Opportunity', 'Opportunity__');
        }catch(Exception e){
            System.debug('Error catched in Test Class: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void testGetTranslationsForField() {
        
        OM_Utils.FieldTranslations translations = new OM_Utils.FieldTranslations();
        
        translations.getTranslationMap(); 

        translations.translationMap.put('account|fieldname|value|en', 'TranslatedValue');

        Map<String, String> result = translations.getTranslationsForField('Account', 'FieldName', 'en');

        System.assertEquals(1, result.size(), 'Debe haber una traducción');
        System.assertEquals('TranslatedValue', result.get('value'), 'La traducción no es la esperada');
    }

    @IsTest
    static void testParseSAPDateValid() {
        String sapDate = '20250618';
        Date expectedDate = Date.newInstance(2025, 6, 18);

        Date result = OM_Utils.parseSAPDate(sapDate);

        System.assertEquals(expectedDate, result, 'Fecha no coincide');
    }

    @IsTest
    static void testParseSAPDateInvalid() {
        String invalidDate = '2025618';
        Date result = OM_Utils.parseSAPDate(invalidDate);
        System.assertEquals(null, result, 'Debe devolver null');
    }

    @IsTest
    static void testParseSAPDateNull() {
        Date result = OM_Utils.parseSAPDate(null);
        System.assertEquals(null, result, 'Debe devolver null');
    }
}