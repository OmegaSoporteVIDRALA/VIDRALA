/* -----------------------------------------------------------------------------------------------------------------------
   Name:        NewMonthForecastExtensionController.cls
   Description: Extension controller class for 'New Month Forecasts for Year' button
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Sep 2024     1.1     Globant             Code Refactoring and Added Comments
------------------------------------------------------------------------------------------------------------------------ */        

public with sharing class NewMonthForecastExtensionController {
    private ForecastProvider fProvider; 
    private Account a;
    private String accountId;
    private String year;   
    public String accountNum { get; set; }
    public Boolean isUK { get; set; }
    public Boolean isItaly { get; set; }
    public Boolean isSpain { get; set; }
    
    /**
     * Constructor for NewMonthForecastExtensionController.
     * Initializes the class with the account details and current year based on the provided standard controller.
     * 
     * @param stdController - The standard controller instance for the page.
     */
    public NewMonthForecastExtensionController(ApexPages.StandardController stdController) {
        fProvider = new ForecastProvider();
        
        this.accountId = ApexPages.currentPage().getParameters().get('id');
        if (String.isBlank(this.accountId)) {
            return;
        }
        
        try {
            this.a = [SELECT Id, SAP_Account_Number__c FROM Account WHERE Id = :this.accountId LIMIT 1]; 
        } catch (Exception e) {
            return;
        }
        this.accountNum = this.a.SAP_Account_Number__c;
        this.year = String.valueOf(System.today().year());
    }
    
    /**
     * Checks if the SAP Account Number is provided and displays appropriate messages.
     * 
     * @return PageReference - Redirects to the same page with an informational or error message.
     */
    public PageReference check() {
        if (String.isBlank(this.accountNum)) {
            ApexPages.addmessage(new ApexPages.message(
                ApexPages.Severity.ERROR, 'In order to create Month Forecasts, an SAP Account Number is required: press Cancel'
            ));
        } else {
            ApexPages.addmessage(new ApexPages.message(
                ApexPages.Severity.INFO, 'I am about to create (or update) 12 Month Forecast records for Account ' + this.accountNum + ' and Year ' + this.year
            ));
        }
        return null;
    }
    
    /**
     * Continues with the creation of month forecast records based on selected countries.
     * 
     * @return PageReference - Redirects to the account page after processing.
     */
    public PageReference contin() {
        if (!this.isUK && !this.isItaly && !this.isSpain) {
            return null;
        }

        if (this.isUK) {
            createMonths(this.year, 'EN60');
        }
        if (this.isItaly) {
            createMonths(this.year, 'VD30');
        }
        if (this.isSpain) {
            createMonths(this.year, 'VD10');
        }
        
        PageReference pageReference = new PageReference('/' + this.accountId);
        pageReference.setRedirect(true);
        return pageReference;
    }
    
    /**
     * Creates or updates month records for each month of the specified year and sales organization.
     * 
     * @param year - The year for which month records are being created or updated.
     * @param salesOrg - The sales organization code to associate with each month record.
     */
    private void createMonths(String year, String salesOrg) {
        if (String.isBlank(year) || String.isBlank(salesOrg)) {
            return;
        }

        Map<String, Month__c> monthUpsertMap = new Map<String, Month__c>();
        
        if (fProvider == null || fProvider.monthMap == null || fProvider.monthMap.isEmpty()) {
            return;
        }

        for (Integer m = 1; m <= 12; m++) {
            String monthNo = String.valueOf(m).leftPad(2, '0');
            String monthUniqueID = salesOrg + '-' + accountNum.leftPad(7, '0') + '-' + year + '-' + monthNo;
            String name = fProvider.monthMap.get(m);
            Month__c mth = new Month__c(
                Customer__c = this.accountId,
                Name = name,
                Calendar_Month__c = name,
                Year__c = year,
                Sales_Organization__c = salesOrg,
                Unique_ID__c = monthUniqueID
            );
            monthUpsertMap.put(monthUniqueID, mth);
        }

        if (monthUpsertMap.isEmpty()) {
            return;
        }

        upsert monthUpsertMap.values() Unique_ID__c;
    }
}



/*public with sharing class NewMonthForecastExtensionController {
    private ForecastProvider fProvider; 
    private Account a;
    private String accountId;
    private String year;   
    public String accountNum    { get; set; }
    public Boolean isUK {get; set;}
    public Boolean isItaly {get; set;}
    public Boolean isSpain {get; set;}
    
    public NewMonthForecastExtensionController(ApexPages.StandardController stdController) {
        fProvider = new ForecastProvider();
        this.accountId = ApexPages.currentPage().getParameters().get('id');
        system.debug(this.accountId);
        this.a = [select Id, SAP_Account_Number__c from Account where Id = :this.accountId]; 
        this.accountNum = this.a.SAP_Account_Number__c;
        this.year = String.valueOf(System.today().year());      
    }
    
    public PageReference check(){
        if (this.accountNum == null) {
            ApexPages.addmessage(new ApexPages.message(
                ApexPages.severity.ERROR, 'In order to create Month Forecasts an SAP Account Number is required: press Cancel'
            ));         
        } else {
            ApexPages.addmessage(new ApexPages.message(
                ApexPages.severity.INFO, 'I am about to create (or update) 12 Month Forecast records for Account '+this.accountNum+' and Year '+this.year
            ));
        }
        return null;
    }
    
    public PageReference contin() {
        if(this.isUK) {
            createMonths(this.year, 'EN60');
        }
        if(this.isItaly) {
            createMonths(this.year, 'VD30');
        }
        if(this.isSpain) {
            createMonths(this.year, 'VD10');
        }
        PageReference pageReference = new PageReference('/'+this.accountId);
        pageReference.setRedirect(true);
        return pageReference;
    }
    
    private void createMonths(String year, String salesOrg) {
        Map<String, Month__c> monthUpsertMap = new Map<String, Month__c>();
        for (Integer m=1; m<13; m++) {
            String monthNo = String.valueOf(m).leftPad(2).replace(' ','0');
            String monthUniqueID = salesOrg + '-' + accountNum.leftPad(7).replace(' ','0') + '-' + year + '-' + monthNo;
            String name = fProvider.monthMap.get(m);
            Month__c mth = new Month__c(
                Customer__c = this.accountId,
                Name = name,
                Calendar_Month__c = name,
                Year__c = year,
                Sales_Organization__c = salesOrg,
                Unique_ID__c = monthUniqueID
            );
            monthUpsertMap.put(monthUniqueID, mth);
        }                                       
        upsert monthUpsertMap.values() Unique_ID__c;
    }
    
}*/