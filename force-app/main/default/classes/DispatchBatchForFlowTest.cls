@isTest
private class DispatchBatchForFlowTest {
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
        //DispatchBatchForFlow dlb = new DispatchBatchForFlow();
        DispatchBatchForFlow.runBatch();
        Test.stopTest();
        
        Integer dispatchCount = [select count() from Dispatch__c];
        Integer forecastCount = [select count() from Forecast__c];
        Integer haulierCount = [select count() from Haulier__c];
        
        //system.assertEquals(dispatchCount, 122);
        //system.assertEquals(forecastCount, 120);
        //system.assertEquals(haulierCount, 1);       
     }
}