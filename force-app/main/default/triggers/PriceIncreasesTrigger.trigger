/* -----------------------------------------------------------------------------------------------------------------------
   Name:        PriceIncreasesTrigger.trigger
   Description: After insert, share record with Account Owner
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Oct 2024     2.0     Globant             Refactored 
------------------------------------------------------------------------------------------------------------------------ */        
trigger PriceIncreasesTrigger on Price_Increases__c (after insert) {
    
    if (trigger.isAfter && trigger.isInsert) {
        
        ApexSharingManager sharingManager = new ApexSharingManager(
            Schema.SObjectType.Price_Increases__c.Name, 
            Schema.Price_Increases__Share.rowCause.Apex__c
        );
        sharingManager.shareWithAccountOwner(Schema.SObjectType.Price_Increases__c.Fields.Account__c.RelationshipName, Trigger.new); 
    }    
}