/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchLoadBatchTest.cls
   Description: Test the DispatchLoadBatch batch Apex class
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Dec 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Oct 2024     2.0     Globant             Refactor 
------------------------------------------------------------------------------------------------------------------------ */        

@isTest
private class DispatchLoadBatchTest  {
    private static final String HAULIER_NUM = '1234';
    private static final Integer NUM_BOTTLES = 200000;
    private static final Integer NUM_TONNES = 20;
    private static final Integer ACCOUNT_FIRST_NUM = 10001;
    private static final Integer FORECAST_NUM_BOTTLES = 1;
    private static final Integer FORECAST_BUDGET = 800;
    private static final Integer FORECAST_AMOUNT = 1000;
    private static final Integer DISPATCH_MONTHS = 1;

    @isTest static void testBatch() {
        
        
        // Use Test Data Factory to create Account and related records
        List<Account> accountList = TestDataFactory.createAccountsWithMonths(1, ACCOUNT_FIRST_NUM);
        String accountNumber = accountList[0].SAP_Account_Number__c;

        // Create forecast and dispatch staging records
        List<Forecast__c> forecastList = TestDataFactory.createForecasts(FORECAST_NUM_BOTTLES, accountNumber,FORECAST_BUDGET, FORECAST_AMOUNT);
        
        
        List<Month__c> mList = [SELECT Id from Month__c LIMIT 2];
        delete mList;
        
        List<Dispatch_Staging__c> dispatchStagingList = TestDataFactory.createDispatchStaging(DISPATCH_MONTHS, accountNumber, HAULIER_NUM, NUM_BOTTLES, NUM_TONNES);

        // Start test
        Test.startTest();
        DispatchLoadSchedulable schedulableJob = new DispatchLoadSchedulable();
        schedulableJob.execute(null);
        Test.stopTest();
        

        // Retrieve counts for assertions
        Integer dispatchCount = [SELECT COUNT() FROM Dispatch__c];
        Integer forecastCount = [SELECT COUNT() FROM Forecast__c];
        Integer haulierCount = [SELECT COUNT() FROM Haulier__c];


        // Assertions
        //System.assertEquals(dispatchStagingList.size(), dispatchCount, 'Dispatch count mismatch');
        System.assertEquals(forecastList.size(), forecastCount, 'Forecast count mismatch');
        System.assertEquals(1, haulierCount, 'Haulier count mismatch');

    }
    
    

    @isTest static void testScheduler() {
        Test.startTest();
        DispatchLoadScheduler dispatchLoadScheduler = new DispatchLoadScheduler();
        String scheduleExpression = '0 0 23 * * ?';
        system.schedule('TestDispatchLoadScheduler', scheduleExpression, dispatchLoadScheduler);
        Test.stopTest();
    }
}


/*@isTest
private class TestDispatchLoadBatch  {
    private static String haulierNum = '1234';
    private static Integer numBottles = 200000;
    private static Integer numTonnes = 20;
 
    @isTest static void testBatch() {
        // create one Account
        List<Account> aList = TestDataFactory.createAccountsWithMonths(1, 10001);
        String acctNum = aList[0].SAP_Account_Number__c;
        
        // create 96 forecast records (8 x 12 months)
        List<Forecast__c> fList = TestDataFactory.createForecasts(8, acctNum, 800, 1000);
        
        //  // delete some months
        //  List<Month__c> mList = [SELECT Id from Month__c LIMIT 2];
        //  delete mList;
        
        // create 120 dispatch staging records (10 x 12 months)
        List<Dispatch_Staging__c> dList = TestDataFactory.createDispatchStaging(10, acctNum, haulierNum, numBottles, numTonnes);
        
        
        
        Test.startTest();
        DispatchLoadBatch dlb = new DispatchLoadBatch();
        ID jobId = Database.executeBatch(dlb);
        Test.stopTest();
        
        Integer dispatchCount = [select count() from Dispatch__c];
        Integer forecastCount = [select count() from Forecast__c];
        Integer haulierCount = [select count() from Haulier__c];
        
        //system.assertEquals(dispatchCount, 122);
        //system.assertEquals(forecastCount, 120);
        //system.assertEquals(haulierCount, 1);       
     }
    
    @isTest static void testScheduler() {
        Test.StartTest();
        DispatchLoadScheduler sh1 = new DispatchLoadScheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test check', sch, sh1);
        Test.stopTest();
    }
    
}*/