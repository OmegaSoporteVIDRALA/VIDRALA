/**
* @description       :
* @author            : mmadridp@omegacrmconsulting.com
* @group             :
* @last modified on  : 17-04-2024
* @last modified by  : mmadridp@omegacrmconsulting.com
**/
@isTest
public with sharing class OM_VID_EmailControllerTest {
    @TestSetup
    static void makeData(){
        OM_VID_TestUtils.createAccountsWithContacts(1);
        OM_VID_TestUtils.createQuotes(1);
    }

    @isTest
    static void sendEmailTest(){
        Contact c = [SELECT Id, Email FROM Contact LIMIT 1];
        Quote q = [SELECT Id, Opportunity.OwnerId, Name, Opportunity.Contact__c, OM_VID_Idioma__c FROM Quote LIMIT 1];
        String templateName = 'ES' + OM_VID_Constants.fiftyTemplateName;

        ContentVersion cvl = new Contentversion(); 
        cvl.Title = 'CZDSTOU'; 
        cvl.PathOnClient = 'test'; 
        cvl.VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body');
        List<ContentVersion> cvList = new List<ContentVersion>();
        cvList.add(cvl);
        insert cvList;

        Test.startTest();
        String s = OM_VID_EmailController.sendQuoteEmail(templateName, q, cvList);
        Test.stopTest();

        System.assertEquals('Ok', s, 'Esperabamos Ok pero hemos recibido un error: ' + s);
    }
}