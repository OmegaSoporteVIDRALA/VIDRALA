@IsTest
public with sharing class RecalculateContentDocumentHelperTest {

    private static final INTEGER BULK_AMOUNT = 10;

    @TestSetup
    static void setup(){
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocLinkList = new List<ContentDocumentLink>();

        Account myAccount = new Account(name = 'Test Account', CurrencyIsoCode = 'GBP');
        insert myAccount;
        Commercial_Contracts__c newspaFileRecord = new Commercial_Contracts__c(name = 'Test record', Account__c = myAccount.Id);
        insert newspaFileRecord;


        // Create a number of documents.
        for(Integer i = 0; i < BULK_AMOUNT; i++){
            string title = 'Penguins ' + i;
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins ' + i,
                PathOnClient = 'Penguins' + i + '.jpg',
                VersionData = Blob.valueOf('Test Content ' + i),
                IsMajorVersion = true
            );
            contentVersionList.add(contentVersion);
        }

        insert contentVersionList;

        Set<Id> contentVersionIds = new Set<Id>();

        for (ContentVersion cv : contentVersionList) {
            contentVersionIds.add(cv.id);
        }

        List<ContentDocument> contentDocument = new List<ContentDocument>([
            SELECT Id, Title, LatestPublishedVersionId
            FROM ContentDocument
            WHERE LatestPublishedVersionId IN :contentVersionIds
        ]);

        // then create your links back.
        for(ContentDocument cd : contentDocument){
            //create ContentDocumentLink record

            ContentDocumentLink cdl = new ContentDocumentLink(
                LinkedEntityId = newspaFileRecord.id,
                ContentDocumentId = cd.Id,
                ShareType = 'v'
            );

            contentDocLinkList.add(cdl);
        }

        insert contentDocLinkList;
    }

    @IsTest
    private static void returnLinkedIdsFromContentDocumentLinksReturnsCorrectAmount() {
        System.Test.startTest();

		Commercial_Contracts__c commercialContracts = [
            SELECT Id
            FROM Commercial_Contracts__c
			LIMIT 1
        ];

        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>([
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :commercialContracts.Id
            LIMIT :BULK_AMOUNT
        ]);

        Set<Id> expectedIdList = new Set<Id>();

        for (ContentDocumentLink cdl : cdlList) {
            expectedIdList.add(cdl.LinkedEntityId);
        }

        Set<Id> actualIdList = new RecalculateContentDocumentHelper().returnLinkedIdsFromContentDocumentLinks(cdlList);
        
        System.assertEquals(
            expectedIdList.size(),
            actualIdList.size(),
            'The actual list size should be the same as the expected'
        );

        System.assertEquals(
            expectedIdList,
            actualIdList,
            'The actual list should be the same as the expected list'
        );
        System.Test.stopTest();
    }

    @IsTest
    private static void updateRecordsSuccessful() {
        System.Test.startTest();

        Commercial_Contracts__c commercialContracts = [
            SELECT Id, Number_of_files_uploaded__c
            FROM Commercial_Contracts__c
			LIMIT 1
        ];

        System.assert(
            commercialContracts.Number_of_files_uploaded__c > 0,
            'There commercial contract should have a files attached to it already'
        );

        RecalculateContentDocumentHelper helper = new RecalculateContentDocumentHelper();

        helper.sobjectTypeToRecordAndFileCount.get('Commercial_Contracts__c').put(
            commercialContracts.Id,
            0
        );

        helper.updateRecords();
        
        Commercial_Contracts__c updatedCommercialContracts = [
            SELECT Id, Number_of_files_uploaded__c
            FROM Commercial_Contracts__c
            WHERE Id = :commercialContracts.Id
			LIMIT 1
        ];

        System.assertEquals(
            commercialContracts.Id,
            updatedCommercialContracts.Id,
            'The record should have the same id'
        );

        System.assertNotEquals(
            commercialContracts.Number_of_files_uploaded__c,
            updatedCommercialContracts.Number_of_files_uploaded__c,
            'The Number_of_files_uploaded__c field should have been updated'
        );
        System.Test.stopTest();
    }

    @IsTest
    private static void recalculateContentDocumentsOnRecordsSuccessful() {
        System.Test.startTest();
        RecalculateContentDocumentHelper helper = new RecalculateContentDocumentHelper();

        Commercial_Contracts__c commercialContracts = [
            SELECT Id, Number_of_files_uploaded__c
            FROM Commercial_Contracts__c
			LIMIT 1
        ];

        System.assert(
            commercialContracts.Number_of_files_uploaded__c > 0,
            'There commercial contract should have a files attached to it already'
        );

        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>([
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :commercialContracts.Id
            LIMIT :BULK_AMOUNT
        ]);

        
        helper.recalculateContentDocumentsOnRecords(
            cdlList,
            new Set<Id>{ cdlList[0].ContentDocumentId }
        );
		
        
        Commercial_Contracts__c updatedCommercialContracts = [
            SELECT Id, Number_of_files_uploaded__c
            FROM Commercial_Contracts__c
            WHERE Id = :commercialContracts.Id
			LIMIT 1
        ];

        System.assertEquals(
            commercialContracts.Id,
            updatedCommercialContracts.Id,
            'The record should have the same id'
        );

        System.assertNotEquals(
            commercialContracts.Number_of_files_uploaded__c,
            updatedCommercialContracts.Number_of_files_uploaded__c,
            'The Number_of_files_uploaded__c field should have been updated'
        );
        System.Test.stopTest();
    }

    @IsTest
    private static void deleteContentDocumentRecalculateSuccessful() {
        System.Test.startTest();
        Commercial_Contracts__c commercialContracts = [
            SELECT Id, Number_of_files_uploaded__c
            FROM Commercial_Contracts__c
			LIMIT 1
        ];

        System.assert(
            commercialContracts.Number_of_files_uploaded__c > 0,
            'There commercial contract should have a files attached to it already'
        );

        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>([
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :commercialContracts.Id
            LIMIT :BULK_AMOUNT
        ]);

        delete new ContentDocument(
            Id = cdlList[0].ContentDocumentId
        );
        

        Commercial_Contracts__c updatedCommercialContracts = [
            SELECT Id, Number_of_files_uploaded__c
            FROM Commercial_Contracts__c
            WHERE Id = :commercialContracts.Id
			LIMIT 1
        ];

        System.assertEquals(
            commercialContracts.Id,
            updatedCommercialContracts.Id,
            'The record should have the same id'
        );

        System.assertNotEquals(
            commercialContracts.Number_of_files_uploaded__c,
            updatedCommercialContracts.Number_of_files_uploaded__c,
            'The Number_of_files_uploaded__c field should have been updated'
        );

        System.assert(
            updatedCommercialContracts.Number_of_files_uploaded__c == commercialContracts.Number_of_files_uploaded__c-1,
            'The Number_of_files_uploaded__c field should be one less than the original'
        );
        System.Test.stopTest();
    }
}


/*@IsTest
public with sharing class RecalculateContentDocumentHelperTest {

    private static final INTEGER BULK_AMOUNT = 10;

    @TestSetup
    static void setup(){
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocLinkList = new List<ContentDocumentLink>();

        Account myAccount = new Account(name = 'Test Account', CurrencyIsoCode = 'GBP');
        insert myAccount;
        Commercial_Contracts__c newspaFileRecord = new Commercial_Contracts__c(name = 'Test record', Account__c = myAccount.Id);
        insert newspaFileRecord;

        System.debug('newspaFileRecord.id ' + newspaFileRecord.id);

        // Create a number of documents.
        for(Integer i = 0; i < BULK_AMOUNT; i++){
            string title = 'Penguins ' + i;
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins ' + i,
                PathOnClient = 'Penguins' + i + '.jpg',
                VersionData = Blob.valueOf('Test Content ' + i),
                IsMajorVersion = true
            );
            contentVersionList.add(contentVersion);
        }

        insert contentVersionList;

        Set<Id> contentVersionIds = new Set<Id>();

        for (ContentVersion cv : contentVersionList) {
            contentVersionIds.add(cv.id);
        }

        List<ContentDocument> contentDocument = new List<ContentDocument>([
            SELECT Id, Title, LatestPublishedVersionId
            FROM ContentDocument
            WHERE LatestPublishedVersionId IN :contentVersionIds
        ]);

        // then create your links back.
        for(ContentDocument cd : contentDocument){
            //create ContentDocumentLink record

            ContentDocumentLink cdl = new ContentDocumentLink(
                LinkedEntityId = newspaFileRecord.id,
                ContentDocumentId = cd.Id,
                ShareType = 'v'
            );

            contentDocLinkList.add(cdl);
        }

        insert contentDocLinkList;
    }

    @IsTest
    private static void returnLinkedIdsFromContentDocumentLinksReturnsCorrectAmount() {

		Commercial_Contracts__c commercialContracts = [
            SELECT Id
            FROM Commercial_Contracts__c
			LIMIT 1
        ];

        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>([
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :commercialContracts.Id
            LIMIT :BULK_AMOUNT
        ]);

        Set<Id> expectedIdList = new Set<Id>();

        for (ContentDocumentLink cdl : cdlList) {
            expectedIdList.add(cdl.LinkedEntityId);
        }

        Set<Id> actualIdList = new RecalculateContentDocumentHelper().returnLinkedIdsFromContentDocumentLinks(cdlList);

        System.assertEquals(
            expectedIdList.size(),
            actualIdList.size(),
            'The actual list size should be the same as the expected'
        );

        System.assertEquals(
            expectedIdList,
            actualIdList,
            'The actual list should be the same as the expected list'
        );
    }

    @IsTest
    private static void updateRecordsSuccessful() {

        System.debug('START OF Method');
        Commercial_Contracts__c commercialContracts = [
            SELECT Id, Number_of_files_uploaded__c
            FROM Commercial_Contracts__c
			LIMIT 1
        ];

        System.assert(
            commercialContracts.Number_of_files_uploaded__c > 0,
            'There commercial contract should have a files attached to it already'
        );

        RecalculateContentDocumentHelper helper = new RecalculateContentDocumentHelper();

        helper.sobjectTypeToRecordAndFileCount.get('Commercial_Contracts__c').put(
            commercialContracts.Id,
            0
        );

        helper.updateRecords();

        Commercial_Contracts__c updatedCommercialContracts = [
            SELECT Id, Number_of_files_uploaded__c
            FROM Commercial_Contracts__c
            WHERE Id = :commercialContracts.Id
			LIMIT 1
        ];

        System.assertEquals(
            commercialContracts.Id,
            updatedCommercialContracts.Id,
            'The record should have the same id'
        );

        System.assertNotEquals(
            commercialContracts.Number_of_files_uploaded__c,
            updatedCommercialContracts.Number_of_files_uploaded__c,
            'The Number_of_files_uploaded__c field should have been updated'
        );
    }

    @IsTest
    private static void recalculateContentDocumentsOnRecordsSuccessful() {
        RecalculateContentDocumentHelper helper = new RecalculateContentDocumentHelper();

        Commercial_Contracts__c commercialContracts = [
            SELECT Id, Number_of_files_uploaded__c
            FROM Commercial_Contracts__c
			LIMIT 1
        ];

        System.assert(
            commercialContracts.Number_of_files_uploaded__c > 0,
            'There commercial contract should have a files attached to it already'
        );

        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>([
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :commercialContracts.Id
            LIMIT :BULK_AMOUNT
        ]);

        helper.recalculateContentDocumentsOnRecords(
            cdlList,
            new Set<Id>{ cdlList[0].ContentDocumentId }
        );

        Commercial_Contracts__c updatedCommercialContracts = [
            SELECT Id, Number_of_files_uploaded__c
            FROM Commercial_Contracts__c
            WHERE Id = :commercialContracts.Id
			LIMIT 1
        ];

        System.assertEquals(
            commercialContracts.Id,
            updatedCommercialContracts.Id,
            'The record should have the same id'
        );

        System.assertNotEquals(
            commercialContracts.Number_of_files_uploaded__c,
            updatedCommercialContracts.Number_of_files_uploaded__c,
            'The Number_of_files_uploaded__c field should have been updated'
        );
    }

    @IsTest
    private static void deleteContentDocumentRecalculateSuccessful() {
        Commercial_Contracts__c commercialContracts = [
            SELECT Id, Number_of_files_uploaded__c
            FROM Commercial_Contracts__c
			LIMIT 1
        ];

        System.assert(
            commercialContracts.Number_of_files_uploaded__c > 0,
            'There commercial contract should have a files attached to it already'
        );

        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>([
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :commercialContracts.Id
            LIMIT :BULK_AMOUNT
        ]);

        delete new ContentDocument(
            Id = cdlList[0].ContentDocumentId
        );

        Commercial_Contracts__c updatedCommercialContracts = [
            SELECT Id, Number_of_files_uploaded__c
            FROM Commercial_Contracts__c
            WHERE Id = :commercialContracts.Id
			LIMIT 1
        ];

        System.assertEquals(
            commercialContracts.Id,
            updatedCommercialContracts.Id,
            'The record should have the same id'
        );

        System.assertNotEquals(
            commercialContracts.Number_of_files_uploaded__c,
            updatedCommercialContracts.Number_of_files_uploaded__c,
            'The Number_of_files_uploaded__c field should have been updated'
        );

        System.assert(
            updatedCommercialContracts.Number_of_files_uploaded__c == commercialContracts.Number_of_files_uploaded__c-1,
            'The Number_of_files_uploaded__c field should be one less than the original'
        );
    }
}*/