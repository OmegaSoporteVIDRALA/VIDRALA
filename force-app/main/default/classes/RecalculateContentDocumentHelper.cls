/* -----------------------------------------------------------------------------------------------------------------------
   Name:        RecalculateContentDocumentHelper.cls
   Description: Apex class for recalculating content document counts associated with specific Salesforce objects. 
                Provides methods to update the count of files related to records and manage the mapping of record IDs
                to file counts based on content document links.
   
   Date         Version Author    Summary of Changes
   -----------  ------- --------- ------------------------------------------------------------------------------
   Sep 2024     1.0     Globant   Initial Release
----------------------------------------------------------------------------------------------------------------------- */

public with sharing class RecalculateContentDocumentHelper {
    
    @TestVisible
    private Map<String, Map<Id, Integer>> sobjectTypeToRecordAndFileCount = new Map<String, Map<Id, Integer>>{
        'Certificate_of_Conformance__c' => new Map<Id, Integer>(),
        'Commercial_Contracts__c' => new Map<Id, Integer>(),
        'Consumer_Complaint__c' => new Map<Id, Integer>(),
        'Contract' => new Map<Id, Integer>(),
        'CTR_CSR__c' => new Map<Id, Integer>(),
        'Deal_Sheet__c' => new Map<Id, Integer>(),
        'Drawing__c' => new Map<Id, Integer>(),
        'Design_Brief__c' => new Map<Id, Integer>(),
        'Vidrala_Customer_Survey_Annual_Reports__c' => new Map<Id, Integer>()
    };

    /**
     * Recalculates the number of content documents associated with records.
     *
     * @param contentDocumentLinkList The list of ContentDocumentLink records to process.
     * @param deletedContentDocumentIds Set of IDs for content documents that were deleted.
     * @throws CustomException if inputs are null or if an unexpected error occurs during DML.
     */
    public void recalculateContentDocumentsOnRecords(List<ContentDocumentLink> contentDocumentLinkList, Set<Id> deletedContentDocumentIds) {
        if (contentDocumentLinkList == null || contentDocumentLinkList.isEmpty()) {
            throw new CustomException('ContentDocumentLink list is null or empty.');
        }
        if (deletedContentDocumentIds == null) {
            deletedContentDocumentIds = new Set<Id>();
        }

        String currentObjectType;

        for (ContentDocumentLink contentDocumentLink : contentDocumentLinkList) {
            currentObjectType = contentDocumentLink.LinkedEntityId.getSObjectType().getDescribe().getName();

            if (sobjectTypeToRecordAndFileCount.containsKey(currentObjectType)) {
                Map<Id, Integer> currentObjectMap = sobjectTypeToRecordAndFileCount.get(currentObjectType);

                if (!currentObjectMap.containsKey(contentDocumentLink.LinkedEntityId)) {
                    currentObjectMap.put(contentDocumentLink.LinkedEntityId, 0);
                }

                if (!deletedContentDocumentIds.contains(contentDocumentLink.ContentDocumentId)) {
                    currentObjectMap.put(
                        contentDocumentLink.LinkedEntityId,
                        currentObjectMap.get(contentDocumentLink.LinkedEntityId) + 1
                    );
                }
            }
        }

        updateRecords();
    }

    /**
     * Updates records with the new count of associated content documents.
     * Handles DML exceptions and logs errors for debugging.
     * 
     * @throws CustomException if a DML operation fails.
     */
    @TestVisible
    private void updateRecords() {
        try {
            for (String currentObjectType : sobjectTypeToRecordAndFileCount.keySet()) {
                List<SObject> recordsToUpdate = new List<SObject>();

                Map<Id, Integer> currentObjectMap = sobjectTypeToRecordAndFileCount.get(currentObjectType);

                for (Id recordId : currentObjectMap.keySet()) {
                    SObject sobjectRecord = Schema.getGlobalDescribe().get(currentObjectType).newSObject();

                    sobjectRecord.put('Id', recordId);
                    sobjectRecord.put('Files_last_updated__c', datetime.now());
                    sobjectRecord.put('Number_of_files_uploaded__c', currentObjectMap.get(recordId));

                    recordsToUpdate.add(sobjectRecord);
                }

                if (!recordsToUpdate.isEmpty()) {
                    update recordsToUpdate;
                }
            }
        } catch (DmlException ex) {
            throw new CustomException('Failed to update records: ' + ex.getMessage());
        }
    }

    /**
     * Returns a set of LinkedEntityIds from a list of ContentDocumentLink records.
     *
     * @param contentDocumentLinkList The list of ContentDocumentLink records.
     * @return A set of LinkedEntityIds.
     * @throws CustomException if the input list is null.
     */
    public Set<Id> returnLinkedIdsFromContentDocumentLinks(List<ContentDocumentLink> contentDocumentLinkList) {
        if (contentDocumentLinkList == null) {
            throw new CustomException('ContentDocumentLink list cannot be null.');
        }

        Set<Id> linkedIds = new Set<Id>();

        for (ContentDocumentLink cdl : contentDocumentLinkList) {
            linkedIds.add(cdl.LinkedEntityId);
        }

        return linkedIds;
    }

    public class CustomException extends Exception {}
}



/*public with sharing class RecalculateContentDocumentHelper {

    @TestVisible
    private Map<String, Map<Id, Integer>> sobjectTypeToRecordAndFileCount = new Map<String, Map<Id, Integer>>{
        'Certificate_of_Conformance__c' => new Map<Id, Integer>(),
        'Commercial_Contracts__c' => new Map<Id, Integer>(),
        'Consumer_Complaint__c' => new Map<Id, Integer>(),
        'Contract' => new Map<Id, Integer>(),
        'CTR_CSR__c' => new Map<Id, Integer>(),
        'Deal_Sheet__c' => new Map<Id, Integer>(),
        'Drawing__c' => new Map<Id, Integer>(),
        'Design_Brief__c' => new Map<Id, Integer>(),
        'Vidrala_Customer_Survey_Annual_Reports__c' => new Map<Id, Integer>()
    };

    public void recalculateContentDocumentsOnRecords(List<ContentDocumentLink> contentDocumentLinkList, Set<Id> deletedContentDocumentIds) {
        String currentObjectType;

        for (ContentDocumentLink contentDocumentLink : contentDocumentLinkList) {
            currentObjectType = contentDocumentLink.LinkedEntityId.getSObjectType().getDescribe().getName();
            //Checks to see if the related object is an object type that needs to recalculate
            if (sobjectTypeToRecordAndFileCount.containsKey(currentObjectType)) {
                //Retrieves the counter map for that object
                Map<Id, Integer> currentObjectMap = sobjectTypeToRecordAndFileCount.get(currentObjectType);

                //Checks to see if the current record is within the map or not, before adding to the counter
                if(!currentObjectMap.containsKey(contentDocumentLink.LinkedEntityId)) {
                    currentObjectMap.put(contentDocumentLink.LinkedEntityId, 0);
                }

                if(!deletedContentDocumentIds.contains(contentDocumentLink.ContentDocumentId)) {
                    currentObjectMap.put(
                        contentDocumentLink.LinkedEntityId,
                        currentObjectMap.get(contentDocumentLink.LinkedEntityId)+1
                    );
                }
            }
        }
        updateRecords();
    }

    //Dynamically loops through the object lists and updates where necessary
    //ASSUMPTION : ALL FIELDS ON THE OBJECTS ARE NAMED THE EXACT SAME
    @TestVisible
    private void updateRecords() {

        for (String currentObjectType : sobjectTypeToRecordAndFileCount.keyset()) {
            List<SObject> recordsToUpdate = new List<SObject>();

            Map<Id, Integer> currentObjectMap = sobjectTypeToRecordAndFileCount.get(currentObjectType);

            for (Id recordId : currentObjectMap.keySet()) {

                SObject sobjectRecord = Schema.getGlobalDescribe().get(currentObjectType).newSObject();

                sobjectRecord.put('Id', recordId);
                sobjectRecord.put('Files_last_updated__c', datetime.now());
                sobjectRecord.put('Number_of_files_uploaded__c', currentObjectMap.get(recordId));

                recordsToUpdate.add(sobjectRecord);

            }

            update recordsToUpdate;

        }
    }

    public Set<Id> returnLinkedIdsFromContentDocumentLinks(List<ContentDocumentLink> contentDocumentLinkList) {
        Set<Id> linkedIds = new Set<Id>();

        for (ContentDocumentLink cdl : contentDocumentLinkList) {
            linkedIds.add(cdl.LinkedEntityId);
        }

        return linkedIds;
    }
}*/