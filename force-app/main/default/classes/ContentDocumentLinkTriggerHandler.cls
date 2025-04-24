/* -----------------------------------------------------------------------------------------------------------------------
   Name:        ContentDocumentLinkTriggerHandler.cls
   Description: Handler class for managing the logic related to ContentDocumentLink trigger events. Recalculates 
                the number of content documents linked to parent records when changes occur.
   
   Date         Version Author    Summary of Changes
   -----------  ------- --------- ------------------------------------------------------------------------------
   Sep 2024     1.0     Globant   Initial Release
----------------------------------------------------------------------------------------------------------------------- */

public class ContentDocumentLinkTriggerHandler {

    /**
     * Recalculates the count of files linked to parent records whenever ContentDocumentLink records are created or modified.
     * 
     * @param triggerNewList List<ContentDocumentLink> - The list of new or modified ContentDocumentLink records from the trigger context.
     */
    public void recountFilesOnParentRecords(List<ContentDocumentLink> triggerNewList) {

        RecalculateContentDocumentHelper recalculationHelper = new RecalculateContentDocumentHelper();

        Set<Id> LinkedEntityIds = recalculationHelper.returnLinkedIdsFromContentDocumentLinks(triggerNewList);

        List<ContentDocumentLink> relatedContentDocumentLinkList = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :LinkedEntityIds AND
            IsDeleted = FALSE
        ];

        recalculationHelper.recalculateContentDocumentsOnRecords(
            relatedContentDocumentLinkList,
            new Set<Id>()
        );
    }
}



// TODO remove once it has been tested/validated/QA-ed
/*public class ContentDocumentLinkTriggerHandler {

    public void recountFilesOnParentRecords(List<ContentDocumentLink> triggerNewList) {

        RecalculateContentDocumentHelper recalculationHelper = new RecalculateContentDocumentHelper();

        Set<Id> LinkedEntityIds = recalculationHelper.returnLinkedIdsFromContentDocumentLinks(triggerNewList);

        List<ContentDocumentLink> relatedContentDocumentLinkList = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :LinkedEntityIds AND
            IsDeleted = FALSE
        ];

        recalculationHelper.recalculateContentDocumentsOnRecords(
            relatedContentDocumentLinkList,
            new Set<Id>()
        );
    }

}*/