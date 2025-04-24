/* -----------------------------------------------------------------------------------------------------------------------
   Name:        ActualSalesHistoryTrigger.trigger
   Description: Update affected Forecast records immediately after Actual Sales History is loaded
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Oct 2024     2.0     Globant             Refactored 
------------------------------------------------------------------------------------------------------------------------ */        
trigger ActualSalesHistoryTrigger on Actual_Sales_History__c (after insert, after update, after delete, after undelete) {
    
    if (trigger.isAfter) {
        
        ForecastHandler handler = new ForecastHandler();
        
        if (trigger.isDelete) {
        
            handler.newSalesHistoryTotals(Trigger.old);
        } else {
         
            handler.newSalesHistoryTotals(Trigger.new);
        }
    }
}