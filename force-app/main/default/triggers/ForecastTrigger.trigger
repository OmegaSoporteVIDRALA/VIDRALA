/* -----------------------------------------------------------------------------------------------------------------------
   Name:        ForecastTrigger.trigger
   Description: Before insert or update, 
                1) total previous month's budgets
                2) extract Actual Sales History totals
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Oct 2024     2.0     Globant             Refactored 
------------------------------------------------------------------------------------------------------------------------ */        
trigger ForecastTrigger on Forecast__c (before insert, before update) {

    if (trigger.isBefore) {
    
        ForecastHandler handler = new ForecastHandler();
        handler.priorMonthBudgetTotals(Trigger.new);
        handler.salesHistoryTotals(Trigger.new);
    }
}