/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchStagingQueueableTest.cls
   Description: Test class for DispatchStagingQueueableTest.cls

   Date         Version Author              Summary of Changes
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Aug 2025		1.0		Globant				Initial Release
------------------------------------------------------------------------------------------------------------------------ */

@IsTest
private class DispatchStagingQueueableTest {
    
    @TestSetup
    static void setupData() {
        insert new Dispatch_Staging__c(
            Number_of_Material_Document__c = '12345',
            SAP_Material_Code__c          = '74191320',
            Salesforce_Unique_Id__c       = '12345-74191320',
            Customer_Name__c              = 'Old Customer'
        );
        
        insert new Dispatch_Staging__c(
            Number_of_Material_Document__c = '17828',
            SAP_Material_Code__c          = '84910123',
            Salesforce_Unique_Id__c       = '17828-84910123',
            Customer_Name__c              = 'Same Customer'
        );
        
        insert new Dispatch_Staging__c(
            Number_of_Material_Document__c = '17828',
            SAP_Material_Code__c          = '84910123',
            Salesforce_Unique_Id__c       = '17828-84910123',
            Customer_Name__c              = 'Duplicate'
        );
    }
    
    @IsTest
    static void testQueueableProcessing() {
        
        List<Dispatch_Staging__c> newBatchRecords = new List<Dispatch_Staging__c>{
            // new record
            new Dispatch_Staging__c(
                Number_of_Material_Document__c = '89427',
                SAP_Material_Code__c          = '12384915',
                Salesforce_Unique_Id__c       = '89427-12384915',
                Customer_Name__c              = 'New Customer'
            ),
                // Matches existing record but with updated data
                new Dispatch_Staging__c(
                    Number_of_Material_Document__c = '12345',
                    SAP_Material_Code__c          = '74191320',
                    Salesforce_Unique_Id__c       = '12345-74191320',
                    Customer_Name__c              = 'Updated Customer'
                ),
                // Matches existing record with no data changes
                new Dispatch_Staging__c(
                    Number_of_Material_Document__c = '17828',
                    SAP_Material_Code__c          = '84910123',
                    Salesforce_Unique_Id__c       = '17828-84910123',
                    Customer_Name__c              = 'Same Customer'
                )
                };
                    insert newBatchRecords;
        
        // IDs for queueable
        Set<Id> newRecordIds = new Map<Id, Dispatch_Staging__c>(
            [SELECT Id FROM Dispatch_Staging__c WHERE Id IN :newBatchRecords]
        ).keySet();
        
        Test.startTest();
        System.enqueueJob(new DispatchStagingQueueable(newRecordIds));
        Test.stopTest();
        
        
        // New record should still exist
        System.assertEquals(1,[SELECT COUNT() FROM Dispatch_Staging__c WHERE Salesforce_Unique_Id__c = '89427-12384915'],'New record should be kept');
        
        // Existing record updated, new record removed
        Dispatch_Staging__c rec = [
            SELECT Customer_Name__c, Process_Status__c
            FROM Dispatch_Staging__c
            WHERE Salesforce_Unique_Id__c = '12345-74191320'
            LIMIT 1
        ];
        System.assertEquals('Updated Customer', rec.Customer_Name__c, 'Data should be updated');
        System.assertEquals('New', rec.Process_Status__c, 'Status should reset to New');
        System.assertEquals(1,[SELECT COUNT() FROM Dispatch_Staging__c WHERE Salesforce_Unique_Id__c = '12345-74191320'],'Only one record should remain');
        
        System.assertEquals(1,[SELECT COUNT() FROM Dispatch_Staging__c WHERE Salesforce_Unique_Id__c = '17828-84910123'],'Only one record should remain after cleanup');
    }
}