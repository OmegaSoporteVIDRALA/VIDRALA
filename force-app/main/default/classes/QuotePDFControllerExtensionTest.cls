@isTest
private class QuotePDFControllerExtensionTest {
    
    @IsTest private static void testController() {
        Quote testQuote = TestDataFactory.createQuote();
        Account testAcc = [
            SELECT Id, Name, Market__c 
            FROM Account
            LIMIT 1
        ];
        Rebate__c reb = new Rebate__c(
            Account__c = testAcc.Id,
            Rebate_Commencement_Date__c = System.today(),
            Rebate_Expiry_Date__c = System.today() + 1,
            Reason_for_Rebate__c = 'Reason'
        );
        insert reb;
       
        PageReference pageRef = Page.QuotePDF; 
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(testQuote.Id));
        ApexPages.StandardController quoteController = new ApexPages.StandardController(testQuote);
        
        QuotePDFControllerExtension testQuotePDF = new QuotePDFControllerExtension(quoteController);
        QuotePDFControllerExtension.QuoteItemWrapper testWrapper = new QuotePDFControllerExtension.QuoteItemWrapper('', '', '', '', 0);

        System.assertEquals('VIDRALA FRANCE', testQuotePDF.accountName);
        
        testAcc.Market__c = 'PT';
        update testAcc;

        QuotePDFControllerExtension testQuotePDFPT = new QuotePDFControllerExtension(quoteController);
        System.assertEquals('VIDRALA, S.A.', testQuotePDFPT.accountName);

        testAcc.Market__c = 'ES';
        update testAcc;

        QuotePDFControllerExtension testQuotePDFES = new QuotePDFControllerExtension(quoteController);
        System.assertEquals('VIDRALA, S.A.', testQuotePDFES.accountName);

        testAcc.Market__c = 'FR';
        update testAcc;

        QuotePDFControllerExtension testQuotePDFRM = new QuotePDFControllerExtension(quoteController);
        System.assertEquals('commercial@vidrala.com', testQuotePDFRM.accountEmail);

        testAcc.Market__c = 'NM';
        update testAcc;

        QuotePDFControllerExtension testQuotePDFNM = new QuotePDFControllerExtension(quoteController);
        System.assertEquals('export@vidrala.com', testQuotePDFNM.accountEmail);
        
    }
}