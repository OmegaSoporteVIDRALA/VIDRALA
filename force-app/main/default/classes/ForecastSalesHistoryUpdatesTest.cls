/* -----------------------------------------------------------------------------------------------------------------------
   Name:        ForecastSalesHistoryUpdatesTest.cls
   Description: Test updating of Forecast records from Sales History
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Dec 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Sept 2024    2.0     Globant             Code Refactoring

------------------------------------------------------------------------------------------------------------------------ */              

@isTest
private class ForecastSalesHistoryUpdatesTest {
    private static String approvedRecordType = 'Approved_Rejected';
    
    @testSetup
    static void setupData() {
        List<Account> aList = TestDataFactory.createAccountsWithMonths(1, 10001);
        String acctNum = aList[0].SAP_Account_Number__c;
        ID accountId = aList[0].Id;
        
        List<Forecast__c> fList = TestDataFactory.createForecasts(8, acctNum, 800, 1000);
        delete new List<Forecast__c>{fList[0], fList[94], fList[95]};
        
        List<Actual_Sales_History__c> sList = TestDataFactory.createSalesHistory(8, accountId, 1000);
    }
    
    @isTest
    static void testSalesUpdatesPriorYear() {
        Test.startTest();
        
        List<Forecast__c> fList = [SELECT Id, Prior_Year__c FROM Forecast__c LIMIT 1];
        List<Actual_Sales_History__c> sList = [SELECT Volume_000_s__c FROM Actual_Sales_History__c LIMIT 2];
        
        Double lastYearSales = sList[0].Volume_000_s__c;
        Forecast__c forecast = fList[0];
        
        System.assertEquals(lastYearSales, forecast.Prior_Year__c);
        
        Test.stopTest();
    }


    @isTest
    static void testForecastDeletionAndCreation() {
        Test.startTest();
        
        List<Forecast__c> fList = [SELECT Id FROM Forecast__c];
        delete fList;
        
        fList = [SELECT Id FROM Forecast__c];
        System.assertEquals(0, fList.size());
        
        Actual_Sales_History__c asRecord = [SELECT Account__c, Bottle__c, Month__c, Item__c, Volume_000_s__c, Tonnes__c, Revenue__c, Year__c, Sales_Organization__c 
                                            FROM Actual_Sales_History__c 
                                            LIMIT 1];
        Actual_Sales_History__c asCopy = new Actual_Sales_History__c(
            Account__c = asRecord.Account__c, 
            Month__c = asRecord.Month__c,
            Item__c = asRecord.Item__c,
            Volume_000_s__c = asRecord.Volume_000_s__c,
            Tonnes__c = asRecord.Tonnes__c,
            Revenue__c = asRecord.Revenue__c,
            Year__c = asRecord.Year__c,
            Sales_Organization__c = asRecord.Sales_Organization__c
        );
        insert asCopy;
        
        fList = [SELECT Id FROM Forecast__c];
        System.assertEquals(1, fList.size());
        
        Test.stopTest();
    }
}


/*
@isTest
private class TestForecastSalesHistoryUpdates {
    private static String approvedRecordType = 'Approved_Rejected';
    
    private static testMethod void testSalesUpdates() {  
        // create one Account
        List<Account> aList = TestDataFactory.createAccountsWithMonths(1, 10001);
        String acctNum = aList[0].SAP_Account_Number__c;
        ID accountId = aList[0].Id;
        
        // create 96 forecast records (8 x 12 months)
        List<Forecast__c> fList = TestDataFactory.createForecasts(8, acctNum, 800, 1000);
        // delete some forecasts
        delete new List<Forecast__c>{fList[0],fList[94],fList[95]};
        
        // create corresponding Sales History records (this year and last year)
        List<Actual_Sales_History__c> sList = TestDataFactory.createSalesHistory(8, accountId, 1000);
        
        Forecast__c f = [select Prior_Year__c, Prior_Month_Actual_Total__c from Forecast__c where Id = :fList[2].Id];
        Double lastYearSales = sList[2].Volume_000_s__c;
        Double thisYearSales = sList[96].Volume_000_s__c + sList[97].Volume_000_s__c;
        
        System.debug('lastYearSales, thisYearSales: '+lastYearSales+','+thisYearSales);
        System.debug('Forecast__c: '+f);
        
        System.assertEquals(lastYearSales, f.Prior_Year__c);
        System.assertEquals(thisYearSales, f.Prior_Month_Actual_Total__c);
        Actual_Sales_History__c asRecord = [SELECT Account__c, Bottle__c, Month__c, Item__c, Volume_000_s__c, Tonnes__c, Revenue__c, Year__c, Sales_Organization__c 
                                            FROM Actual_Sales_History__c 
                                            LIMIT 1];
        fList = [SELECT Id FROM Forecast__c];
        delete fList;
        Actual_Sales_History__c asCopy = new Actual_Sales_History__c(Account__c = asRecord.Account__c, 
                                                                    Month__c = asRecord.Month__c,
                                                                    Item__c = asRecord.Item__c,
                                                                    Volume_000_s__c = asRecord.Volume_000_s__c,
                                                                    Tonnes__c = asRecord.Tonnes__c,
                                                                    Revenue__c = asRecord.Revenue__c,
                                                                    Year__c = asRecord.Year__c,
                                                                    Sales_Organization__c = asRecord.Sales_Organization__c);
        insert asCopy;
        fList = [SELECT Id FROM Forecast__c];
        System.assertEquals(1, fList.size(), 'Forecast record should be created');
    }
}*/