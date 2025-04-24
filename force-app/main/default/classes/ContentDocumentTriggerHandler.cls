/* -----------------------------------------------------------------------------------------------------------------------
   Name:        ContentDocumentTriggerHandler.cls
   Description: Handler class for managing ContentDocument trigger events. Recalculates the number of content documents 
                linked to parent records when ContentDocument records are modified or deleted.
   
   Date         Version Author    Summary of Changes
   -----------  ------- --------- ------------------------------------------------------------------------------
   Sep 2024     1.0     Globant   Initial Release
----------------------------------------------------------------------------------------------------------------------- */

public class ContentDocumentTriggerHandler {

    /**
     * Recalculates the count of files linked to parent records whenever ContentDocument records are modified or deleted.
     * 
     * @param triggerOldList List<ContentDocument> - The list of old ContentDocument records from the trigger context.
     */
    public void recountFilesOnParentRecords(List<ContentDocument> triggerOldList) {
        RecalculateContentDocumentHelper recalculationHelper = new RecalculateContentDocumentHelper();

        Set<Id> contentDocumentIds = returnIdsFromList(triggerOldList);

        List<ContentDocumentLink> contentDocumentLinkList = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocumentIds
        ];

        Set<Id> LinkedEntityIds = recalculationHelper.returnLinkedIdsFromContentDocumentLinks(contentDocumentLinkList);

        List<ContentDocumentLink> relatedContentDocumentLinkList = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :LinkedEntityIds AND
            IsDeleted = FALSE
        ];

        recalculationHelper.recalculateContentDocumentsOnRecords(
            relatedContentDocumentLinkList,
            contentDocumentIds
        );
    }

    /**
     * Extracts the Ids from a list of ContentDocument records and returns them as a Set.
     * 
     * @param contentDocumentList List<ContentDocument> - The list of ContentDocument records.
     * @return Set<Id> - A Set of ContentDocument Ids.
     */
    private Set<Id> returnIdsFromList(List<ContentDocument> contentDocumentList) {
        Set<Id> idSet = new Set<Id>();

        for (ContentDocument contentDocument : contentDocumentList) {
            idSet.add(contentDocument.Id);
        }

        return idSet;
    }
}


// TODO remove once it has been tested/validated/QA-ed
/*public class ContentDocumentTriggerHandler {

    public void recountFilesOnParentRecords(List<ContentDocument> triggerOldList) {
        RecalculateContentDocumentHelper recalculationHelper = new RecalculateContentDocumentHelper();

        Set<Id> contentDocumentIds = returnIdsFromList(triggerOldList);

        List<ContentDocumentLink> contentDocumentLinkList = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocumentIds
        ];

        Set<Id> LinkedEntityIds = recalculationHelper.returnLinkedIdsFromContentDocumentLinks(contentDocumentLinkList);

        List<ContentDocumentLink> relatedContentDocumentLinkList = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :LinkedEntityIds AND
            IsDeleted = FALSE
        ];

        recalculationHelper.recalculateContentDocumentsOnRecords(
            relatedContentDocumentLinkList,
            contentDocumentIds
        );

    }

    private Set<Id> returnIdsFromList(List<ContentDocument> contentDocumentList) {
        Set<Id> idSet = new Set<Id>();

        for(ContentDocument contentDocument : contentDocumentList ) {
            idSet.add(contentDocument.Id);
        }

        return idSet;
    }

}*/