/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DealSheetTrigger.trigger
   Description: After insert, share record with Account Owner
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Oct 2024     2.0     Globant             Refactored 
------------------------------------------------------------------------------------------------------------------------ */        
trigger DealSheetTrigger on Deal_Sheet__c (after insert) {

    if (trigger.isAfter && trigger.isInsert) {
        
        ApexSharingManager sharingManager = new ApexSharingManager(
            Schema.SObjectType.Deal_Sheet__c.Name, 
            Schema.Deal_Sheet__Share.rowCause.Apex__c
        );
        sharingManager.shareWithAccountOwner(Schema.SObjectType.Deal_Sheet__c.Fields.ACCOUNT__c.RelationshipName, Trigger.new); 
    }
}