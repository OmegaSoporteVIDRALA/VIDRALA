/* -----------------------------------------------------------------------------------------------------------------------
   Name:        LateLoadHandler.cls
   Description: Handler class for processing of the Late_Load__c object
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
------------------------------------------------------------------------------------------------------------------------ */      
public with sharing class LateLoadHandler {
    private static final String lateLoadObjectName = Schema.SObjectType.Late_Load__c.Name;
    
    // Get Record Types by Developer Name
    public Map<String, RecordType> getRecordTypeMap() {
        Map<String, RecordType> rtMap = new Map<String, RecordType>();
        for (RecordType rt: [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType = :lateLoadObjectName]) {
            rtMap.put(rt.DeveloperName, rt);
        } 
        return rtMap;
    }    
    
}