/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchStagingQueueableTest.cls
   Description: Test class for DispatchStagingQueueableTest.cls

   Date         Version Author              Summary of Changes
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Aug 2025		1.0		Globant				Initial Release
------------------------------------------------------------------------------------------------------------------------ */

@IsTest
private class DispatchStagingQueueableTest {
    
    private static String unique5Digit(Integer i) {
        return String.valueOf(10000 + i);
    }
    private static String unique8Digit(Integer i) {
        return String.valueOf(10000000 + i);
    }
    private static Dispatch_Staging__c makeRecord(Integer i, String name) {
        String numDoc = unique5Digit(i);
        String sap = unique8Digit(i);
        return new Dispatch_Staging__c(
            Number_of_Material_Document__c = numDoc,
            SAP_Material_Code__c = sap,
            Salesforce_Unique_Id__c = numDoc + '-' + sap,
            Customer_Name__c = name
        );
    }
    
    @TestSetup
    static void setupData() {
        List<Dispatch_Staging__c> setupRecords = new List<Dispatch_Staging__c>();
        
        Dispatch_Staging__c rec1 = makeRecord(1, 'Original Customer Name');
        rec1.Customer_Code__c = '24988';
        rec1.Haulier_Code__c = '62773';
        rec1.Process_Status__c = 'Success';
        rec1.Process_Error__c = 'Previously processed';
        rec1.Bottles__c = 1000;
        rec1.Tonnage__c = 50.5;
        rec1.Dispatch_Time__c = '10:00:00';
        rec1.Planned_Delivery_Time__c = '14:00:00';
        setupRecords.add(rec1);
        
        Dispatch_Staging__c rec2 = makeRecord(2, 'Unchanged Customer Name');
        rec2.Customer_Code__c = '71223';
        rec2.Haulier_Code__c = '62784';
        rec2.Process_Status__c = 'Success';
        rec2.Process_Error__c = 'Processed successfully';
        rec2.Bottles__c = 2000;
        rec2.Tonnage__c = 75.0;
        setupRecords.add(rec2);
        
        insert setupRecords;
        
        insert new Dispatch_Staging__c(
            Number_of_Material_Document__c = rec2.Number_of_Material_Document__c,
            SAP_Material_Code__c = rec2.SAP_Material_Code__c,
            Salesforce_Unique_Id__c = rec2.Number_of_Material_Document__c + '-' + rec2.SAP_Material_Code__c,
            Customer_Name__c = 'Duplicate Record',
            Customer_Code__c = '71223',
            Process_Status__c = 'New'
        );
    }
    
    @IsTest
    static void testQueueableProcessing_CompleteScenario() {
        Test.startTest();
        
        List<Dispatch_Staging__c> newBatch = new List<Dispatch_Staging__c>();
        
        newBatch.add(makeRecord(3, 'Brand New Customer'));
        
        Dispatch_Staging__c updated = makeRecord(1, 'Updated Customer Name');
        updated.Customer_Code__c = '24989';
        updated.Haulier_Code__c = '62773';
        updated.Bottles__c = 1500;
        updated.Dispatch_Time__c = '11:00:00';
        updated.Planned_Delivery_Time__c = '15:00:00';
        newBatch.add(updated);
        
        Dispatch_Staging__c unchanged = makeRecord(2, 'Unchanged Customer Name');
        unchanged.Customer_Code__c = '71223';
        unchanged.Haulier_Code__c = '62784';
        unchanged.Bottles__c = 2000;
        unchanged.Tonnage__c = 75.0;
        newBatch.add(unchanged);
        
        insert newBatch;
        
        System.enqueueJob(new DispatchStagingQueueable(
            new Map<Id, Dispatch_Staging__c>(newBatch).keySet()
        ));
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, [
            SELECT COUNT() FROM Dispatch_Staging__c WHERE Customer_Name__c = 'Brand New Customer'
        ]);
        
        Dispatch_Staging__c rec1 = [
            SELECT Customer_Name__c, Customer_Code__c, Bottles__c, Dispatch_Time__c, Planned_Delivery_Time__c, Process_Status__c
            FROM Dispatch_Staging__c
            WHERE Salesforce_Unique_Id__c = :unique5Digit(1) + '-' + unique8Digit(1)
            LIMIT 1
        ];
        System.assertEquals('Updated Customer Name', rec1.Customer_Name__c);
        System.assertEquals('24989', rec1.Customer_Code__c);
        System.assertEquals(1500, rec1.Bottles__c);
        System.assertEquals('11:00:00', rec1.Dispatch_Time__c);
        System.assertEquals('15:00:00', rec1.Planned_Delivery_Time__c);
        System.assertEquals('New', rec1.Process_Status__c);
        
        Integer count2 = [
            SELECT COUNT() FROM Dispatch_Staging__c
            WHERE Salesforce_Unique_Id__c = :unique5Digit(2) + '-' + unique8Digit(2)
        ];
        System.assertEquals(1, count2);
    }
    
    @IsTest
    static void testQueueableProcessing_NewRecordsOnly() {
        List<Dispatch_Staging__c> records = new List<Dispatch_Staging__c>();
        for (Integer i = 10; i < 15; i++) {
            records.add(makeRecord(i, 'New Customer ' + i));
        }
        insert records;
        
        Test.startTest();
        System.enqueueJob(new DispatchStagingQueueable(
            new Map<Id, Dispatch_Staging__c>(records).keySet()
        ));
        Test.stopTest();
        
        for (Dispatch_Staging__c rec : [
            SELECT Process_Status__c FROM Dispatch_Staging__c WHERE Id IN :records
        ]) {
            System.assertEquals('New', rec.Process_Status__c);
        }
    }
    
    @IsTest
    static void testQueueableProcessing_EmptyRecordSet() {
        Test.startTest();
        System.enqueueJob(new DispatchStagingQueueable(new Set<Id>()));
        Test.stopTest();
        System.assertEquals(true, [SELECT COUNT() FROM Dispatch_Staging__c] > 0);
    }
    
    @IsTest
    static void testQueueableProcessing_NullUniqueIds() {
        Dispatch_Staging__c rec = new Dispatch_Staging__c(
            Number_of_Material_Document__c = '',
            SAP_Material_Code__c = '',
            Customer_Name__c = 'Null Test'
        );
        insert rec;
        Test.startTest();
        System.enqueueJob(new DispatchStagingQueueable(new Set<Id>{rec.Id}));
        Test.stopTest();
        System.assertEquals(1, [
            SELECT COUNT() FROM Dispatch_Staging__c WHERE Id = :rec.Id
        ]);
    }
    
    @IsTest
    static void testBulkProcessing() {
        List<Dispatch_Staging__c> bulkrec = new List<Dispatch_Staging__c>();
        for (Integer i = 20; i < 220; i++) {
            bulkrec.add(makeRecord(i, 'Bulk Customer ' + i));
        }
        insert bulkrec;
        
        Set<Id> bulkIds = new Set<Id>();
        for (Dispatch_Staging__c rec : bulkrec) {
            bulkIds.add(rec.Id);
        }
        
        Test.startTest();
        System.enqueueJob(new DispatchStagingQueueable(bulkIds));
        Test.stopTest();
        
        Integer processed = [
            SELECT COUNT()
            FROM Dispatch_Staging__c
            WHERE Customer_Name__c LIKE 'Bulk Customer%'
            AND Process_Status__c = 'New'
        ];
        System.assertEquals(200, processed);
    }
}
