/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchStagingQueueableTest.cls
   Description: Test class for DispatchStagingQueueableTest.cls

   Date         Version Author              Summary of Changes
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Aug 2025		1.0		Globant				Initial Release
------------------------------------------------------------------------------------------------------------------------ */

@IsTest
private class DispatchStagingQueueableTest {
    
    private static final String EXISTING_UNIQUE_ID_1 = '24156-74191320';
    private static final String EXISTING_UNIQUE_ID_2 = '46271-89277194';
    private static final String NEW_UNIQUE_ID = '59102-90827711';
    
    private static Set<Id> getIds(List<Dispatch_Staging__c> records) {
        return new Map<Id, Dispatch_Staging__c>(records).keySet();
    }
    
    private static Dispatch_Staging__c getRecordByUniqueId(String uniqueId) {
        return [
            SELECT Id, Number_of_Material_Document__c, SAP_Material_Code__c, Salesforce_Unique_Id__c,
                   Customer_Name__c, Customer_Code__c, Haulier_Code__c, Bottles__c, Tonnage__c,
                   Dispatch_Time__c, Planned_Delivery_Time__c, Process_Status__c, Process_Error__c
            FROM Dispatch_Staging__c 
            WHERE Salesforce_Unique_Id__c = :uniqueId
            LIMIT 1
        ];
    }
    
    private static List<Dispatch_Staging__c> getRecordsByIds(Set<Id> ids) {
        return [
            SELECT Id, Process_Status__c, Process_Error__c 
            FROM Dispatch_Staging__c 
            WHERE Id IN :ids
        ];
    }
    
    @TestSetup
    static void setupData() {
        List<Dispatch_Staging__c> setupRecords = new List<Dispatch_Staging__c>{
            new Dispatch_Staging__c(
                Number_of_Material_Document__c = '24156',
                SAP_Material_Code__c = '74191320',
                Salesforce_Unique_Id__c = EXISTING_UNIQUE_ID_1,
                Customer_Name__c = 'Original Customer',
                Customer_Code__c = '24988',
                Haulier_Code__c = '62773',
                Process_Status__c = 'Success',
                Process_Error__c = 'Previously processed',
                Bottles__c = 1000,
                Tonnage__c = 50.5,
                Dispatch_Time__c = '10:00:00',
                Planned_Delivery_Time__c = '14:00:00'
            ),
            new Dispatch_Staging__c(
                Number_of_Material_Document__c = '46271',
                SAP_Material_Code__c = '89277194',
                Salesforce_Unique_Id__c = EXISTING_UNIQUE_ID_2,
                Customer_Name__c = 'Unchanged Customer',
                Customer_Code__c = '71223',
                Haulier_Code__c = '62784',
                Process_Status__c = 'Success',
                Process_Error__c = 'Completed successfully',
                Bottles__c = 2000,
                Tonnage__c = 75.0
            )
        };
        
        insert setupRecords;
        
        // Duplicate of record 2 for cleanup testing
        insert new Dispatch_Staging__c(
            Number_of_Material_Document__c = '46271',
            SAP_Material_Code__c = '89277194',
            Salesforce_Unique_Id__c = EXISTING_UNIQUE_ID_2,
            Customer_Name__c = 'Duplicate Record',
            Customer_Code__c = '71223',
            Process_Status__c = 'New'
        );
    }
    @IsTest
    static void testQueueableProcessing_CompleteScenario() {
        Test.startTest();
        List<Dispatch_Staging__c> newBatchRecords = new List<Dispatch_Staging__c>{
            // New record
            new Dispatch_Staging__c(
                Number_of_Material_Document__c = '59102',
                SAP_Material_Code__c = '90827711',
                Salesforce_Unique_Id__c = NEW_UNIQUE_ID,
                Customer_Name__c = 'Brand New Customer',
                Customer_Code__c = '62791',
                Haulier_Code__c = '90321',
                Bottles__c = 3000,
                Tonnage__c = 100.0,
                Dispatch_Time__c = '12:00:00'
            ),
            // Updated record
            new Dispatch_Staging__c(
                Number_of_Material_Document__c = '24156',
                SAP_Material_Code__c = '74191320',
                Salesforce_Unique_Id__c = EXISTING_UNIQUE_ID_1,
                Customer_Name__c = 'Updated Customer',
                Customer_Code__c = '24989',
                Haulier_Code__c = '62773',
                Bottles__c = 1500,
                Tonnage__c = 50.5,
                Dispatch_Time__c = '11:00:00',
                Planned_Delivery_Time__c = '15:00:00'
            ),
            // Unchanged record
            new Dispatch_Staging__c(
                Number_of_Material_Document__c = '46271',
                SAP_Material_Code__c = '89277194',
                Salesforce_Unique_Id__c = EXISTING_UNIQUE_ID_2,
                Customer_Name__c = 'Unchanged Customer',
                Customer_Code__c = '71223',
                Haulier_Code__c = '62784',
                Bottles__c = 2000,
                Tonnage__c = 75.0
            )
        };
        insert newBatchRecords;
        
        System.enqueueJob(new DispatchStagingQueueable(getIds(newBatchRecords)));
        Test.stopTest();
        
        // 1. New record
        Dispatch_Staging__c newRec = getRecordByUniqueId(NEW_UNIQUE_ID);
        System.assertEquals('New', newRec.Process_Status__c, 'New record should have New status');
        
        // 2. Updated record
        Dispatch_Staging__c updatedRec = getRecordByUniqueId(EXISTING_UNIQUE_ID_1);
        System.assertEquals('Updated Customer', updatedRec.Customer_Name__c);
        System.assertEquals('24989', updatedRec.Customer_Code__c);
        System.assertEquals(1500, updatedRec.Bottles__c);
        System.assertEquals('11:00:00', updatedRec.Dispatch_Time__c);
        System.assertEquals('15:00:00', updatedRec.Planned_Delivery_Time__c);
        System.assertEquals('New', updatedRec.Process_Status__c);
        
        // 3. Unchanged record (status must remain same)
        Dispatch_Staging__c unchangedRec = getRecordByUniqueId(EXISTING_UNIQUE_ID_2);
        System.assertEquals('New', unchangedRec.Process_Status__c);
        
        // Record count
        System.assertEquals(3, [SELECT COUNT() FROM Dispatch_Staging__c]);
    }
    
    @IsTest
    static void testQueueableProcessing_NewRecordsOnly() {
        List<Dispatch_Staging__c> newRecords = new List<Dispatch_Staging__c>();
        for (Integer i = 0; i < 5; i++) {
            newRecords.add(new Dispatch_Staging__c(
                Number_of_Material_Document__c = '7823' + i,
                SAP_Material_Code__c = '7418012' + i,
                Salesforce_Unique_Id__c = '7823' + i + '-7418012' + i,
                Customer_Name__c = 'New Customer ' + i,
                Bottles__c = 1000 + (i * 100)
            ));
        }
        insert newRecords;
        
        Test.startTest();
        System.enqueueJob(new DispatchStagingQueueable(getIds(newRecords)));
        Test.stopTest();
        
        for (Dispatch_Staging__c rec : getRecordsByIds(getIds(newRecords))) {
            System.assertEquals('New', rec.Process_Status__c);
        }
    }
    
    @IsTest
    static void testQueueableProcessing_EmptyRecordSet() {
        Test.startTest();
        System.enqueueJob(new DispatchStagingQueueable(new Set<Id>()));
        Test.stopTest();
        
        System.assertEquals(2, [SELECT COUNT() FROM Dispatch_Staging__c]);
    }
    
    @IsTest
    static void testQueueableProcessing_NullUniqueIds() {
        Dispatch_Staging__c rec = new Dispatch_Staging__c(
            Number_of_Material_Document__c = '',
            SAP_Material_Code__c = '',
            Customer_Name__c = ''
        );
        insert rec;
        
        Test.startTest();
        System.enqueueJob(new DispatchStagingQueueable(new Set<Id>{rec.Id}));
        Test.stopTest();
        
        System.assertEquals(1, 
            [SELECT COUNT() FROM Dispatch_Staging__c WHERE Number_of_Material_Document__c = ''], 
            'Record with null unique ID should remain');
    }
    
    @IsTest
    static void testBulkProcessing() {
        List<Dispatch_Staging__c> bulkRecords = new List<Dispatch_Staging__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkRecords.add(new Dispatch_Staging__c(
                Number_of_Material_Document__c = '23101' + String.valueOf(i).leftPad(4, '0'),
                SAP_Material_Code__c = '80214024' + String.valueOf(i).leftPad(4, '0'),
                Salesforce_Unique_Id__c = '23101' + String.valueOf(i).leftPad(4, '0') + '-80214024' + String.valueOf(i).leftPad(4, '0'),
                Customer_Name__c = 'Bulk Customer ' + i,
                Bottles__c = 1000 + i,
                Tonnage__c = 50.0 + i
            ));
        }
        insert bulkRecords;
        
        Test.startTest();
        System.enqueueJob(new DispatchStagingQueueable(getIds(bulkRecords)));
        Test.stopTest();
        
        Integer processedCount = [
            SELECT COUNT() 
            FROM Dispatch_Staging__c 
            WHERE Process_Status__c = 'New' AND Customer_Name__c LIKE 'Bulk Customer%'
        ];
        System.assertEquals(200, processedCount);
    }
    
    @IsTest
    static void testFieldComparison_AllFieldTypes() {
        Dispatch_Staging__c newRecord = new Dispatch_Staging__c(
            Number_of_Material_Document__c = '24156',
            SAP_Material_Code__c = '74191320',
            Salesforce_Unique_Id__c = EXISTING_UNIQUE_ID_1,
            Customer_Name__c = 'Original Customer',
            Customer_Code__c = '24988',
            Haulier_Code__c = '62773',
            Bottles__c = 1000,
            Tonnage__c = 50.5,
            Dispatch_Time__c = '10:00:00',
            Planned_Delivery_Time__c = '14:00:00',
            Dispatch_Date__c = Date.today(),
            Planned_Date_for_End_of_Shipment__c = Date.today().addDays(1),
            Current_Date_for_Start_of_Loading__c = Date.today()
        );
        insert newRecord;
        
        Test.startTest();
        System.enqueueJob(new DispatchStagingQueueable(new Set<Id>{newRecord.Id}));
        Test.stopTest();
        
        List<Dispatch_Staging__c> remaining = [
            SELECT Id FROM Dispatch_Staging__c WHERE Salesforce_Unique_Id__c = :EXISTING_UNIQUE_ID_1
        ];
        System.assertEquals(1, remaining.size());
    }
    
    @IsTest
    static void testErrorHandling() {
        Dispatch_Staging__c rec = new Dispatch_Staging__c(
            Number_of_Material_Document__c = '16274',
            SAP_Material_Code__c = '16274',
            Salesforce_Unique_Id__c = '16274-16274',
            Customer_Name__c = 'Test Customer'
        );
        insert rec;
        
        Test.startTest();
        new DispatchStagingQueueable(new Set<Id>{rec.Id}).processUpsertLogic();
        Test.stopTest();
        
        System.assertEquals(1, 
            [SELECT COUNT() FROM Dispatch_Staging__c WHERE Salesforce_Unique_Id__c = '16274-16274']);
    }
}
