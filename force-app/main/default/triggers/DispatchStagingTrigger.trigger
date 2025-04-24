/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchStagingTrigger.trigger
   Description: Before insert, assign dummy batch numbers to spurious duplicates 
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Jun 2018     1.0     M.Witchalls(Cloud9) Initial Release 
------------------------------------------------------------------------------------------------------------------------ */        

trigger DispatchStagingTrigger on Dispatch_Staging__c (before insert) {
    DispatchStagingHandler handler = new DispatchStagingHandler();
    handler.handleSpuriousDups(Trigger.new);
}