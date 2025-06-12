@isTest
public class OM_VID_GenerateOffersController_Test {
    
   
	
    @IsTest
    static void testCreateQuote() {
        
        Id standardPBId = Test.getStandardPricebookId();

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
            CloseDate = Date.today().addDays(10)
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

        Test.startTest();
        OM_VID_GenerateOffersController.createQuote(opp.Id);
        Test.stopTest();

        List<Quote> quotes = [SELECT Id, OpportunityId FROM Quote WHERE OpportunityId = :opp.Id];
        System.assertEquals(1, quotes.size(), 'Quote debería haberse creado');

        List<QuoteLineItem> qli = [SELECT Id, QuoteId FROM QuoteLineItem WHERE QuoteId = :quotes[0].Id];
        System.assertEquals(1, qli.size(), 'QuoteLineItem debería haberse creado');
    }
}