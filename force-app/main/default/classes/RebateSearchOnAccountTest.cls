@isTest
public class RebateSearchOnAccountTest {    
    @TestSetup
    public static void setupTestData() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.CurrencyIsoCode = 'GBP';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.StageName = 'Introduction';
        opp.CurrencyIsoCode = 'GBP';
        opp.CloseDate = System.today();
        insert opp;
        
        Quote qc = new Quote();
        qc.Name = 'Test Quote';
        qc.OpportunityId = opp.Id;
        qc.ExpirationDate = system.today();
        qc.Status = 'Draft';
        insert qc;
        
        Rebate__c reb = new Rebate__c();
        reb.Account__c = acc.Id;
        reb.Reason_for_Rebate__c = 'Test Rebate';
        reb.Rebate_Commencement_Date__c = System.today();
        reb.Rebate_Expiry_Date__c = System.today().addDays(7);
        insert reb;
    }

    @isTest
    public static void testSearchRebateReturnsRebates() {     
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        List<Rebate__c> rebates = RebateSearchOnAccount.searchRebate(testQuote.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, rebates.size(), 'Expected to find at least one rebate for the account.');
        System.assertEquals('Test Rebate', rebates[0].Reason_for_Rebate__c, 'The rebate reason should match the test data.');
    }
    
    @isTest
    public static void testSearchRebateThrowsExceptionOnNullId() {
        Test.startTest();
        try {
            List<Rebate__c> rebates = RebateSearchOnAccount.searchRebate(null);
            System.assert(false, 'Expected CustomException was not thrown.');
        } catch (RebateSearchOnAccount.CustomException e) {
            System.assertEquals('Quote record ID cannot be null.', e.getMessage(), 'Exception message should match expected.');
        }
        Test.stopTest();
    }

    @isTest
    public static void testSearchRebateThrowsExceptionOnNoQuoteFound() {
        Test.startTest();
        try {
            List<Rebate__c> rebates = RebateSearchOnAccount.searchRebate('001000000000000AAA'); // Invalid Id
            System.assert(false, 'Expected CustomException was not thrown.');
        } catch (RebateSearchOnAccount.CustomException e) {
            System.assertEquals('No records found in Quote/Rebate query', e.getMessage(), 'Exception message should match expected.');
        }
        Test.stopTest();
    }
}


/*@isTest
public class RebateSearchOnAccountTest {
	@isTest
    public static void testMethod1(){
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.CurrencyIsoCode = 'GBP';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.StageName = 'Introduction';
        opp.CurrencyIsoCode = 'GBP';
        opp.CloseDate = System.today();
        insert opp;
        
        Quote qc = new Quote();
        qc.Name = 'Test Quote';
        qc.OpportunityId = opp.Id;
        qc.ExpirationDate = system.today();
        qc.Status = 'Draft';
        insert qc;
        
        Rebate__c reb = new Rebate__c();
        reb.Account__c = acc.Id;
        reb.Reason_for_Rebate__c = 'Test';
        reb.Rebate_Commencement_Date__c = System.today() ;
        reb.Rebate_Expiry_Date__c = System.today().addDays(7);
        insert reb;
        
        Test.startTest();
        RebateSearchOnAccount.searchRebate(qc.Id);
        Test.stopTest();
    }
}*/