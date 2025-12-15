@isTest
public class OM_VID_QuoteTRGHandlerMethods_Test {
    
    @isTest
    static void quoteFieldsTranslation(){
        
       
        
        Id standardPBId = Test.getStandardPricebookId();
        
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customers').getRecordTypeId();

        Account acc = new Account(
        Name = 'Test Account',
        SAP_Account_Number__c = '11268',
        RecordTypeId = customerRecordTypeId,
        OM_VID_SalesOrganizations__c = 'VD10',
        OM_VID_AgreedTerms__c = 'ZD',
        OM_VID_PaymentMethods__c = 'AF6C' 
    );
    	insert acc;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry standardEntry = new PricebookEntry(
            Pricebook2Id = standardPBId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardEntry;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Introduction',
            CloseDate = Date.today().addDays(10),
            OM_VID_Idioma__c = 'Español',
            AccountId = acc.Id
        );
        insert opp;
        
        opp.StageName = 'Quotation';
        update opp;

        OpportunityLineItem oppLine = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            PricebookEntryId = standardEntry.Id,
            UnitPrice = 100
        );
        insert oppLine;
        
        String QuoteRTFiftyId = [SELECT Id FROM RecordType WHERE SObjectType = :OM_VID_Constants.quoteName AND DeveloperName = :OM_VID_Constants.quoteRTFifty LIMIT 1].Id; 
        
        Quote q = new Quote(
        Name = 'test',
        OpportunityId = opp.Id,
        RecordTypeId = QuoteRTFiftyId,
        ExpirationDate = Date.today() + 30,
        OM_VID_DetallesAdicionales__c = opp.Description
        );
            
        OM_Utils.shouldSkipTriggerGlobal = false;
        
        Test.startTest();
        insert q;
        Test.stopTest();
	}
    
    @isTest 
    static void testByPassApexFlag() {
    
    OM_VID_QuoteTRGHandler.setbyPassApex(true);
    System.assertEquals(true, OM_VID_QuoteTRGHandler.getbyPassApex());

    
    OM_VID_QuoteTRGHandler.execute(
        new List<Quote>(), 
        new Map<Id, Quote>(),
        true,  
        false, 
        true,  
        false, 
        false  
    );

    OM_VID_QuoteTRGHandler.setbyPassApex(false);
    System.assertEquals(false, OM_VID_QuoteTRGHandler.getbyPassApex());
	}
    
    @isTest
    static void testCloseTasks() {

        Account acc = new Account(
            Name = 'Test Account',
            SAP_Account_Number__c = '11268'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Introduction',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        Task task = new Task(
            Subject = OM_VID_Constants.taskSubjectSendQuotation,
            Status = 'Open',
            WhatId = opp.Id
        );
        insert task;

        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            OM_VID_Oferta_Enviada__c = false
        );
        insert quote;

        quote.OM_VID_Oferta_Enviada__c = true;
        update quote;

        Map<Id, Quote> oldMap = new Map<Id, Quote>{ quote.Id => quote };
        List<Quote> newQuotes = new List<Quote>{ quote };

        Test.startTest();
        OM_VID_QuoteTRGHandlerMethods.closeTasks(newQuotes, oldMap);
        Test.stopTest();

        Task tUpdated = [SELECT Status FROM Task WHERE Id = :task.Id];
        System.assertEquals(OM_VID_Constants.taskStatusCompleted, tUpdated.Status, 'El Task debe haberse cerrado');
    }
}