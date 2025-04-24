/* -----------------------------------------------------------------------------------------------------------------------
   Name:        AccountTeamController.cls
   Description: Apex class to retrieve Account team member details for one or more Account records.

   Date         Version Author              Summary of Changes
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Sep 2024     1.0     Globant             Initial Release
------------------------------------------------------------------------------------------------------------------------ */
public with sharing class AccountTeamController {

    /**
     * Retrieves team member details for multiple Account records by their Ids.
     * 
     * @param  recordIds List of Account record IDs to retrieve team member details for.
     * @return Map of Account Ids to Account records containing team member details.
     *         Returns an empty map if no accounts are found or if invalid/removed Ids are passed.
     * @throws CustomException if no valid Account records are found for the provided Ids.
     */
    @AuraEnabled(Cacheable = true)
    public static Map<Id, Account> getTeamMembers(List<String> recordIds) {
        // Handle case where no Ids are passed
        if (recordIds == null || recordIds.isEmpty()) {
            throw new CustomException('No record Ids provided.');
        }

        // Query for the Accounts based on the provided record Ids
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [ 
                SELECT Id, Name, 
                    Account_Manager_IT__r.Name, 
                    Account_Manager_UK__r.Name, 
                    Account_Manager__r.Name, 
                    Area_Manager_UK__r.Name, 
                    Area_Manager__r.Name,
                    Customer_Service_IT__r.Name, 
                    Customer_Service_UK__r.Name, 
                    Customer_Service__r.Name, 
                    Sales_Office__r.Name, 
                    Sales_Office_UK__r.Name, 
                    Sales_Office_IT__r.Name 
                FROM Account
                WHERE Id IN :recordIds
            ]
        );

        // If no accounts are found, throw an error
        if (accountMap.isEmpty()) {
            throw new CustomException('No valid Accounts found for the provided Ids.');
        }

        return accountMap;
    }
    
    // Custom exception class to handle errors
    public class CustomException extends Exception {}
}


// TODO remove once it has been tested/validated/QA-ed
/* public with sharing class AccountTeamController {

    @AuraEnabled(Cacheable = true)
    public static Account getTeamMembers(String recordId) {
        Account teamMembers = [ 
            SELECT Id, Name, Account_Manager_IT__r.Name, Account_Manager_UK__r.Name, Account_Manager__r.Name, Area_Manager_UK__r.Name, Area_Manager__r.Name,
            Customer_Service_IT__r.Name, Customer_Service_UK__r.Name, Customer_Service__r.Name, Sales_Office__r.Name, Sales_Office_UK__r.Name, Sales_Office_IT__r.Name 
            FROM Account
            WHERE Id = :recordId
        ];
        return teamMembers;
    }
} */