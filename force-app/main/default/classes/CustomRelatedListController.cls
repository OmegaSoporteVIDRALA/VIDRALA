/* -----------------------------------------------------------------------------------------------------------------------
   Name:        CustomRelatedListController.cls
   Description: Controller class for fetching related records based on the provided record ID. Provides methods to retrieve
                discounts and packaging agreements associated with an account derived from the given record ID.
   
   Date         Version Author    Summary of Changes
   -----------  ------- --------- ------------------------------------------------------------------------------
   Sep 2024     1.0     Globant   Initial Release
----------------------------------------------------------------------------------------------------------------------- */

public with sharing class CustomRelatedListController {
    /**
     * Retrieves a list of Discount__c records associated with the account derived from the provided record ID.
     * 
     * @param recordId String - The record ID from which the account ID will be derived.
     * @return List<Discount__c> - A list of Discount__c records related to the account.
     */
    @AuraEnabled(Cacheable = true)
    public static List<Discount__c> getDiscounts(String recordId) {
        if (String.isEmpty(recordId)) {
            return new List<Discount__c>();
        }

        String accountId = getAccountId(recordId);
        List<Discount__c> discounts = new List<Discount__c>();

        if (String.isNotEmpty(accountId)) {
            discounts = [
                SELECT Id, Name, Status__c, CurrencyIsoCode, Account__c, TYPE__c, ProductName__c, Unit_Type__c, Quantity__c, Percentage__c, EUR__c 
                FROM Discount__c
                WHERE Account__c = :accountId
                WITH SECURITY_ENFORCED
            ];
        }
        
        return discounts; 
    }

    /**
     * Retrieves a list of Packaging_Agreement__c records associated with the account derived from the provided record ID.
     * 
     * @param recordId String - The record ID from which the account ID will be derived.
     * @return List<Packaging_Agreement__c> - A list of Packaging_Agreement__c records related to the account.
     */
    @AuraEnabled(Cacheable = true)
    public static List<Packaging_Agreement__c> getAgreements(String recordId) {
        if (String.isEmpty(recordId)) {
            return new List<Packaging_Agreement__c>();
        }

        String accountId = getAccountId(recordId);
        List<Packaging_Agreement__c> agreements = new List<Packaging_Agreement__c>();

        if (String.isNotEmpty(accountId)) {
            agreements = [
                SELECT Id, Name, Material__c, Agreement__c, Account__c, Agreement_Code__c, Credit_Price__c, Debit_Price__c 
                FROM Packaging_Agreement__c 
                WHERE Account__c = :accountId
                WITH SECURITY_ENFORCED
            ];
        }
        
        return agreements; 
    }

    /**
     * Retrieves the AccountId associated with a given Quote record ID.
     * 
     * @param quoteId String - The Quote record ID.
     * @return String - The Account ID associated with the provided Quote ID.
     */
    private static String getAccountId(String quoteId) {
        if (String.isEmpty(quoteId)) {
            return null;
        }

        Quote quoteRecord;
        try {
            quoteRecord = [
                SELECT Id, Name, AccountId 
                FROM Quote
                WHERE Id = :quoteId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        } catch (QueryException e) {
            return null;
        }

        if (quoteRecord == null) {
            return null;
        }

        return quoteRecord.AccountId;    
    }
}





// TODO remove once it has been tested/validated/QA-ed
/*public with sharing class CustomRelatedListController {

    private static String accountId;

    @AuraEnabled(Cacheable = true)
    public static List<Discount__c> getDiscounts(String recordId) {
        //quoteId = recordId;
        accountId = getAccountId(recordId);
        List<Discount__c> discounts = new List<Discount__c>();

        if (String.isNotEmpty(accountId)) {
            discounts = [
                SELECT Id, Name, Status__c, CurrencyIsoCode, Account__c, TYPE__c, ProductName__c, Unit_Type__c, Quantity__c, Percentage__c, EUR__c 
                FROM Discount__c
                WHERE Account__c = :accountId
            ];
        }
        
        return discounts; 
    }

    @AuraEnabled(Cacheable = true)
    public static List<Packaging_Agreement__c> getAgreements(String recordId) {
        accountId = getAccountId(recordId);
        List<Packaging_Agreement__c> agreements = new List<Packaging_Agreement__c>();

        if (String.isNotEmpty(accountId)) {
            agreements = [
                SELECT Id, Name, Material__c, Agreement__c, Account__c, Agreement_Code__c, Credit_Price__c, Debit_Price__c 
                FROM Packaging_Agreement__c 
                WHERE Account__c = :accountId
            ];
        }
        
        return agreements; 
    }

    private static String getAccountId(String quoteId) {
        Quote quoteRecord = [
            SELECT Id, Name, AccountId 
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];
        return quoteRecord.AccountId;
    }
}*/