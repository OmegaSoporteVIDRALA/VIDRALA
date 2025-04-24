/* -----------------------------------------------------------------------------------------------------------------------
   Name:        AccountTrigger.trigger
   Description: After update, recalculate child object Apex sharing if Account Owner has changed 
                or Recalculate_Apex_Sharing__c = true
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2016     1.0     M.Witchalls(Ciber)  Initial Release 
   Mar 2017     1.1     M.Witchalls(Cloud9) Change Month Forecast Owners when Account Owner is changed  
   Oct 2024     2.0     Globant             Refactored
------------------------------------------------------------------------------------------------------------------------ */        

trigger AccountTrigger on Account (after update) {
    
    if (trigger.isAfter && trigger.isUpdate) {
        
        AccountTriggerHandler.processAccountRecords(trigger.new, trigger.oldMap);
    }
}