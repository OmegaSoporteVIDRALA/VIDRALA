@isTest
private class DispatchStagingHandlerTest {
    // Declare parameters to avoid hardcoding
    private static final String HAULIER_NUM = '1234';
    private static final Integer NUM_BOTTLES = 200000;
    private static final Integer NUM_TONNES = 20;
    private static final Integer ACCOUNT_MONTHS = 10001;
    private static final Integer FORECAST_MONTHS = 8;
    private static final Integer FORECAST_MIN_VALUE = 800;
    private static final Integer FORECAST_MAX_VALUE = 1000;
    private static final Integer DISPATCH_MONTHS = 8;

    @isTest static void itShouldDispatchStagingHandler() {

        // Use Test Data Factory to create Account and related records
        List<Account> accountList = TestDataFactory.createAccountsWithMonths(1, ACCOUNT_MONTHS);
        String accountNumber = accountList[0].SAP_Account_Number__c;

        // Create forecast and dispatch staging records
        List<Forecast__c> forecastList = TestDataFactory.createForecasts(FORECAST_MONTHS, accountNumber, FORECAST_MIN_VALUE, FORECAST_MAX_VALUE);
        
        
        List<Month__c> mList = [SELECT Id from Month__c LIMIT 2];
        delete mList;
        
        List<Dispatch_Staging__c> dispatchStagingList = TestDataFactory.createDispatchStaging(DISPATCH_MONTHS, accountNumber, HAULIER_NUM, NUM_BOTTLES, NUM_TONNES);
        for (Dispatch_Staging__c ds : dispatchStagingList) {
            
            ds.Dispatch_ID__c = '0009991';
            ds.Haulier_Code__c = '0';
            ds.SAP_Material_Code__c = 'xxyy' + ds.Dispatch_ID__c;
            ds.Dispatch_Time__c = '11:00:00';
        }
        update dispatchStagingList;

        // Start test
        Test.startTest();
        DispatchStagingHandler dispatchStagingHandler = new DispatchStagingHandler();
        dispatchStagingHandler.handleSpuriousDups(dispatchStagingList);
        Test.stopTest();
        

        // Retrieve counts for assertions
        Integer haulierCount = [SELECT COUNT() FROM Haulier__c];

        // Assertion
        System.assertEquals(0, haulierCount, 'Haulier count mismatch');
    }
}