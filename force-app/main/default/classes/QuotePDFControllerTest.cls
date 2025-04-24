@isTest
private class QuotePDFControllerTest {

    @isTest static void testAttachment() {  
        Test.startTest();
        Quote testQuote = TestDataFactory.createQuote();
        string result = QuotePDFController.attachPDF(testQuote.Id, 'testURL', 'testPage');
        Test.stopTest();
        QuoteDocument attach = [
            SELECT Id, Name, QuoteId, ContentVersionDocumentId, Document 
            FROM QuoteDocument
            WHERE QuoteId = :testQuote.Id
            LIMIT 1
        ];
        System.assertEquals('success', result);
        System.assertEquals(testQuote.Id, attach.QuoteId, 'QuoteId should match the test quote');
    }
    @IsTest
    static void testAttachPDFWithBlankParameters() {
        Test.startTest();
        String result = QuotePDFController.attachPDF('', '', '');
        Test.stopTest();
        System.assert(result == null, 'Expected null result for blank parameters.');

    }
    
}

/*@isTest
private class QuotePDFControllerTest {

    @isTest static void testAttachment() {  
        Quote testQuote = TestDataFactory.createQuote();
        string result = QuotePDFController.attachPDF(testQuote.Id, 'testURL', 'testPage');
        QuoteDocument attach = [
            SELECT Id, Name, QuoteId, ContentVersionDocumentId, Document 
            FROM QuoteDocument
            WHERE QuoteId = :testQuote.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, attach);
    }
}*/