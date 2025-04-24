/* -----------------------------------------------------------------------------------------------------------------------
   Name:        TestRiskUpsideApproval.cls
   Description: Test transfer of approved Risk/Upside record values to Month Revised Forecasts
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Dec 2017     1.0     M.Witchalls(Ciber)  Initial Release 
------------------------------------------------------------------------------------------------------------------------ */        
@isTest
private class TestRiskUpsideApproval {
    private static String rowCause = 'Apex__c';
    private static String encircProfile = 'Encirc Standard User';
    private static List<User> encircUsers = [SELECT Id FROM User WHERE Profile.Name = :encircProfile AND IsActive = true LIMIT 2];
    private static String approvedRecordType = 'Approved_Rejected';
     
    @isTest static void testRiskUpside() {  
        // create one Account with 12 Month Forecasts
        List<Account> aList = TestDataFactory.createAccountsWithMonths(1, 10001); 
        List<Month__c> mList = aList[0].Months__r;
        
        String objectName = Schema.SObjectType.Forecast_Risk_Upside__c.Name;
        Schema.DescribeFieldResult fr = Schema.SObjectType.Forecast_Risk_Upside__c.fields.Approval_Status__c;
        String status = fr.getPickListValues()[0].getValue();
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = :objectName AND DeveloperName = :approvedRecordType];
        
        // create some Risk/Upside records
        List<Forecast_Risk_Upside__c> fruList = new List<Forecast_Risk_Upside__c>();
        for (Month__c m: mList) {
            Forecast_Risk_Upside__c fru = new Forecast_Risk_Upside__c(
                Approval_Status__c = status,
                Month__c = m.Id,
                Risks__c = 300,
                Upsides__c = 500
            );
            fruList.add(fru);
        }
        insert fruList;
        
        // Approve them
        for (Forecast_Risk_Upside__c fru: fruList) {
            fru.RecordTypeId = rt.Id;
            fru.Approval_Status__c = 'Approved';
        }
        update fruList;
        
        Month__c m = [SELECT Id, Revised_Forecast__c FROM Month__c WHERE Id = :mList[0].Id];
        
        //system.assertEquals(200, m.Revised_Forecast__c);              
    }   
    
}