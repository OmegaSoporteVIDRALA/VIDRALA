/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchStagingQueueable.cls
   Description: Queueable class to perform custom upsert on Dispatch_Staging__c object 
   
   Date         Version Author              Summary of Changes
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Aug 2025		1.0		Globant				Initial Release
------------------------------------------------------------------------------------------------------------------------ */
public class DispatchStagingQueueable implements Queueable {
    private Set<Id> newRecordIds;
    
    public DispatchStagingQueueable(Set<Id> recordIds) {
        this.newRecordIds = recordIds;
    }
    
    public void execute(QueueableContext context) {
        processUpsertLogic();
    }
    
    @TestVisible
    private void processUpsertLogic() {
        // Get all newly inserted records with all fields
        List<Dispatch_Staging__c> newRecords = [
            SELECT Id, SAP_Material_Code__c, Number_of_Material_Document__c,
                   Salesforce_Unique_Id__c, CreatedDate, Haulier_Code__c, Freight_Reference__c,
                   Current_Date_for_Start_of_Loading__c, Delivery_Code__c, Scheduling_End_Time__c,
                   Bottle_Identifier__c, Sales_Document__c, Pack_Specification__c, Actual_Loading_Start_Time__c,
                   Planned_Date_for_End_of_Shipment__c, Purchasing_Document_Number__c, Series__c,
                   Haulier_Name__c, Delivery_Name__c, Record_Creation_Date__c, Planned_Loading_End_Time__c,
                   Current_Date_for_Start_of_Shipment__c, Planned_Date_for_Start_of_Loading__c, Dispatch_Time__c,
                   Bottle_Description__c, Trailer_Plate_Number__c, Customer_Code__c, Actual_Loading_End_Time__c,
                   Material_Document_Year__c, Sales_Organization__c, Item__c, Planned_Transport_End_Time__c,
                   Current_Date_of_Shipment_Completion__c, Overall_Transportation_Status__c, Actual_Date_of_Check_In__c,
                   Customer_Name__c, Planned_Loading_Start_Time__c, Actual_Shipment_End_Time__c, Actual_Transport_Start_Time__c,
                   Planned_Transport_Start_Time__c, SAP_Model_Number__c, End_of_Planning_Date__c, Bottles__c,
                   Tonnage__c, Plate_Number__c, Time_of_Transportation_Processing__c, Planned_Date_of_Check_In__c,
                   Actual_Date_for_End_of_Shipment__c, Entry_Time__c, Dispatch_ID__c, Planned_Check_In_Time__c,
                   Planned_Time_for_Processing__c, Planned_Date_for_End_of_Loading__c, Dispatch_Date__c,
                   Store__c, Planned_Delivery_Time__c, Type__c, Batch_Number__c,
                   Planned_Date_for_Shipment_Completion__c, Planned_Date_for_Start_of_Shipment__c, Planned_Delivery_Date__c,
                   Current_Time_of_Check_In__c, Shipment_Number__c, Actual_Date_for_End_of_Loading__c, Site_ID__c
            FROM Dispatch_Staging__c 
            WHERE Id IN :newRecordIds
            AND Salesforce_Unique_Id__c != null
        ];
        
        if(newRecords.isEmpty()) return;
        
        Set<String> uniqueIds = new Set<String>();
        Map<String, Dispatch_Staging__c> uniqueIdToNewRecordMap = new Map<String, Dispatch_Staging__c>();
        
        for(Dispatch_Staging__c newRecord : newRecords) {
            uniqueIds.add(newRecord.Salesforce_Unique_Id__c);
            uniqueIdToNewRecordMap.put(newRecord.Salesforce_Unique_Id__c, newRecord);
        }
        
        // Find existing records with same unique IDs
        Map<String, Dispatch_Staging__c> existingRecordsMap = new Map<String, Dispatch_Staging__c>();
        for(Dispatch_Staging__c existing : [
            SELECT Id, Salesforce_Unique_Id__c, CreatedDate, Process_Status__c, Process_Error__c, 
                   Process_Date__c, Process_Job__c, Number_of_Material_Document__c,
                   SAP_Material_Code__c, Haulier_Code__c, Freight_Reference__c, Current_Date_for_Start_of_Loading__c,
                   Delivery_Code__c, Scheduling_End_Time__c, Bottle_Identifier__c, Sales_Document__c,
                   Pack_Specification__c, Actual_Loading_Start_Time__c, Planned_Date_for_End_of_Shipment__c,
                   Purchasing_Document_Number__c, Series__c, Haulier_Name__c, Delivery_Name__c,
                   Record_Creation_Date__c, Planned_Loading_End_Time__c, Current_Date_for_Start_of_Shipment__c,
                   Planned_Date_for_Start_of_Loading__c, Dispatch_Time__c, Bottle_Description__c,
                   Trailer_Plate_Number__c, Customer_Code__c, Actual_Loading_End_Time__c, Material_Document_Year__c,
                   Sales_Organization__c, Item__c, Planned_Transport_End_Time__c, Current_Date_of_Shipment_Completion__c,
                   Overall_Transportation_Status__c, Actual_Date_of_Check_In__c, Customer_Name__c,
                   Planned_Loading_Start_Time__c, Actual_Shipment_End_Time__c, Actual_Transport_Start_Time__c,
                   Planned_Transport_Start_Time__c, SAP_Model_Number__c, End_of_Planning_Date__c, Bottles__c,
                   Tonnage__c, Plate_Number__c, Time_of_Transportation_Processing__c, Planned_Date_of_Check_In__c,
                   Actual_Date_for_End_of_Shipment__c, Entry_Time__c, Dispatch_ID__c, Planned_Check_In_Time__c,
                   Planned_Time_for_Processing__c, Planned_Date_for_End_of_Loading__c, Dispatch_Date__c,
                   Store__c, Planned_Delivery_Time__c, Type__c, Batch_Number__c, Planned_Date_for_Shipment_Completion__c, 
                   Planned_Date_for_Start_of_Shipment__c, Planned_Delivery_Date__c,
                   Current_Time_of_Check_In__c, Shipment_Number__c, Actual_Date_for_End_of_Loading__c, Site_ID__c
            FROM Dispatch_Staging__c 
            WHERE Salesforce_Unique_Id__c IN :uniqueIds
            AND Id NOT IN :newRecordIds
            ORDER BY CreatedDate ASC
        ]) {
            if(!existingRecordsMap.containsKey(existing.Salesforce_Unique_Id__c)) {
                existingRecordsMap.put(existing.Salesforce_Unique_Id__c, existing);
            }
        }
        
        List<Dispatch_Staging__c> existingRecordsToUpdate = new List<Dispatch_Staging__c>();
        List<Dispatch_Staging__c> newRecordsToDelete = new List<Dispatch_Staging__c>();
        List<Dispatch_Staging__c> newRecordsToKeep = new List<Dispatch_Staging__c>();
        
        // Process each unique ID
        for(String uniqueId : uniqueIds) {
            Dispatch_Staging__c newRecord = uniqueIdToNewRecordMap.get(uniqueId);
            
            if(existingRecordsMap.containsKey(uniqueId)) {
                Dispatch_Staging__c existingRecord = existingRecordsMap.get(uniqueId);
                
                boolean hasChanges = hasDataChanged(newRecord, existingRecord);
                
                if(hasChanges) {
                    String originalStatus = existingRecord.Process_Status__c;
                    
                    copyAllFieldValues(newRecord, existingRecord);
                    
                    existingRecord.Process_Status__c = 'New';
                    existingRecord.Process_Error__c = 'Record updated from data load at ' + System.now() + 
                                                     ' (Previous status: ' + originalStatus + ')';
                    
                    existingRecordsToUpdate.add(existingRecord);
                    newRecordsToDelete.add(newRecord);
                    
                    System.debug('Data changed for unique ID: ' + uniqueId + 
                               '. Updated existing record ID: ' + existingRecord.Id + 
                               '. Reset status from ' + originalStatus + ' to New for reprocessing.');
                } else {

                    newRecordsToDelete.add(newRecord);
                    
                    System.debug('No data changes for unique ID: ' + uniqueId + 
                               '. Existing record ID: ' + existingRecord.Id + 
                               ' remains unchanged with status: ' + existingRecord.Process_Status__c);
                }
                
            } else {
                newRecord.Process_Status__c = 'New';
                newRecord.Process_Error__c = '';
                newRecordsToKeep.add(newRecord);
                
                System.debug('No existing record found for unique ID: ' + uniqueId + 
                           '. Keeping new record ID: ' + newRecord.Id + ' with status: New');
            }
        }
        
        try {
            if(!existingRecordsToUpdate.isEmpty()) {
                update existingRecordsToUpdate;
                System.debug('Successfully updated ' + existingRecordsToUpdate.size() + 
                           ' existing records with data changes');
            }
            
            if(!newRecordsToDelete.isEmpty()) {
                delete newRecordsToDelete;
                System.debug('Successfully deleted ' + newRecordsToDelete.size() + ' duplicate new records');
            }
            
            if(!newRecordsToKeep.isEmpty()) {
                List<Dispatch_Staging__c> newRecordsToUpdate = new List<Dispatch_Staging__c>();
                for(Dispatch_Staging__c newRecord : newRecordsToKeep) {
                    if(String.isBlank(newRecord.Process_Status__c) || newRecord.Process_Status__c != 'New') {
                        newRecord.Process_Status__c = 'New';
                        newRecord.Process_Error__c = '';
                        newRecordsToUpdate.add(newRecord);
                    }
                }
                
                if(!newRecordsToUpdate.isEmpty()) {
                    update newRecordsToUpdate;
                    System.debug('Updated ' + newRecordsToUpdate.size() + ' new records to ensure New status');
                }
            }
            
            cleanupSystemDuplicates(uniqueIds);
            
            Integer totalInserted = newRecordsToKeep.size();
            Integer totalUpdated = existingRecordsToUpdate.size();
            Integer totalSkipped = newRecordsToDelete.size() - existingRecordsToUpdate.size();
            
            System.debug('New Records Inserted: ' + totalInserted);
            System.debug('Existing Records Updated (Data Changed): ' + totalUpdated);
            System.debug('Records Skipped (No Changes): ' + totalSkipped);
            System.debug('Total Records Processed: ' + (totalInserted + totalUpdated + totalSkipped));
            
        } catch(Exception e) {
            System.debug('Error in upsert processing: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
    
    /**
     * Compare all fields to detect if data has changed
     * Returns true if any field value is different between new and existing record
     */
    private boolean hasDataChanged(Dispatch_Staging__c newRecord, Dispatch_Staging__c existingRecord) {

        return (
            !isEqual(newRecord.Number_of_Material_Document__c, existingRecord.Number_of_Material_Document__c) ||
            !isEqual(newRecord.SAP_Material_Code__c, existingRecord.SAP_Material_Code__c) ||
            !isEqual(newRecord.Haulier_Code__c, existingRecord.Haulier_Code__c) ||
            !isEqual(newRecord.Freight_Reference__c, existingRecord.Freight_Reference__c) ||
            !isEqual(newRecord.Current_Date_for_Start_of_Loading__c, existingRecord.Current_Date_for_Start_of_Loading__c) ||
            !isEqual(newRecord.Delivery_Code__c, existingRecord.Delivery_Code__c) ||
            !isEqual(newRecord.Scheduling_End_Time__c, existingRecord.Scheduling_End_Time__c) ||
            !isEqual(newRecord.Bottle_Identifier__c, existingRecord.Bottle_Identifier__c) ||
            !isEqual(newRecord.Sales_Document__c, existingRecord.Sales_Document__c) ||
            !isEqual(newRecord.Pack_Specification__c, existingRecord.Pack_Specification__c) ||
            !isEqual(newRecord.Actual_Loading_Start_Time__c, existingRecord.Actual_Loading_Start_Time__c) ||
            !isEqual(newRecord.Planned_Date_for_End_of_Shipment__c, existingRecord.Planned_Date_for_End_of_Shipment__c) ||
            !isEqual(newRecord.Purchasing_Document_Number__c, existingRecord.Purchasing_Document_Number__c) ||
            !isEqual(newRecord.Series__c, existingRecord.Series__c) ||
            !isEqual(newRecord.Haulier_Name__c, existingRecord.Haulier_Name__c) ||
            !isEqual(newRecord.Delivery_Name__c, existingRecord.Delivery_Name__c) ||
            !isEqual(newRecord.Record_Creation_Date__c, existingRecord.Record_Creation_Date__c) ||
            !isEqual(newRecord.Planned_Loading_End_Time__c, existingRecord.Planned_Loading_End_Time__c) ||
            !isEqual(newRecord.Current_Date_for_Start_of_Shipment__c, existingRecord.Current_Date_for_Start_of_Shipment__c) ||
            !isEqual(newRecord.Planned_Date_for_Start_of_Loading__c, existingRecord.Planned_Date_for_Start_of_Loading__c) ||
            !isEqual(newRecord.Dispatch_Time__c, existingRecord.Dispatch_Time__c) ||
            !isEqual(newRecord.Bottle_Description__c, existingRecord.Bottle_Description__c) ||
            !isEqual(newRecord.Trailer_Plate_Number__c, existingRecord.Trailer_Plate_Number__c) ||
            !isEqual(newRecord.Customer_Code__c, existingRecord.Customer_Code__c) ||
            !isEqual(newRecord.Actual_Loading_End_Time__c, existingRecord.Actual_Loading_End_Time__c) ||
            !isEqual(newRecord.Material_Document_Year__c, existingRecord.Material_Document_Year__c) ||
            !isEqual(newRecord.Sales_Organization__c, existingRecord.Sales_Organization__c) ||
            !isEqual(newRecord.Item__c, existingRecord.Item__c) ||
            !isEqual(newRecord.Planned_Transport_End_Time__c, existingRecord.Planned_Transport_End_Time__c) ||
            !isEqual(newRecord.Current_Date_of_Shipment_Completion__c, existingRecord.Current_Date_of_Shipment_Completion__c) ||
            !isEqual(newRecord.Overall_Transportation_Status__c, existingRecord.Overall_Transportation_Status__c) ||
            !isEqual(newRecord.Actual_Date_of_Check_In__c, existingRecord.Actual_Date_of_Check_In__c) ||
            !isEqual(newRecord.Customer_Name__c, existingRecord.Customer_Name__c) ||
            !isEqual(newRecord.Planned_Loading_Start_Time__c, existingRecord.Planned_Loading_Start_Time__c) ||
            !isEqual(newRecord.Actual_Shipment_End_Time__c, existingRecord.Actual_Shipment_End_Time__c) ||
            !isEqual(newRecord.Actual_Transport_Start_Time__c, existingRecord.Actual_Transport_Start_Time__c) ||
            !isEqual(newRecord.Planned_Transport_Start_Time__c, existingRecord.Planned_Transport_Start_Time__c) ||
            !isEqual(newRecord.SAP_Model_Number__c, existingRecord.SAP_Model_Number__c) ||
            !isEqual(newRecord.End_of_Planning_Date__c, existingRecord.End_of_Planning_Date__c) ||
            !isEqual(newRecord.Bottles__c, existingRecord.Bottles__c) ||
            !isEqual(newRecord.Tonnage__c, existingRecord.Tonnage__c) ||
            !isEqual(newRecord.Plate_Number__c, existingRecord.Plate_Number__c) ||
            !isEqual(newRecord.Time_of_Transportation_Processing__c, existingRecord.Time_of_Transportation_Processing__c) ||
            !isEqual(newRecord.Planned_Date_of_Check_In__c, existingRecord.Planned_Date_of_Check_In__c) ||
            !isEqual(newRecord.Actual_Date_for_End_of_Shipment__c, existingRecord.Actual_Date_for_End_of_Shipment__c) ||
            !isEqual(newRecord.Entry_Time__c, existingRecord.Entry_Time__c) ||
            !isEqual(newRecord.Dispatch_ID__c, existingRecord.Dispatch_ID__c) ||
            !isEqual(newRecord.Planned_Check_In_Time__c, existingRecord.Planned_Check_In_Time__c) ||
            !isEqual(newRecord.Planned_Time_for_Processing__c, existingRecord.Planned_Time_for_Processing__c) ||
            !isEqual(newRecord.Planned_Date_for_End_of_Loading__c, existingRecord.Planned_Date_for_End_of_Loading__c) ||
            !isEqual(newRecord.Dispatch_Date__c, existingRecord.Dispatch_Date__c) ||
            !isEqual(newRecord.Store__c, existingRecord.Store__c) ||
            !isEqual(newRecord.Planned_Delivery_Time__c, existingRecord.Planned_Delivery_Time__c) ||
            !isEqual(newRecord.Type__c, existingRecord.Type__c) ||
            !isEqual(newRecord.Batch_Number__c, existingRecord.Batch_Number__c) ||
            !isEqual(newRecord.Planned_Date_for_Shipment_Completion__c, existingRecord.Planned_Date_for_Shipment_Completion__c) ||
            !isEqual(newRecord.Planned_Date_for_Start_of_Shipment__c, existingRecord.Planned_Date_for_Start_of_Shipment__c) ||
            !isEqual(newRecord.Planned_Delivery_Date__c, existingRecord.Planned_Delivery_Date__c) ||
            !isEqual(newRecord.Current_Time_of_Check_In__c, existingRecord.Current_Time_of_Check_In__c) ||
            !isEqual(newRecord.Shipment_Number__c, existingRecord.Shipment_Number__c) ||
            !isEqual(newRecord.Actual_Date_for_End_of_Loading__c, existingRecord.Actual_Date_for_End_of_Loading__c) ||
            !isEqual(newRecord.Site_ID__c, existingRecord.Site_ID__c)
        );
    }
    
    /**
     * Utility method to compare field values and handling null values
     */
    private boolean isEqual(Object value1, Object value2) {
        if(value1 == null && value2 == null) return true;
        if(value1 == null || value2 == null) return false;
        return value1.equals(value2);
    }
    
    private void copyAllFieldValues(Dispatch_Staging__c source, Dispatch_Staging__c target) {
        
        target.Number_of_Material_Document__c = source.Number_of_Material_Document__c;
        target.SAP_Material_Code__c = source.SAP_Material_Code__c;
        target.Salesforce_Unique_Id__c = source.Salesforce_Unique_Id__c;
        target.Haulier_Code__c = source.Haulier_Code__c;
        target.Freight_Reference__c = source.Freight_Reference__c;
        target.Current_Date_for_Start_of_Loading__c = source.Current_Date_for_Start_of_Loading__c;
        target.Delivery_Code__c = source.Delivery_Code__c;
        target.Scheduling_End_Time__c = source.Scheduling_End_Time__c;
        target.Bottle_Identifier__c = source.Bottle_Identifier__c;
        target.Sales_Document__c = source.Sales_Document__c;
        target.Pack_Specification__c = source.Pack_Specification__c;
        target.Actual_Loading_Start_Time__c = source.Actual_Loading_Start_Time__c;
        target.Planned_Date_for_End_of_Shipment__c = source.Planned_Date_for_End_of_Shipment__c;
        target.Purchasing_Document_Number__c = source.Purchasing_Document_Number__c;
        target.Series__c = source.Series__c;
        target.Haulier_Name__c = source.Haulier_Name__c;
        target.Delivery_Name__c = source.Delivery_Name__c;
        target.Record_Creation_Date__c = source.Record_Creation_Date__c;
        target.Planned_Loading_End_Time__c = source.Planned_Loading_End_Time__c;
        target.Current_Date_for_Start_of_Shipment__c = source.Current_Date_for_Start_of_Shipment__c;
        target.Planned_Date_for_Start_of_Loading__c = source.Planned_Date_for_Start_of_Loading__c;
        target.Dispatch_Time__c = source.Dispatch_Time__c;
        target.Bottle_Description__c = source.Bottle_Description__c;
        target.Trailer_Plate_Number__c = source.Trailer_Plate_Number__c;
        target.Customer_Code__c = source.Customer_Code__c;
        target.Actual_Loading_End_Time__c = source.Actual_Loading_End_Time__c;
        target.Material_Document_Year__c = source.Material_Document_Year__c;
        target.Sales_Organization__c = source.Sales_Organization__c;
        target.Item__c = source.Item__c;
        target.Planned_Transport_End_Time__c = source.Planned_Transport_End_Time__c;
        target.Current_Date_of_Shipment_Completion__c = source.Current_Date_of_Shipment_Completion__c;
        target.Overall_Transportation_Status__c = source.Overall_Transportation_Status__c;
        target.Actual_Date_of_Check_In__c = source.Actual_Date_of_Check_In__c;
        target.Customer_Name__c = source.Customer_Name__c;
        target.Planned_Loading_Start_Time__c = source.Planned_Loading_Start_Time__c;
        target.Actual_Shipment_End_Time__c = source.Actual_Shipment_End_Time__c;
        target.Actual_Transport_Start_Time__c = source.Actual_Transport_Start_Time__c;
        target.Planned_Transport_Start_Time__c = source.Planned_Transport_Start_Time__c;
        target.SAP_Model_Number__c = source.SAP_Model_Number__c;
        target.End_of_Planning_Date__c = source.End_of_Planning_Date__c;
        target.Bottles__c = source.Bottles__c;
        target.Tonnage__c = source.Tonnage__c;
        target.Plate_Number__c = source.Plate_Number__c;
        target.Time_of_Transportation_Processing__c = source.Time_of_Transportation_Processing__c;
        target.Planned_Date_of_Check_In__c = source.Planned_Date_of_Check_In__c;
        target.Actual_Date_for_End_of_Shipment__c = source.Actual_Date_for_End_of_Shipment__c;
        target.Entry_Time__c = source.Entry_Time__c;
        target.Dispatch_ID__c = source.Dispatch_ID__c;
        target.Planned_Check_In_Time__c = source.Planned_Check_In_Time__c;
        target.Planned_Time_for_Processing__c = source.Planned_Time_for_Processing__c;
        target.Planned_Date_for_End_of_Loading__c = source.Planned_Date_for_End_of_Loading__c;
        target.Dispatch_Date__c = source.Dispatch_Date__c;
        target.Store__c = source.Store__c;
        target.Planned_Delivery_Time__c = source.Planned_Delivery_Time__c;
        target.Type__c = source.Type__c;
        target.Batch_Number__c = source.Batch_Number__c;
        target.Planned_Date_for_Shipment_Completion__c = source.Planned_Date_for_Shipment_Completion__c;
        target.Planned_Date_for_Start_of_Shipment__c = source.Planned_Date_for_Start_of_Shipment__c;
        target.Planned_Delivery_Date__c = source.Planned_Delivery_Date__c;
        target.Current_Time_of_Check_In__c = source.Current_Time_of_Check_In__c;
        target.Shipment_Number__c = source.Shipment_Number__c;
        target.Actual_Date_for_End_of_Loading__c = source.Actual_Date_for_End_of_Loading__c;
        target.Site_ID__c = source.Site_ID__c;

    }
    
    private void cleanupSystemDuplicates(Set<String> uniqueIds) {
        
        Map<String, List<Dispatch_Staging__c>> duplicateGroups = new Map<String, List<Dispatch_Staging__c>>();
        
        for(Dispatch_Staging__c record : [
            SELECT Id, Salesforce_Unique_Id__c, CreatedDate 
            FROM Dispatch_Staging__c 
            WHERE Salesforce_Unique_Id__c IN :uniqueIds
            ORDER BY Salesforce_Unique_Id__c, CreatedDate ASC
        ]) {
            if(!duplicateGroups.containsKey(record.Salesforce_Unique_Id__c)) {
                duplicateGroups.put(record.Salesforce_Unique_Id__c, new List<Dispatch_Staging__c>());
            }
            duplicateGroups.get(record.Salesforce_Unique_Id__c).add(record);
        }
        
        List<Dispatch_Staging__c> duplicatesToDelete = new List<Dispatch_Staging__c>();
        
        for(String uniqueId : duplicateGroups.keySet()) {
            List<Dispatch_Staging__c> duplicates = duplicateGroups.get(uniqueId);
            if(duplicates.size() > 1) {
                for(Integer i = 1; i < duplicates.size(); i++) {
                    duplicatesToDelete.add(duplicates[i]);
                }
            }
        }
        
        if(!duplicatesToDelete.isEmpty()) {
            try {
                delete duplicatesToDelete;
                System.debug('Cleaned up ' + duplicatesToDelete.size() + ' system duplicates');
            } catch(Exception e) {
                System.debug('Error cleaning up duplicates: ' + e.getMessage());
            }
        }
    }
}