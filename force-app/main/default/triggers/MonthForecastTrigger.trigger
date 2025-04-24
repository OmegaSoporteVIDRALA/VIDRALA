/* -----------------------------------------------------------------------------------------------------------------------
   Name:        MonthForecastTrigger.trigger
   Description: Before insert or update, copy Account Owner to record Owner
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Oct 2024     2.0     Globant             Refactored 
------------------------------------------------------------------------------------------------------------------------ */        
trigger MonthForecastTrigger on Month__c (before insert, before update) {
    
    if (trigger.isBefore) {
    
        ForecastHandler handler = new ForecastHandler();
        handler.copyAccountOwner(Trigger.new);
    }
}