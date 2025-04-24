@isTest
private class CustomRelatedListControllerTest {

    @TestSetup
    private static void setupTestData() {
        
        Account testAcc = TestDataFactory.createActiveCustomerAccount();
        Quote testQuote = TestDataFactory.createQuote();

        Discount__c discount1 = new Discount__c(
            Account__c = testQuote.Account_Id_Copy__c,
            Status__c = 'Approved',
            CurrencyIsoCode = 'EUR',
            TYPE__c = 'ZDUN - Descuento unitario',
            Quantity__c = 100,
            Percentage__c = 10,
            EUR__c = 500
        );
        insert discount1;

        Packaging_Agreement__c agreement1 = new Packaging_Agreement__c(
            Account__c = testQuote.Account_Id_Copy__c,
            Agreement__c = 'Depósito',
            Material__c = '8003625 Top Frame - 25 mm',
            Agreement_Code__c = 'AG001',
            Credit_Price__c = 50,
            Debit_Price__c = 70
        );
        insert agreement1;
    }

    @IsTest 
    private static void testGetDiscounts() {
        Test.startTest();
        Quote testQuote = [SELECT Id, AccountId FROM Quote LIMIT 1];
        
        List<Discount__c> discounts = CustomRelatedListController.getDiscounts(testQuote.Id);
        
        // Assert the results
        System.assertNotEquals(null, discounts, 'Discount list should not be null.');
        System.assertEquals(1, discounts.size(), 'There should be one discount associated.');

        // Assert fields of the discount
        Discount__c discount = discounts[0];
        System.assertEquals('Approved', discount.Status__c, 'Discount status should be Approved.');
        System.assertEquals('EUR', discount.CurrencyIsoCode, 'Currency should be EUR.');
        System.assertEquals(10, discount.Percentage__c, 'Discount percentage should be 10.');
        
        Test.stopTest();
    }

    @IsTest 
    private static void testGetAgreements() {
        Test.startTest();
        Quote testQuote = [SELECT Id, AccountId FROM Quote LIMIT 1]; 
        
        List<Packaging_Agreement__c> agreements = CustomRelatedListController.getAgreements(testQuote.Id);
        
        // Assert the results
        System.assertNotEquals(null, agreements, 'Agreement list should not be null.');
        System.assertEquals(1, agreements.size(), 'There should be one agreement associated.');

        // Assert fields of the agreement
        Packaging_Agreement__c agreement = agreements[0];
        System.assertEquals('Depósito', agreement.Agreement__c, 'Agreement name should match.');
        System.assertEquals('8003625 Top Frame - 25 mm', agreement.Material__c, 'Material should be Plastic.');
        System.assertEquals(50, agreement.Credit_Price__c, 'Credit price should be 50.');
        
        Test.stopTest();
    }
}

/*
@isTest
private class CustomRelatedListControllerTest {
    
    @IsTest private static void testGetDiscounts() {
        Quote testQuote = TestDataFactory.createQuote();
        List<Discount__c> discounts = CustomRelatedListController.getDiscounts(testQuote.Id);
        System.assertEquals(0, discounts.size());
    }

    @IsTest private static void testGetAgreements() {
        Quote testQuote = TestDataFactory.createQuote();
        List<Packaging_Agreement__c>  agreements = CustomRelatedListController.getAgreements(testQuote.Id);
        System.assertEquals(0, agreements.size());
    }
}*/