/* -----------------------------------------------------------------------------------------------------------------------
   Name:        PricingModelTrigger.trigger
   Description: After insert, share record with Account Owner
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Oct 2024     2.0     Globant             Refactored 
------------------------------------------------------------------------------------------------------------------------ */        
trigger PricingModelTrigger on Pricing_Model__c (after insert) {
    
    if (trigger.isAfter && trigger.isInsert) {
        
        ApexSharingManager sharingManager = new ApexSharingManager(
            Schema.SObjectType.Pricing_Model__c.Name, 
            Schema.Pricing_Model__Share.rowCause.Apex__c
        );
        sharingManager.shareWithAccountOwner(Schema.SObjectType.Pricing_Model__c.Fields.Account__c.RelationshipName, Trigger.new); 
    }
    
}