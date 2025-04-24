/* ---------------------------------------------------------------------------------------------------------------
   Name:        MonthForecastListController.cls
   Description: Controller Class for MonthForecastList Page
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ----------------------------------------------------------------------
   Mar 2017     1.0     Michael Witchalls   Initial Release 
   Sep 2024     1.1     Globant             Code Refactoring and Added Comments
------------------------------------------------------------------------------------------------------------------ */        
   
public with sharing class MonthForecastListController {

    private static final Integer PAGESIZE = 24;
    
    public Account theAccount {get; set;}
    public String accountId {get; set;}
    
    // Filter picklist
    public List<SelectOption> statusSelectList {get; set;}
    
    /**
     * Constructor for MonthForecastListController.
     * Initializes the account details based on the provided account ID.
     * 
     * @param stdController - The standard controller instance for the page.
     */
    public MonthForecastListController(ApexPages.StandardController stdController) {

        accountId = ApexPages.currentPage().getParameters().get('id');
        
        if (String.isBlank(accountId)) {

            return;
        }

        theAccount = [SELECT Id, Name, SAP_Account_Number__c FROM Account WHERE Id = :accountId LIMIT 1];
    }   
     

    /**
     * Retrieves an instance of ApexPages.StandardSetController for handling pagination and record retrieval.
     * 
     * @return ApexPages.StandardSetController - Controller for managing and displaying month forecast records.
     */
    public ApexPages.StandardSetController monthSetController {
        get{
            if (String.isBlank(accountId)) {

                return null;
            }

            if (monthSetController == null) {

                String currentYear = String.valueOf(System.today().year());
                monthSetController = new ApexPages.StandardSetController(
                    Database.getQueryLocator([
                        SELECT 
                            Id, Name, Sales_Organization_Text__c, Year__c, Budget__c, Forecast__c, Budget_Tonnage__c, Forecast_Tonnage__c, OwnerId
                        FROM 
                            Month__c 
                        WHERE 
                            Customer__c = :accountId
                            AND Year__c = :currentYear
                            AND First_Monday_of_Month__c <= :System.today()
                            AND Is_Current_Month__c = TRUE
                        ORDER BY Unique_ID__c DESC
                        LIMIT 24
                    ])
                );
                monthSetController.setPageSize(PAGESIZE);
            }
            return monthSetController;
        } private set;
    }
    
    /**
     * Retrieves the list of month forecast records managed by MonthSetController.
     * 
     * @return List<Month__c> - The list of Month__c records.
     */
    public List<Month__c> getRecords() {

        if (monthSetController == null) {

            return new List<Month__c>(); 
        }

        return (List<Month__c>)monthSetController.getRecords();
    }
}



// TODO remove once it has been tested/validated/QA-ed
/*public with sharing class MonthForecastListController {
    private static final Integer PAGESIZE = 24;
    
    public Account theAccount   {get; set;}
    public String accountId     {get; set;}
    
    // Filter picklist
    public List<SelectOption> statusSelectList {get; set;}
    
    public MonthForecastListController(ApexPages.StandardController stdController) {
        accountId = ApexPages.currentPage().getParameters().get('id');
        theAccount = [select Id, Name, SAP_Account_Number__c from Account where Id = :accountId];       
    }   
     
    public ApexPages.StandardSetController MonthSetController {
        get {
            String currentYear = String.valueOf(System.today().year());
            if(MonthSetController == null) {
                MonthSetController = new ApexPages.StandardSetController(
                    Database.getQueryLocator([
                        SELECT 
                            Id, Name, Sales_Organization_Text__c, Year__c, Budget__c, Forecast__c, Budget_Tonnage__c, Forecast_Tonnage__c, OwnerId
                        FROM 
                            Month__c 
                        WHERE 
                            Customer__c = :accountId
                            AND Year__c = :currentYear
                            AND First_Monday_of_Month__c <= :System.today()
                            AND Is_Current_Month__c = TRUE
                        ORDER BY Unique_ID__c DESC
                        LIMIT 24
                    ])
                );
            }
            MonthSetController.setPageSize(PAGESIZE);
            return MonthSetController;
        }
        private set;
    }
    
    public List<Month__c> getRecords() {
        return (List<Month__c>)MonthSetController.getRecords();
    } 
}*/