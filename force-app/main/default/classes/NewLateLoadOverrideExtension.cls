/* -----------------------------------------------------------------------------------------------------------------------
   Name:        NewLateLoadOverrideExtension.cls
   Description: Extension controller class for enforcing creation of new records from Dispatches.

   Date         Version Author              Summary of Changes
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release
   Sep 2024     1.1     Globant             Added Comments
------------------------------------------------------------------------------------------------------------------------ */

public with sharing class NewLateLoadOverrideExtension {
    
    /**
     * Constructor for NewLateLoadOverrideExtension.
     * 
     * @param stdController - The standard controller instance for the page.
     */
    public NewLateLoadOverrideExtension(ApexPages.StandardController stdController) {
    }
    
    /**
     * Displays an error message indicating that new Late Load records must be created from the Dispatch Detail Page.
     * 
     * @return PageReference - Returns null, as the method is used to display an error message.
     */
    public PageReference abortAction(){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, 'New Late Load records must be created from the Dispatch Detail Page'));
        return null;
    }

    /**
     * Redirects the user to the list view of Late Load records.
     * 
     * @return PageReference - Redirects to the Late Load object list view.
     */
    public PageReference cancel() {
        Schema.DescribeSObjectResult schema = Late_Load__c.SObjectType.getDescribe();
        String objectIdPrefix = schema.getKeyPrefix();
        PageReference pageReference = new PageReference('/'+objectIdPrefix+'/o');
        pageReference.setRedirect(true);
        return pageReference;
    }
    
}


/*public with sharing class NewLateLoadOverrideExtension {
    
    public NewLateLoadOverrideExtension(ApexPages.StandardController stdController) {
    }
    
    public PageReference abortAction(){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, 'New Late Load records must be created from the Dispatch Detail Page'));
        return null;
    }

    public PageReference cancel() {
        Schema.DescribeSObjectResult schema = Late_Load__c.SObjectType.getDescribe();
        String objectIdPrefix = schema.getKeyPrefix();
        PageReference pageReference = new PageReference('/'+objectIdPrefix+'/o');
        pageReference.setRedirect(true);
        return pageReference;
    }
    
}*/