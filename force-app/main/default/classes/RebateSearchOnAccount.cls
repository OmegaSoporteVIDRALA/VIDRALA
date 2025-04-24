/* -----------------------------------------------------------------------------------------------------------------------
   Name:        RebateSearchOnAccount.cls
   Description: Class to search for Rebate records based on the associated Account of a given Quote record.
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Sept 2024    1.0     Globant             Initial Release 
------------------------------------------------------------------------------------------------------------------------ */        

/**
 * The RebateSearchOnAccount class provides a method to search for rebates related to a specific quote.
 * It retrieves the AccountId from the provided Quote and then queries the related Rebate records.
 */
public class RebateSearchOnAccount {
    /**
     * Searches for Rebate__c records associated with the account related to the provided Quote record.
     * 
     * @param quoteRecordId The Id of the Quote record. It cannot be null.
     * @return List<Rebate__c> A list of Rebate__c records related to the account in the Quote.
     * @throws CustomException If the quoteRecordId is null, or if no records are found in the queries.
     */
    @AuraEnabled
    public static List<Rebate__c> searchRebate(Id quoteRecordId) {
        if (quoteRecordId == null) {
            throw new CustomException('Quote record ID cannot be null.');
        }
        
        List<Rebate__c> rebates = new List<Rebate__c>();
        try {
            Quote qc = [SELECT Id, AccountId FROM Quote WHERE Id = :quoteRecordId];
            rebates = [SELECT Id, Name, Product__r.Name, Scales__c, Percentage__c, Provision__c,Reason_for_Rebate__c
                       FROM Rebate__c 
                       WHERE Account__c = :qc.AccountId];

        } catch (Exception e) {
            throw new CustomException('No records found in Quote/Rebate query');
        }

        return rebates;
    }
    
    public class CustomException extends Exception {}

}


/*public class RebateSearchOnAccount {
	@AuraEnabled
    public static List<Rebate__c> searchRebate(Id quoteRecordId){
    	List< Rebate__c> rebates = new List<Rebate__c>();
        Quote qc = [SELECT Id,AccountId FROM Quote WHERE Id =: quoteRecordId];        
        rebates = [SELECT Id,Name,Product__r.Name,Scales__c,Percentage__c,Provision__c FROM Rebate__c WHERE Account__c =: qc.AccountId];
        return rebates;
        
    }
}*/