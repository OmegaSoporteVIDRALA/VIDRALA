/* -----------------------------------------------------------------------------------------------------------------------
   Name:        CommercialContractsTrigger.trigger
   Description: After insert, share record with Account Owner
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Oct 2024     2.0     Globant             Refactored 
------------------------------------------------------------------------------------------------------------------------ */        
trigger CommercialContractsTrigger on Commercial_Contracts__c (after insert) {
    
    if (trigger.isAfter && trigger.isInsert) {
        
        ApexSharingManager sharingManager = new ApexSharingManager(
            Schema.SObjectType.Commercial_Contracts__c.Name, 
            Schema.Rebate__Share.rowCause.Apex__c
        );
        
        sharingManager.shareWithAccountOwner(Schema.SObjectType.Commercial_Contracts__c.Fields.Account__c.RelationshipName, trigger.new); 
    }
}