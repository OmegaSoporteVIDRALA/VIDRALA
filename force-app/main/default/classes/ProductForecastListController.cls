/* -----------------------------------------------------------------------------------------------------------------------
   Name:        ProductForecastListController.cls
   Description: List controller class for Forecast Lists
                    
   Date         Version Author              Summary of Changes
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release
   Sep 2024     1.1     Globant             Code Refactoring and Added Comments
------------------------------------------------------------------------------------------------------------------------ */

public with sharing class ProductForecastListController {
    
    private Month__c thisMonthTotals;

    /**
     * Gets the StandardSetController for Forecast records, initializing it with records for the current month
     * and setting the page size to 1000.
     * 
     * @return ApexPages.StandardSetController - The StandardSetController for Forecast records.
     */
    public ApexPages.StandardSetController setCon {
        get {
            String customerNo = ApexPages.currentPage().getParameters().get('customerNo');
            if (String.isBlank(customerNo)) {
                return null;
            }

            if (setCon == null) {
                List<Forecast__c> fList = new List<Forecast__c>();
                ForecastHandler handler = new ForecastHandler();
                ForecastProvider provider = new ForecastProvider();

                Set<ID> monthIdSet = new Set<ID>();
                for (Month__c m : [
                    SELECT Id 
                    FROM Month__c 
                    WHERE Is_Current_Month__c = true 
                    AND Customer_A_c_No__c = :customerNo
                ]) {
                    monthIdSet.add(m.Id);
                }

                if (monthIdSet.isEmpty()) {
                    return null;
                }

                if (monthIdSet.size() > 0) {
                    Map<ID, Month__c> monthMap = provider.getMonthsById(monthIdSet);

                    if (monthMap.isEmpty()) {
                        return null;
                    }

                    thisMonthTotals = monthMap.values()[0];
                    fList = provider.getForecastListByMonthId(monthIdSet);
                }

                setCon = new ApexPages.StandardSetController(fList);
                setCon.setPageSize(1000);
            }
            return setCon;
        }
        set;
    }

    /**
     * Gets the list of fields for the 'unitsList' field set on the Forecast__c object.
     * 
     * @return List<Schema.FieldSetMember> - List of fields in the 'unitsList' field set.
     */
    public List<Schema.FieldSetMember> getUnitsList() {
        if (SObjectType.Forecast__c.FieldSets.unitsList != null) {
            return SObjectType.Forecast__c.FieldSets.unitsList.getFields();
        }
        return new List<Schema.FieldSetMember>();
    }

    /**
     * Gets the list of fields for the 'tonnageList' field set on the Forecast__c object.
     * 
     * @return List<Schema.FieldSetMember> - List of fields in the 'tonnageList' field set.
     */
    public List<Schema.FieldSetMember> getTonnageList() {
        if (SObjectType.Forecast__c.FieldSets.tonnageList != null) {
            return SObjectType.Forecast__c.FieldSets.tonnageList.getFields();
        }
        return new List<Schema.FieldSetMember>();
    }

    /**
     * Gets the list of fields for the 'unitsList' field set on the Month__c object.
     * 
     * @return List<Schema.FieldSetMember> - List of fields in the 'unitsList' field set.
     */
    public List<Schema.FieldSetMember> getCustomerUnitsList() {
        if (SObjectType.Month__c.FieldSets.unitsList != null) {
            return SObjectType.Month__c.FieldSets.unitsList.getFields();
        }
        return new List<Schema.FieldSetMember>();
    }

    /**
     * Gets the list of fields for the 'tonnageList' field set on the Month__c object.
     * 
     * @return List<Schema.FieldSetMember> - List of fields in the 'tonnageList' field set.
     */
    public List<Schema.FieldSetMember> getCustomerTonnageList() {
        // Guard block: Ensure that the field set exists
        if (SObjectType.Month__c.FieldSets.tonnageList != null) {
            return SObjectType.Month__c.FieldSets.tonnageList.getFields();
        }
        return new List<Schema.FieldSetMember>();
    }

    /**
     * Initializes the setCon and returns a list of Forecast__c records.
     * 
     * @return List<Forecast__c> - The list of Forecast__c records.
     */
    public List<Forecast__c> getRecords() {
        if (setCon == null) {
            return new List<Forecast__c>();
        }
        return (List<Forecast__c>) setCon.getRecords();
    }

    /**
     * Returns the totals for the current month.
     * 
     * @return Month__c - The current month's totals.
     */
    public Month__c getTotals() {
        if (thisMonthTotals == null) {
            return null;
        }
        return thisMonthTotals;
    }
}


/*public with sharing class ProductForecastListController {
    
    private Month__c thisMonthTotals;
    
    public ApexPages.StandardSetController setCon {
        get {
            if(setCon == null) {
                List<Forecast__c> fList = new List<Forecast__c>();
                ForecastHandler handler = new ForecastHandler();
                ForecastProvider provider = new ForecastProvider();
                String customerNo = ApexPages.currentPage().getParameters().get('customerNo');
                Set<ID> monthIdSet = new Set<ID>();
                for (Month__c m: [SELECT Id FROM Month__c WHERE Is_Current_Month__c = true AND Customer_A_c_No__c = :customerNo]) {
                    monthIdSet.add(m.Id);
                }
                if (MonthIdSet.size() > 0) {
                    Map<ID, Month__c> monthMap = provider.getMonthsById(monthIdSet);
                    thisMonthTotals = monthMap.values()[0];
                    fList = provider.getForecastListByMonthId(monthIdSet);
                }           
                setCon = new ApexPages.StandardSetController(fList);
                setCon.setPageSize(1000);
            }
            return setCon;
        }
        set;
    }
    
    public List<Schema.FieldSetMember> getUnitsList() {
        return SObjectType.Forecast__c.FieldSets.unitsList.getFields();
    }
    
    public List<Schema.FieldSetMember> getTonnageList() {
        return SObjectType.Forecast__c.FieldSets.tonnageList.getFields();
    }
    
    public List<Schema.FieldSetMember> getCustomerUnitsList() {
        return SObjectType.Month__c.FieldSets.unitsList.getFields();
    }
    
    public List<Schema.FieldSetMember> getCustomerTonnageList() {
        return SObjectType.Month__c.FieldSets.tonnageList.getFields();
    }
    
    // Initialize setCon and return a list of records
    public List<Forecast__c> getRecords() {
        return (List<Forecast__c>) setCon.getRecords();
    }    
    
    // Return the customer totals
    public Month__c getTotals() {
        return thisMonthTotals;
    }    
}*/