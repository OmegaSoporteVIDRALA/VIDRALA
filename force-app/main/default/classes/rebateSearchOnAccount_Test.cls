@isTest
public class rebateSearchOnAccount_Test {
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
        rebateSearchOnAccount.searchRebate(qc.Id);
        Test.stopTest();
    }
}