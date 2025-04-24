/* -----------------------------------------------------------------------------------------------------------------------
   Name:        SalesHistoryProvider.cls
   Description: Provider class for the Actual_Sales_History__c object

   Date         Version Author              Summary of Changes
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release
   Sep 2024     1.1     Globant             In Progress(To be Updated)
------------------------------------------------------------------------------------------------------------------------ */

public with sharing class SalesHistoryProvider{

    /**
     * Retrieves `Actual_Sales_History__c` records filtered by account IDs, product names, and year,
     * and organizes them into a map grouped by account ID and product name.
     *
     * @param accountIdSet Set<Id> - A set of account IDs to filter the records.
     * @param prodNameSet Set<String> - A set of product names to filter the records.
     * @param year String - The year to filter the records.
     * @return Map<String, List<Actual_Sales_History__c>> - A map where the key is a combination of account ID and product name,
     *         and the value is a list of `Actual_Sales_History__c` records that match the criteria.
     */
    public Map<String, List<Actual_Sales_History__c>> getSalesHistorysByAccountProduct2(Set<ID> accountIdSet, Set<String> prodNameSet, String year){
        if (accountIdSet == null || accountIdSet.isEmpty()) {
            return new Map<String, List<Actual_Sales_History__c>>();
        }

        if (prodNameSet == null || prodNameSet.isEmpty()) {
            return new Map<String, List<Actual_Sales_History__c>>();
        }

        if (String.isBlank(year)) {
            return new Map<String, List<Actual_Sales_History__c>>();
        }

        Map<String, List<Actual_Sales_History__c>> returnMap = new Map<String, List<Actual_Sales_History__c>>();

        for (List<Actual_Sales_History__c> sList : [
            SELECT
                Id, Name, Account__c, Month__c, Item__c,
                SAP_Material_Code__c, SAP_Material_Code__r.Name, 
                SAP_Material_Code__r.Bottle__c, Bottle__r.Bottle_Identifier__c,
                Date__c, Year__c, Volume_000_s__c, Tonnes__c
            FROM 
                Actual_Sales_History__c
            WHERE
                Account__c IN :accountIdSet
            AND
                Item__c IN :prodNameSet
            AND
                Year__c = :year
        ]) {
            for (Actual_Sales_History__c s : sList) {
                String keyString = s.Account__c + ':' + s.Item__c;

                if (s.Account__c != null && s.Item__c != null) {
                    List<Actual_Sales_History__c> ashList = returnMap.get(keyString);
                    if (ashList == null) {
                        ashList = new List<Actual_Sales_History__c>();
                    }
                    ashList.add(s);
                    returnMap.put(keyString, ashList);
                }
            }
        }

        return returnMap;
    }
}



/*public with sharing class SalesHistoryProvider {
    
    public Map<String, List<Actual_Sales_History__c>> getSalesHistorysByAccountProduct2(
        Set<ID> accountIdSet, Set<String> prodNameSet, String year
    ) {
        Map<String, List<Actual_Sales_History__c>> returnMap = new Map<String, List<Actual_Sales_History__c>>();
        for (List<Actual_Sales_History__c> sList: [
            SELECT
                Id, Name, Account__c, Month__c, Item__c, 
                SAP_Material_Code__c, SAP_Material_Code__r.Name, SAP_Material_Code__r.Bottle__c, Bottle__r.Bottle_Identifier__c,
                Date__c, Year__c, Volume_000_s__c, Tonnes__c             
            FROM 
                Actual_Sales_History__c 
            WHERE
                Account__c IN :accountIdSet
            AND
                Item__c IN :prodNameSet
            AND
                Year__c = :year
        ]) {
            for (Actual_Sales_History__c s: sList) {
                String keyString = s.Account__c + ':' + s.Item__c;
                
                List<Actual_Sales_History__c> ashList = returnMap.get(keyString);
                if (ashList == null) ashList = new List<Actual_Sales_History__c>();
                ashList.add(s);
                returnMap.put(keyString, ashList);
            }
        }
        return returnMap;
    }
    
}*/