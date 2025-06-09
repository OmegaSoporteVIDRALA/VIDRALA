/* -----------------------------------------------------------------------------------------------------------------------
   Name:        AccountTrigger.trigger
   Description: After update, recalculate child object Apex sharing if Account Owner has changed 
                or Recalculate_Apex_Sharing__c = true
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2016     1.0     M.Witchalls(Ciber)  Initial Release 
   Mar 2017     1.1     M.Witchalls(Cloud9) Change Month Forecast Owners when Account Owner is changed  
------------------------------------------------------------------------------------------------------------------------ */        

trigger AccountTrigger on Account (before insert, before update, after insert, after update, before delete) {
    if(!OM_Utils.shouldSkipTriggerGlobal){
		OM_VID_AccountTRGHandler.execute(trigger.new, trigger.oldMap, trigger.isBefore, trigger.isAfter, trigger.isInsert, trigger.isUpdate, trigger.isDelete);
        if (trigger.isAfter && trigger.isUpdate) {
            
            AccountTriggerHandler.processAccountRecords(trigger.new, trigger.oldMap);
        }
    }
}