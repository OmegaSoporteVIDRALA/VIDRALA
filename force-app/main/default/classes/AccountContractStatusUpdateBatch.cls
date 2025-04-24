/* -----------------------------------------------------------------------------------------------------------------------
   Name:        AccountContractStatusUpdateBatch.cls
   Description: AccountContractStatusUpdateBatch is responsible for updating account contract statuses 
                based on the related commercial contract data and resetting expired contract statuses.

   Date         Version Author              Summary of Changes
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Sep 2024     1.0     Globant             Initial Release
------------------------------------------------------------------------------------------------------------------------ */
global class AccountContractStatusUpdateBatch implements Database.Batchable<sObject> {

    /**
     * Start method to define the query for batch processing.
     * 
     * @param  BC Database.BatchableContext
     * @return Database.QueryLocator The query locator for the batch
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        Date today = Date.today();
        
        String query = 'SELECT Id, Account__c, Contract_Status__c, Start_date__c, End_Date__c ' + 
                       'FROM Commercial_Contract_Status__c WHERE Start_date__c < :today AND End_Date__c > :today';
        
        return Database.getQueryLocator(query);
    }

    /**
     * Executes the logic to update accounts based on the commercial contract status.
     * 
     * @param BC Database.BatchableContext
     * @param scope List<Commercial_Contract_Status__c> The batch scope of commercial contracts
     */
    global void execute(Database.BatchableContext BC, List<Commercial_Contract_Status__c> scope) {
        
        if (scope.isEmpty()) return;

        Map<Id, Commercial_Contract_Status__c> contractMap = buildContractMap(scope);
        updateAccountsWithContractStatus(contractMap);
        resetExpiredContractStatuses();
    }

    /**
     * Finish method after batch completes execution.
     * 
     * @param BC Database.BatchableContext
     */
    global void finish(Database.BatchableContext BC) {
        // Any post-processing logic after the batch execution can be placed here
    }

    /**
     * Builds a map of Account IDs to their respective Commercial Contract Status.
     * 
     * @param  scope List<Commercial_Contract_Status__c>  The batch scope of commercial contracts
     * @return Map<Id, Commercial_Contract_Status__c>     A map of Account ID to Commercial Contract Status
     */
    private Map<Id, Commercial_Contract_Status__c> buildContractMap(List<Commercial_Contract_Status__c> scope) {
        
        Map<Id, Commercial_Contract_Status__c> contractMap = new Map<Id, Commercial_Contract_Status__c>();
        
        for (Commercial_Contract_Status__c cc : scope) {
            // Only store the contract if it's the first occurrence for the account
            if (!contractMap.containsKey(cc.Account__c)) {
                
                contractMap.put(cc.Account__c, cc);
            }
        }
        
        return contractMap;
    }

    /**
     * Updates accounts with new contract statuses based on the commercial contract map.
     * 
     * @param contractMap Map<Id, Commercial_Contract_Status__c> Map of Account IDs to their contract status
     */
    private void updateAccountsWithContractStatus(Map<Id, Commercial_Contract_Status__c> contractMap) {
        
        if (contractMap.isEmpty()) return;

        List<Account> accountsToUpdate = new List<Account>();
        Set<Id> accountIds = contractMap.keySet();

        for (Account acc : [SELECT Id, Commercial_Contract_Status__c, Contract_Expire_Date__c 
                            FROM Account WHERE Id IN :accountIds]) {
            
                                Commercial_Contract_Status__c cc = contractMap.get(acc.Id);
            acc.Commercial_Contract_Status__c = cc.Contract_Status__c;
            acc.Contract_Expire_Date__c = cc.End_Date__c;
            accountsToUpdate.add(acc);
        }

        if (!accountsToUpdate.isEmpty()) {
            
            update accountsToUpdate;
        }
    }

    /**
     * Resets expired contract statuses by setting them to a default state and clearing expiration dates.
     */
    private void resetExpiredContractStatuses() {
        
        List<Account> expiredAccountsToUpdate = [SELECT Id, Commercial_Contract_Status__c, Contract_Expire_Date__c 
                                                 FROM Account 
                                                 WHERE Contract_Expire_Date__c < :Date.today()];

        for (Account acc : expiredAccountsToUpdate) {
            
            acc.Contract_Expire_Date__c = null;
            acc.Commercial_Contract_Status__c = 'Red'; // Assuming 'Red' indicates expired status
        }

        if (!expiredAccountsToUpdate.isEmpty()) {
            
            update expiredAccountsToUpdate;
        }
    }
}

// TODO remove once it has been tested/validated/QA-ed
/* global class AccountContractStatusUpdateBatch implements Database.Batchable<sObject>
{
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        Date today = Date.today();
        String query = 'SELECT Id, Account__c, Contract_Status__c, Start_date__c, End_Date__c FROM Commercial_Contract_Status__c WHERE Start_date__c < :today AND End_Date__c > :today';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Commercial_Contract_Status__c> scope)
    {
        Set<Id> accountIds = new Set<Id>();
        List<Account> accountsToUpdate = new List<Account>();
        Map<Id, Commercial_Contract_Status__c> contractMap = new Map<Id, Commercial_Contract_Status__c>();
        for(Commercial_Contract_Status__c cc : scope){
            accountIds.add(cc.Account__c);
            if(!contractMap.containsKey(cc.Account__c)){
                contractMap.put(cc.Account__c, cc);
            }
        }
        if(!accountIds.isEmpty()){
            for(Account acc : [SELECT Id, Commercial_Contract_Status__c, Contract_Expire_Date__c FROM Account WHERE Id IN : accountIds]){
                acc.Commercial_Contract_Status__c = contractMap.get(acc.Id).Contract_Status__c;
                acc.Contract_Expire_Date__c = contractMap.get(acc.Id).End_Date__c;
                accountsToUpdate.add(acc);
            }
            update accountsToUpdate;
        }
        accountsToUpdate = new List<Account>();
        for(Account acc : [SELECT Id, Commercial_Contract_Status__c, Contract_Expire_Date__c FROM Account WHERE Contract_Expire_Date__c < :Date.today()]){
            acc.Contract_Expire_Date__c = null;
            acc.Commercial_Contract_Status__c = 'Red';
            accountsToUpdate.add(acc);
        }
        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate;
        }
    }  
    global void finish(Database.BatchableContext BC)
    {
    }
} */