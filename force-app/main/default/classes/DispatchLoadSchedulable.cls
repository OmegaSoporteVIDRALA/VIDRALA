/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchLoadSchedulable.cls
   Description: Schedule the batch job to upsert records from the Dispatch Staging object to the Dispatch object
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
------------------------------------------------------------------------------------------------------------------------ */
global class DispatchLoadSchedulable implements Schedulable {
    global void execute(SchedulableContext sc) {
        DispatchLoadBatch dlb = new DispatchLoadBatch();
        Database.executeBatch(dlb);   
    }
}