/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchStagingTrigger.trigger
   Description: Before insert, assign dummy batch numbers to spurious duplicates
				Before insert, clean time fields and populate values to salesforce unique id and encirc account number fields
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Jun 2018     1.0     M.Witchalls(Cloud9) Initial Release 
   Aug 2025		2.0		Globant				Added new class methods to trigger
------------------------------------------------------------------------------------------------------------------------ */        

trigger DispatchStagingTrigger on Dispatch_Staging__c (before insert,after insert) {
    DispatchStagingHandler handler = new DispatchStagingHandler();
    if(Trigger.isBefore){
        if(Trigger.isInsert){
    		handler.handleSpuriousDups(Trigger.new);
        }
    }
    if(Trigger.isBefore && Trigger.isInsert){

        DispatchStagingValidation.cleanTimeFields(Trigger.new);
        DispatchStagingValidation.populateDerivedFields(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        Set<Id> insertedIds = new Set<Id>();
        for (Dispatch_Staging__c rec : Trigger.new) {
            if (String.isNotBlank(rec.Salesforce_Unique_Id__c)) {
                insertedIds.add(rec.Id);
            }
        }
    }
}
