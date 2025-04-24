/**
* @description       :
* @author            : mmadridp@omegacrmconsulting.com
* @group             :
* @last modified on  : 17-04-2024
* @last modified by  : mmadridp@omegacrmconsulting.com
**/
@isTest
public with sharing class OM_VID_EnviarEmailOfertaControllerTest {
    @TestSetup
    static void makeData(){
        OM_VID_TestUtils.createQuotes(1);
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        List<Opportunity> oppList = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        OM_VID_TestUtils.createDrawingWithContentVersion(oppList[0].AccountId/*, oppLine.Product2Id*/);
        Drawing__c draw = [SELECT Id FROM Drawing__c LIMIT 1];
        OM_VID_TestUtils.createOpportunityLineItems(oppList, 1, draw.Id);
        OpportunityLineItem oppLine = [SELECT Id, Quantity, PricebookEntryId, Product2Id, UnitPrice, Description FROM OpportunityLineItem WHERE OpportunityId = :oppList[0].Id LIMIT 1];

        OM_VID_TestUtils.createQuoteLineItem(oppLine, q.Id);
    }
    
    @isTest
    static void validateErrorsTest(){
        Quote q = [SELECT Id, OpportunityId FROM Quote LIMIT 1];
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = : q.OpportunityId LIMIT 1];
        Contact cont = [SELECT Id FROM Contact LIMIT 1];

        System.debug('MMP QLine: ' + [SELECT Id FROM QuoteLineItem WHERE QuoteId =: q.Id LIMIT 1]);

        Test.startTest();
        String test1 = OM_VID_EnviarEmailOfertaController.validateErrors(q.Id);
        opp.OM_VID_Idioma__c = 'Español';
        opp.Contact__c = cont.Id;
        update opp;
        OM_VID_TestUtils.createContentVersion(q.Id);
        String test2 = OM_VID_EnviarEmailOfertaController.validateErrors(q.Id);
        Test.stopTest();

        System.assertNotEquals(null, test1);
        System.debug('MMP test2: ' + test2);
    }

    @isTest
    static void getTemplateNameFormulaTest(){
        System.assertEquals('ES' + OM_VID_Constants.fiftyTemplateName, OM_VID_EnviarEmailOfertaController.getTemplateNameFormula('Español'));
        System.assertEquals('FR' + OM_VID_Constants.fiftyTemplateName, OM_VID_EnviarEmailOfertaController.getTemplateNameFormula('Francés'));
        System.assertEquals('PT' + OM_VID_Constants.fiftyTemplateName, OM_VID_EnviarEmailOfertaController.getTemplateNameFormula('Portugués'));
        System.assertEquals('EN' + OM_VID_Constants.fiftyTemplateName, OM_VID_EnviarEmailOfertaController.getTemplateNameFormula('Inglés'));
    }
}