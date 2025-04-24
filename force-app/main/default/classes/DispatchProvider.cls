/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchProvider.cls
   Description: Provider class for the Dispatch__c object
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Sep 2024     1.1     Globant             Code refactoring and added comments
------------------------------------------------------------------------------------------------------------------------ */        

public with sharing class DispatchProvider {
    
    /**
     * Retrieves a map of Dispatch__c records by their IDs.
     * 
     * @param idSet - Set of Dispatch__c record IDs.
     * @return A map of Dispatch__c records keyed by their IDs, or an empty map if input is null or empty.
     */
    public Map<ID, Dispatch__c> getDispatchMapById(Set<String> idSet) {
        if (idSet == null || idSet.isEmpty()) {
            return new Map<ID, Dispatch__c>();
        }
        
        return new Map<ID, Dispatch__c>([
            SELECT
                Id, Name, Month__c, Week__c, Week_in_Month__c, Dispatch_ID__c, 
                Dispatch_Date__c, Dispatch_Time__c, Dispatch_Date_Time__c, Delivery_Code__c, 
                Customer__c, Customer_ID__c, Customer__r.Name, Bottle__c, Bottle_Identifier__c, Bottle__r.Name,
                Haulier__c, Haulier_Code__c, Haulier__r.Name, Freight_Reference__c, 
                Warehouse_ID__c, Units__c, Type__c, Tonnage__c, 
                Staging_Id__c, Site_ID__c, Planned_Delivery_Date__c, Pack_Specification__c, 
                Collapsed_Loads__c, Late_Loads__c, Early_Loads__c, Early_Late_Collapsed_Loads__c, On_Time_Loads__c, Early_or_Late_Loads__c,
                Load_Job_Id__c, Collapsed__c, Delivery_Status__c,
                Weight_per_Unit__c
            FROM 
                Dispatch__c 
            WHERE
                Id in :idSet
        ]);
    }
    
    /**
     * Retrieves a Dispatch__c record by its ID.
     * 
     * @param id - ID of the Dispatch__c record.
     * @return The Dispatch__c record with the given ID, or null if input is null or empty, or if the record is not found.
     */
    public Dispatch__c getDispatchById(String id) {
        if (String.isBlank(id)) {
            return null;
        }

        Map<ID, Dispatch__c> dispatchMap = getDispatchMapById(new Set<String>{id});
        return dispatchMap.get(id);
    }
    
    /**
     * Retrieves aggregate totals of late load metrics for the current month.
     * 
     * @return A list of AggregateResult objects containing totals of various late load metrics, or an empty list if no records found.
     */
    public List<AggregateResult> currentMonthLateLoadTotals() {
        List<AggregateResult> results = [
            SELECT
                Customer__r.Name customer,
                SUM(On_Time_Loads__c) ontime,
                SUM(Early_Loads__c) early,
                SUM(Late_Loads__c) late,
                SUM(Collapsed_Loads__c) collapsed,
                SUM(Early_or_Late_Loads__c) earlyOrLate,
                SUM(Early_Late_Collapsed_Loads__c) earlyLateCollapsed
            FROM
                Dispatch__c
            WHERE
                Current_Month_Delivery__c = true
            AND
                Exclude_from_OTIF__c = false
            GROUP BY
                Customer__r.Name
            HAVING
                SUM(Early_Late_Collapsed_Loads__c) > 0
        ];
        
        if (results == null || results.isEmpty()) {
            return new List<AggregateResult>();
        } else {
            return results;
        }
    }
    
    /**
     * Retrieves aggregate totals of late load metrics for the last 48 hours.
     * 
     * @return A list of AggregateResult objects containing totals of various late load metrics for the last 48 hours, or an empty list if no records found.
     */
    public List<AggregateResult> last48hourLateLoadTotals() {
        List<AggregateResult> results = [
            SELECT
                Customer__r.Name customer,
                SUM(On_Time_Loads__c) ontime,
                SUM(Early_Loads__c) early,
                SUM(Late_Loads__c) late,
                SUM(Collapsed_Loads__c) collapsed,
                SUM(Early_or_Late_Loads__c) earlyOrLate,
                SUM(Early_Late_Collapsed_Loads__c) earlyLateCollapsed
            FROM
                Dispatch__c
            WHERE
                (Last_48_Hour_Late_Early_Delivery__c = true OR Last_48_Hour_Collapse__c = true)
            AND
                Exclude_from_OTIF__c = false
            GROUP BY
                Customer__r.Name
        ];

        if (results == null || results.isEmpty()) {
            return new List<AggregateResult>();
        } else {
            return results;
        }
    }
}


/*public with sharing class DispatchProvider {
    
    public Map<ID, Dispatch__c> getDispatchMapById(Set<String> idSet) {
        return new Map<ID, Dispatch__c> ([
            SELECT
                Id, Name, Month__c, Week__c, Week_in_Month__c, Dispatch_ID__c, 
                Dispatch_Date__c, Dispatch_Time__c, Dispatch_Date_Time__c, Delivery_Code__c, 
                Customer__c, Customer_ID__c, Customer__r.Name, Bottle__c, Bottle_Identifier__c, Bottle__r.Name,
                Haulier__c, Haulier_Code__c, Haulier__r.Name, Freight_Reference__c, 
                Warehouse_ID__c, Units__c, Type__c, Tonnage__c, 
                Staging_Id__c, Site_ID__c, Planned_Delivery_Date__c, Pack_Specification__c, 
                Collapsed_Loads__c, Late_Loads__c, Early_Loads__c, Early_Late_Collapsed_Loads__c, On_Time_Loads__c, Early_or_Late_Loads__c,
                Load_Job_Id__c, Collapsed__c, Delivery_Status__c,
                Weight_per_Unit__c
            FROM 
                Dispatch__c 
            WHERE
                Id in :idSet
        ]);
    }
    
    public Dispatch__c getDispatchById(String id) {
        Map<ID, Dispatch__c> dispatchMap = getDispatchMapById(new Set<String>{id});
        return dispatchMap.get(id);
    }
    
    public List<AggregateResult> currentMonthLateLoadTotals() {
        return [
            SELECT
                Customer__r.Name customer,
                SUM(On_Time_Loads__c) ontime,
                SUM(Early_Loads__c) early,
                SUM(Late_Loads__c) late,
                SUM(Collapsed_Loads__c) collapsed,
                SUM(Early_or_Late_Loads__c) earlyOrLate,
                SUM(Early_Late_Collapsed_Loads__c) earlyLateCollapsed
            FROM
                Dispatch__c
            WHERE
                Current_Month_Delivery__c = true
            AND
                Exclude_from_OTIF__c = false
            GROUP BY
                Customer__r.Name
            HAVING
                SUM(Early_Late_Collapsed_Loads__c) > 0
        ];
    }
    
    public List<AggregateResult> last48hourLateLoadTotals() {
        return [
            SELECT
                Customer__r.Name customer,
                SUM(On_Time_Loads__c) ontime,
                SUM(Early_Loads__c) early,
                SUM(Late_Loads__c) late,
                SUM(Collapsed_Loads__c) collapsed,
                SUM(Early_or_Late_Loads__c) earlyOrLate,
                SUM(Early_Late_Collapsed_Loads__c) earlyLateCollapsed
            FROM
                Dispatch__c
            WHERE
                (Last_48_Hour_Late_Early_Delivery__c = true OR Last_48_Hour_Collapse__c = true)
            AND
                Exclude_from_OTIF__c = false
            GROUP BY
                Customer__r.Name
        ];
    }
}*/