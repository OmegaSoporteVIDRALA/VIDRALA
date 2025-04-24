/* -----------------------------------------------------------------------------------------------------------------------
   Name:        ForecastProvider.cls
   Description: Provider class for the Forecast__c object.
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2016     1.0     M.Witchalls(Ciber)  Initial Release 
   Mar 2017     1.1     M.Witchalls(Cloud9) Change Month Forecast Owners when Account Owner is changed  
   Dec 2017     1.2     M.Witchalls(Cloud9) Addition of DTG fields
   May 2018     2.0     M.Witchalls(Cloud9) Actual Sales History and Forecast records now include SAP Material Code
   Sep 2024     3.0     Globant             Refactor
------------------------------------------------------------------------------------------------------------------------ */        
public class ForecastProvider {

    // Mapping of month numbers to their respective abbreviations
    public Map<Integer, String> monthMap = new Map<Integer, String>{
        1 => 'JAN', 2 => 'FEB', 3 => 'MAR', 4 => 'APR', 5 => 'MAY', 6 => 'JUN', 
        7 => 'JUL', 8 => 'AUG', 9 => 'SEP', 10 => 'OCT', 11 => 'NOV', 12 => 'DEC'
    };

    /**
     * Retrieves a map of Account IDs to their respective Owner IDs.
     *
     * @param accountIdSet Set of Account IDs.
     * @return Map of Account IDs to Owner IDs.
     */
    public Map<ID, ID> getAccountOwnersByAccountId(Set<ID> accountIdSet) {
        // Guard clause to check for empty input
        if (accountIdSet == null || accountIdSet.isEmpty()) {
            return new Map<ID, ID>();
        }

        Map<ID, ID> accountOwnerMap = new Map<ID, ID>();
        for (Account a : [SELECT Id, OwnerId, Encirc_Account_Number__c FROM Account WHERE Id IN :accountIdSet]) {
            accountOwnerMap.put(a.Id, a.OwnerId);
        }
        return accountOwnerMap;
    }

    /**
     * Retrieves a map of Account IDs to Accounts, including related Month records.
     *
     * @param accountIdSet Set of Account IDs.
     * @return Map of Account IDs to Accounts with related Month records.
     */
    public Map<ID, Account> getMonthsByAccountId(Set<ID> accountIdSet) {
        // Guard clause for empty input
        if (accountIdSet == null || accountIdSet.isEmpty()) {
            return new Map<ID, Account>();
        }

        return new Map<ID, Account>([
            SELECT Id, OwnerId, Encirc_Account_Number__c, (SELECT Id, OwnerId FROM Months__r)
            FROM Account
            WHERE Id IN :accountIdSet
        ]);
    }

    /**
     * Retrieves a map of Account IDs to their respective SAP and Encirc Account Numbers.
     *
     * @param accountIdSet Set of Account IDs.
     * @return Map of Account IDs to Accounts with SAP and Encirc Account Numbers.
     */
    public Map<ID, Account> getAccountNumsByAccountId(Set<ID> accountIdSet) {
        // Guard clause for empty input
        if (accountIdSet == null || accountIdSet.isEmpty()) {
            return new Map<ID, Account>();
        }

        return new Map<ID, Account>([
            SELECT Id, SAP_Account_Number__c, Encirc_Account_Number__c FROM Account WHERE Id IN :accountIdSet       
        ]);
    }

    /**
     * Retrieves a map of Bottle__c records by their IDs.
     *
     * @param prodIdSet Set of Product IDs (Bottle__c).
     * @return Map of Product IDs to Bottle__c records.
     */
    public Map<ID, Bottle__c> getProductById(Set<ID> prodIdSet) {
        // Guard clause for empty input
        if (prodIdSet == null || prodIdSet.isEmpty()) {
            return new Map<ID, Bottle__c>();
        }

        return new Map<ID, Bottle__c>([
            SELECT Id, Name, SAP_Model_Number__c, Bottle_Identifier__c, Weight_per_Unit__c FROM Bottle__c 
            WHERE Id IN :prodIdSet
        ]);
    }

    /**
     * Retrieves a map of Bottle__c records by their names.
     *
     * @param prodNameSet Set of Bottle Names (Bottle__c).
     * @return Map of Product Names to Bottle__c records.
     */
    public Map<String, Bottle__c> getProductByName(Set<String> prodNameSet) {
        // Guard clause for empty input
        if (prodNameSet == null || prodNameSet.isEmpty()) {
            return new Map<String, Bottle__c>();
        }

        Map<String, Bottle__c> bMap = new Map<String, Bottle__c>();
        for (Bottle__c b : [
            SELECT Id, Name, SAP_Model_Number__c, Bottle_Identifier__c, Weight_per_Unit__c 
            FROM Bottle__c 
            WHERE Bottle_Identifier__c IN :prodNameSet
        ]) {
            bMap.put(b.Bottle_Identifier__c, b);
        }
        return bMap;
    }

    /**
     * Retrieves a map of SAP Material Code records by their IDs.
     *
     * @param materialIdSet Set of Material Code IDs.
     * @return Map of Material Code IDs to SAP_Material_Code__c records.
     */
    public Map<ID, SAP_Material_Code__c> getSAPMaterialCodeById(Set<ID> materialIdSet) {
        // Guard clause for empty input
        if (materialIdSet == null || materialIdSet.isEmpty()) {
            return new Map<ID, SAP_Material_Code__c>();
        }

        return new Map<ID, SAP_Material_Code__c>([
            SELECT Id, Name, Bottle__c, Bottle__r.SAP_Model_Number__c, Material_Code_Key__c
            FROM SAP_Material_Code__c 
            WHERE Id IN :materialIdSet
        ]);
    }

    /**
     * Retrieves a map of Bottle__c records by their IDs.
     *
     * @param productIdSet Set of Product IDs (Bottle__c).
     * @return Map of Product IDs to Bottle__c records.
     */
    public Map<ID, Bottle__c> getProductMap(Set<ID> productIdSet) {
        // Guard clause for empty input
        if (productIdSet == null || productIdSet.isEmpty()) {
            return new Map<ID, Bottle__c>();
        }

        return new Map<ID, Bottle__c>([
            SELECT Id, Name, Bottle_Identifier__c
            FROM Bottle__c 
            WHERE Id IN :productIdSet
        ]);
    }

    /**
     * Retrieves a map of Month__c records by their IDs.
     *
     * @param monthIdSet Set of Month IDs.
     * @return Map of Month IDs to Month__c records.
     */
    public Map<ID, Month__c> getMonthsById(Set<ID> monthIdSet) {
        // Guard clause for empty input
        if (monthIdSet == null || monthIdSet.isEmpty()) {
            return new Map<ID, Month__c>();
        }

        return new Map<ID, Month__c>([
            SELECT Id, Name, Year__c, Customer__c, Customer_Name__c, Customer_A_c_No__c, Customer_Name_Text__c, Unique_ID__c, Month_Number__c, Calendar_Month__c, 
                Budget__c, Forecast__c, Budget_Tonnage__c, Forecast_Tonnage__c,
                Budget_Rounded__c, Forecast_Rounded__c, Budget_Tonnage_Rounded__c, Forecast_Tonnage_Rounded__c,
                Risks__c, Upsides__c, Risk_Upside_Comments__c, Risk_Tonnage__c, Upside_Tonnage__c, 
                Revised_T_Forecast__c, Revised_Forecast__c, Var_to_Forecast__c, T_Var_to_Forecast__c,
                Adh_to_Fcast__c, Adh_to_Rev_Fcast__c, Adh_to_T_Fcast__c, Adh_to_Rev_T_Fcast__c,
                Year_Total__c, T_Year_Total__c, Year_Forecast__c, T_Year_Forecast__c, 
                Year_Budget__c, T_Year_Budget__c, Year_Var_to_Budget__c, T_Year_Var_to_Budget__c,
                Prior_Year__c, T_Prior_Year__c, Year_Prior_Yr__c, T_Year_Prior_Yr__c,
                Total_Units_Rounded__c, Total_Tonnage_Rounded__c, DTG__c, DTG_Tonnage__c,
                Week_1_Units_Rounded__c, Week_2_Units_Rounded__c, Week_3_Units_Rounded__c,
                Week_4_Units_Rounded__c, Week_5_Units_Rounded__c, Week_6_Units_Rounded__c,
                Week_1_Tonnage_Rounded__c, Week_2_Tonnage_Rounded__c, Week_3_Tonnage_Rounded__c,
                Week_4_Tonnage_Rounded__c, Week_5_Tonnage_Rounded__c, Week_6_Tonnage_Rounded__c 
            FROM Month__c
            WHERE Id IN :monthIdSet
        ]);
    }

    /**
     * Retrieves a list of current Month__c records for current month units.
     *
     * @return List of Month__c records for the current month.
     */
    public List<Month__c> currentMonthUnits() {
        return [
            SELECT Id, Name, Year__c, Customer__c, Customer_Name__c, Customer_Name_Text__c, Customer_A_c_No__c, 
                   Total_Units_Rounded__c, Risks__c, Upsides__c, Budget__c, Forecast__c, 
                   Revised_Forecast__c, Adh_to_Fcast__c, Adh_to_Rev_Fcast__c, DTG__c
            FROM Month__c
            WHERE Is_Current_Month__c = true
            ORDER BY Revised_Forecast__c DESC
            LIMIT 20
        ];
    }

    /**
     * Retrieves aggregate totals for the current month's units.
     *
     * @return AggregateResult containing the totals for the current month's units.
     */
    public AggregateResult currentMonthUnitTotals() {
        List<AggregateResult> rList = [
            SELECT SUM(Total_Units_Rounded__c) actual, SUM(Risks__c) risks, SUM(Upsides__c) opps, 
                   SUM(Budget__c) budget, SUM(Forecast__c) forecast, SUM(Revised_Forecast__c) revised, 
                   SUM(DTG__c) dtg
            FROM Month__c
            WHERE Is_Current_Month__c = true
        ];
        return rList.isEmpty() ? null : rList[0];
    }

    /**
     * Retrieves a list of Forecast__c records based on account IDs, product IDs, bottle identifiers, and year.
     * 
     * @param accountIdSet A set of account IDs to filter the forecasts.
     * @param prodIdSet A set of product IDs to filter the forecasts.
     * @param identifierIdSet A set of bottle identifiers to filter the forecasts.
     * @param year The year for which the forecasts are to be retrieved.
     * @return A list of Forecast__c records matching the criteria.
     */
    public List<Forecast__c> getForecastListByAccountProductAndBottleId(Set<ID> accountIdSet, Set<ID> prodIdSet, Set<String> identifierIdSet, String year) {
        // Guard clause: Return an empty list if any set or year is null or empty
        if (accountIdSet == null || prodIdSet == null || identifierIdSet == null || String.isEmpty(year)) {
            return new List<Forecast__c>();
        }

        List<Forecast__c> returnList = new List<Forecast__c>();
        
        for (List<Forecast__c> fList: [
            SELECT
                Id, Name, Month__c, Month_No__c, Calendar_Month__c, Year__c, Month__r.Customer__c, Customer_A_c_No__c,
                Product__c, Product__r.Bottle_Identifier__c, Product_Name__c, Product_Description__c, SAP_Material_Code__c, SAP_Material_Code__r.Name, Unique_ID__c,
                Budget__c, Budget_Tonnage__c, Forecast__c, Forecast_Tonnage__c, 
                Total_Units_Rounded__c, Total_Tonnage_Rounded__c, Total_Actual_Units__c, Total_Actual_Tonnage__c, Month__r.Customer__r.SAP_Account_Number__c
            FROM 
                Forecast__c 
            WHERE
                Month__r.Customer__c in :accountIdSet
            AND
                (Product__c IN :prodIdSet OR Product__r.Bottle_Identifier__c IN :identifierIdSet)
            AND
                Year__c = :year
        ]) {
            returnList.addAll(fList);
        }
        return returnList; 
    }

    /**
     * Retrieves a map of Forecast__c records indexed by a composite key consisting of SAP account number, month number, and bottle identifier or product name.
     * 
     * @param accountIdSet A set of account IDs to filter the forecasts.
     * @param prodIdSet A set of product IDs to filter the forecasts.
     * @param identifierIdSet A set of bottle identifiers to filter the forecasts.
     * @param year The year for which the forecasts are to be retrieved.
     * @return A map where the key is a composite key of SAP account number, month number, and bottle identifier or product name, and the value is the corresponding Forecast__c record.
     */
    public Map<String, Forecast__c> getForecastMapByAccountProduct(Set<ID> accountIdSet, Set<ID> prodIdSet, Set<String> identifierIdSet, String year) {
        // Guard clause: Return an empty map if any set or year is null or empty
        if (accountIdSet == null || prodIdSet == null || identifierIdSet == null || String.isEmpty(year)) {
            return new Map<String, Forecast__c>();
        }

        Map<String, Forecast__c> returnMap = new Map<String, Forecast__c>();
        
        for (Forecast__c f: getForecastListByAccountProductAndBottleId(accountIdSet, prodIdSet, identifierIdSet, year)) {
            String monthNo = String.valueOf(f.Month_No__c).leftPad(2).replace(' ','0');
            String keyString = f.Month__r.Customer__r.SAP_Account_Number__c + ':' + monthNo + ':' + (f.Product__r.Bottle_Identifier__c != null ? f.Product__r.Bottle_Identifier__c : f.Product_Name__c);
            returnMap.put(keyString, f);
        }
        return returnMap; 
    }

    /**
     * Retrieves a map of lists of Forecast__c records indexed by a composite key consisting of customer ID and product ID.
     * 
     * @param accountIdSet A set of account IDs to filter the forecasts.
     * @param prodIdSet A set of product IDs to filter the forecasts.
     * @param year The year for which the forecasts are to be retrieved.
     * @return A map where the key is a composite key of customer ID and product ID, and the value is a list of Forecast__c records.
     */
    public Map<String, List<Forecast__c>> getForecastListMapByAccountProduct2(Set<ID> accountIdSet, Set<ID> prodIdSet, String year) {
        // Guard clause: Return an empty map if any set or year is null or empty
        if (accountIdSet == null || prodIdSet == null || String.isEmpty(year)) {
            return new Map<String, List<Forecast__c>>();
        }

        Map<String, List<Forecast__c>> returnMap = new Map<String, List<Forecast__c>>();
        
        for (Forecast__c f: getForecastListByAccountProduct2(accountIdSet, prodIdSet, year)) {
            String keyString = f.Month__r.Customer__c + ':' + f.Product__c;
            List<Forecast__c> fcpList = returnMap.get(keyString);
            if (fcpList == null) {
                fcpList = new List<Forecast__c>();
            }
            fcpList.add(f); 
            returnMap.put(keyString, fcpList);
        }
        return returnMap; 
    }

    /**
     * Retrieves a list of Forecast__c records based on account IDs, product IDs, and year.
     * 
     * @param accountIdSet A set of account IDs to filter the forecasts.
     * @param prodIdSet A set of product IDs to filter the forecasts.
     * @param year The year for which the forecasts are to be retrieved.
     * @return A list of Forecast__c records matching the criteria.
     */
    public List<Forecast__c> getForecastListByAccountProduct2(Set<ID> accountIdSet, Set<ID> prodIdSet, String year) {
        // Guard clause: Return an empty list if any set or year is null or empty
        if (accountIdSet == null || prodIdSet == null || String.isEmpty(year)) {
            return new List<Forecast__c>();
        }

        List<Forecast__c> returnList = new List<Forecast__c>();
        
        for (List<Forecast__c> fList: [
            SELECT
                Id, Name, Month__c, Month_No__c, Calendar_Month__c, Year__c, Month__r.Customer__c, Customer_A_c_No__c,
                Product__c, Product__r.Bottle_Identifier__c, Product_Name__c, Product_Description__c, SAP_Material_Code__c, SAP_Material_Code__r.Name, Unique_ID__c,
                Budget__c, Budget_Tonnage__c, Forecast__c, Forecast_Tonnage__c, 
                Total_Units_Rounded__c, Total_Tonnage_Rounded__c, Total_Actual_Units__c, Total_Actual_Tonnage__c
            FROM 
                Forecast__c 
            WHERE
                Month__r.Customer__c in :accountIdSet
            AND
                Product__c IN :prodIdSet
            AND
                Year__c = :year
        ]) {
            returnList.addAll(fList);
        }
        return returnList; 
    }
    /**
     * Retrieves a list of Forecast__c records filtered by a set of Month__c IDs.
     * The records are sorted by the Forecast__c field in descending order.
     *
     * @param monthIdSet A Set of IDs representing the Month__c records to filter forecasts.
     * @return List<Forecast__c> A list of Forecast__c records that correspond to the provided Month__c IDs.
     * This method ensures that forecasts for the given months are returned, which can be useful for generating reports
     * or analyzing forecasting data on a monthly basis.
     */
    public List<Forecast__c> getForecastListByMonthId(Set<ID> monthIdSet) {
        return [
            SELECT
                Id, Name, Year__c, Month__c, Product__c, Product_Name__c, Product_Description__c, 
                SAP_Material_Code__c, SAP_Material_Code__r.Name, Unique_ID__c,
                Customer_Name__c, Customer_A_c_No__c, Month_No__c, Calendar_Month__c, 
                Budget__c, Forecast__c, Budget_Tonnage__c, Forecast_Tonnage__c, Budget_Tonnage_Display__c, Forecast_Tonnage_Display__c,
                Var_to_Forecast__c, T_Var_to_Forecast__c, Adh_to_Fcast__c, Adh_to_T_Fcast__c, 
                Year_Total__c, T_Year_Total__c, Year_Forecast__c, T_Year_Forecast__c, 
                Year_Budget__c, T_Year_Budget__c, Year_Var_to_Budget__c, T_Year_Var_to_Budget__c,
                Prior_Year__c, T_Prior_Year__c, Year_Prior_Yr__c, T_Year_Prior_Yr__c,
                Total_Units_Rounded__c, Total_Tonnage_Rounded__c, 
                Week_1_Units_Rounded__c,
                Week_2_Units_Rounded__c,
                Week_3_Units_Rounded__c,
                Week_4_Units_Rounded__c,
                Week_5_Units_Rounded__c,
                Week_6_Units_Rounded__c,
                Week_1_Tonnage_Rounded__c,
                Week_2_Tonnage_Rounded__c,
                Week_3_Tonnage_Rounded__c,
                Week_4_Tonnage_Rounded__c,
                Week_5_Tonnage_Rounded__c,
                Week_6_Tonnage_Rounded__c
            FROM
                Forecast__c
            WHERE
                Month__c in :monthIdSet
            ORDER BY
                Forecast__c DESC
        ];
    }

    /**
     * Retrieves a current Month Tonnage
     * 
     * @return A list of Month__c records matching the criteria.
     */
    public List<Month__c> currentMonthTonnage() {

        return [
            SELECT
                Id, Name, Year__c, Customer__c, Customer_Name__c, Customer_Name_Text__c, Customer_A_c_No__c, 
                Total_Tonnage_Rounded__c, Risk_Tonnage__c, Upside_Tonnage__c, Budget__c, Forecast__c, 
                Budget_Tonnage__c, Forecast_Tonnage__c, Revised_T_Forecast__c, Risks__c, Upsides__c, 
                Adh_to_T_Fcast__c, Adh_to_Rev_T_Fcast__c, DTG_Tonnage__c, Revised_Forecast__c, Total_Units_Rounded__c,
                Adh_to_Rev_Fcast__c, DTG__c 
            FROM
                Month__c
            WHERE
                Is_Current_Month__c = true
            ORDER BY 
                Revised_T_Forecast__c DESC
            LIMIT 20
        ];
    }
    
    /**
     * Retrieves a current Month Tonnage
     * 
     * @return A AggregateResult record matching the criteria.
     */
    public AggregateResult currentMonthTonnageTotals() {

        List<AggregateResult> rList = [
            SELECT
                SUM(Total_Tonnage_Rounded__c) actual, SUM(Risk_Tonnage__c) risks, SUM(Upside_Tonnage__c) opps, 
                SUM(Budget_Tonnage__c) budget, SUM(Forecast_Tonnage__c) forecast, SUM(Revised_T_Forecast__c) revised,
                SUM(DTG_Tonnage__c) dtg
            FROM
                Month__c
            WHERE
                Is_Current_Month__c = true
        ];

        return (rList != null ? rList[0] : null);
    }
}





// TODO remove once it has been tested/validated/QA-ed
/*public class ForecastProvider {
    public Map<Integer,String> monthMap = new Map<Integer,String>{
        1 => 'JAN',
        2 => 'FEB',
        3 => 'MAR',
        4 => 'APR',
        5 => 'MAY',
        6 => 'JUN',
        7 => 'JUL',
        8 => 'AUG',
        9 => 'SEP',
        10 => 'OCT',
        11 => 'NOV',
        12 => 'DEC' 
    };
    
    public Map<ID, ID> getAccountOwnersByAccountId(Set<ID> accountIdSet) {
        Map<ID, ID> accountOwnerMap = new Map<ID, ID>();
        for (Account a: [SELECT Id, OwnerId, Encirc_Account_Number__c FROM Account WHERE Id in :accountIdSet]) {
            accountOwnerMap.put(a.Id, a.OwnerId);
        }
        return accountOwnerMap;
    }
    
    // Query used for change of Month Forecast Account Owners
    public Map<ID, Account> getMonthsByAccountId(Set<ID> accountIdSet) {
        return new MAP<ID, Account>([
            SELECT
                Id, OwnerId, Encirc_Account_Number__c, (SELECT Id, OwnerId from Months__r)
            FROM
                Account
            WHERE
                Id in :accountIdSet
        ]);
    }
    
    public Map<ID, Account> getAccountNumsByAccountId(Set<ID> accountIdSet) {
        return new Map<ID, Account>([
            SELECT Id, SAP_Account_Number__c, Encirc_Account_Number__c FROM Account WHERE Id in :accountIdSet       
        ]);
    }
    
    public Map<ID, Bottle__c> getProductById(Set<ID> prodIdSet) {
        return new Map<ID, Bottle__c>([
            SELECT Id, Name, SAP_Model_Number__c, Bottle_Identifier__c, Weight_per_Unit__c FROM Bottle__c WHERE Id in :prodIdSet
        ]);
    }
    
    public Map<String, Bottle__c> getProductByName(Set<String> prodNameSet) {
        Map<String, Bottle__c> bMap = new Map<String, Bottle__c>();
        for (Bottle__c b: [
            SELECT 
                Id, Name, SAP_Model_Number__c, Bottle_Identifier__c, Weight_per_Unit__c 
            FROM 
                Bottle__c 
            WHERE 
                Bottle_Identifier__c IN :prodNameSet
        ]) bMap.put(b.Bottle_Identifier__c, b);
        return bMap;
    }
    
    public Map<ID, SAP_Material_Code__c> getSAPMaterialCodeById(Set<ID> materialIdSet) {
        return new Map<ID, SAP_Material_Code__c>([
            SELECT 
                Id, Name, Bottle__c, Bottle__r.SAP_Model_Number__c, Material_Code_Key__c
            FROM 
                SAP_Material_Code__c 
            WHERE 
                Id in :materialIdSet
        ]);
    }
    
    public Map<Id, Bottle__c> getProductMap(Set<Id> productIdSet){
        return new Map<Id, Bottle__c>([
            SELECT 
                Id, Name, Bottle_Identifier__c
            FROM 
                Bottle__c 
            WHERE 
                Id in :productIdSet
        ]);
    }

    public Map<ID, Month__c> getMonthsById(Set<ID> monthIdSet) {
        return new MAP<ID, Month__c>([
            SELECT
                Id, Name, Year__c, Customer__c, Customer_Name__c, Customer_A_c_No__c, Customer_Name_Text__c, Unique_ID__c, Month_Number__c, Calendar_Month__c, 
                Budget__c, Forecast__c, Budget_Tonnage__c, Forecast_Tonnage__c,
                Budget_Rounded__c, Forecast_Rounded__c, Budget_Tonnage_Rounded__c, Forecast_Tonnage_Rounded__c,
                Risks__c, Upsides__c, Risk_Upside_Comments__c, Risk_Tonnage__c, Upside_Tonnage__c, 
                Revised_T_Forecast__c, Revised_Forecast__c, Var_to_Forecast__c, T_Var_to_Forecast__c,
                Adh_to_Fcast__c, Adh_to_Rev_Fcast__c, Adh_to_T_Fcast__c, Adh_to_Rev_T_Fcast__c,
                Year_Total__c, T_Year_Total__c, Year_Forecast__c, T_Year_Forecast__c, 
                Year_Budget__c, T_Year_Budget__c, Year_Var_to_Budget__c, T_Year_Var_to_Budget__c,
                Prior_Year__c, T_Prior_Year__c, Year_Prior_Yr__c, T_Year_Prior_Yr__c,
                Total_Units_Rounded__c, Total_Tonnage_Rounded__c, 
                DTG__c, DTG_Tonnage__c,
                Week_1_Units_Rounded__c,
                Week_2_Units_Rounded__c,
                Week_3_Units_Rounded__c,
                Week_4_Units_Rounded__c,
                Week_5_Units_Rounded__c,
                Week_6_Units_Rounded__c,
                Week_1_Tonnage_Rounded__c,
                Week_2_Tonnage_Rounded__c,
                Week_3_Tonnage_Rounded__c,
                Week_4_Tonnage_Rounded__c,
                Week_5_Tonnage_Rounded__c,
                Week_6_Tonnage_Rounded__c
            FROM
                Month__c
            WHERE
                Id in :monthIdSet
        ]);
    }

    public List<Month__c> currentMonthUnits() {
        return [
            SELECT
                Id, Name, Year__c, Customer__c, Customer_Name__c, Customer_Name_Text__c, Customer_A_c_No__c, 
                Total_Units_Rounded__c, Risks__c, Upsides__c, 
                Budget__c, Forecast__c, Revised_Forecast__c,
                Adh_to_Fcast__c, Adh_to_Rev_Fcast__c, DTG__c
            FROM
                Month__c
            WHERE
                Is_Current_Month__c = true
            ORDER BY 
                Revised_Forecast__c DESC
            LIMIT 20
        ];
    }
    
    public AggregateResult currentMonthUnitTotals() {
        List<AggregateResult> rList = [
            SELECT
                SUM(Total_Units_Rounded__c) actual, SUM(Risks__c) risks, SUM(Upsides__c) opps, 
                SUM(Budget__c) budget, SUM(Forecast__c) forecast, SUM(Revised_Forecast__c) revised, 
                SUM(DTG__c) dtg
            FROM
                Month__c
            WHERE
                Is_Current_Month__c = true
        ];
        return rList[0];
    }

    public List<Month__c> currentMonthTonnage() {
        return [
            SELECT
                Id, Name, Year__c, Customer__c, Customer_Name__c, Customer_Name_Text__c, Customer_A_c_No__c, 
                Total_Tonnage_Rounded__c, Risk_Tonnage__c, Upside_Tonnage__c, 
                Budget_Tonnage__c, Forecast_Tonnage__c, Revised_T_Forecast__c,
                Adh_to_T_Fcast__c, Adh_to_Rev_T_Fcast__c, DTG_Tonnage__c
            FROM
                Month__c
            WHERE
                Is_Current_Month__c = true
            ORDER BY 
                Revised_T_Forecast__c DESC
            LIMIT 20
        ];
    }
    
    public AggregateResult currentMonthTonnageTotals() {
        List<AggregateResult> rList = [
            SELECT
                SUM(Total_Tonnage_Rounded__c) actual, SUM(Risk_Tonnage__c) risks, SUM(Upside_Tonnage__c) opps, 
                SUM(Budget_Tonnage__c) budget, SUM(Forecast_Tonnage__c) forecast, SUM(Revised_T_Forecast__c) revised,
                SUM(DTG_Tonnage__c) dtg
            FROM
                Month__c
            WHERE
                Is_Current_Month__c = true
        ];
        return rList[0];
    }
    
    // Note that the map key here includes either bottle identifier or SAP material name
    public Map<String, Forecast__c> getForecastMapByAccountProduct(Set<ID> accountIdSet, Set<ID> prodIdSet, Set<String> identifierIdSet, String year) {
        Map<String, Forecast__c> returnMap = new Map<String, Forecast__c>();
        
        for (Forecast__c f: getForecastListByAccountProductAndBottleId(accountIdSet, prodIdSet, identifierIdSet, year)) {
          String monthNo = String.valueOf(f.Month_No__c).leftPad(2).replace(' ','0');
          String keyString = f.Month__r.Customer__r.SAP_Account_Number__c + ':' + monthNo + ':' + (f.Product__r.Bottle_Identifier__c != null ? f.Product__r.Bottle_Identifier__c : f.Product_Name__c);
            System.debug('fpkeyString '+ keyString);
          returnMap.put(keyString, f);
        }
        return returnMap; 
    }
            
    
    // Note that the map key here includes either bottle Salesforce Id or SAP material Salesforce Id
    public Map<String, List<Forecast__c>> getForecastListMapByAccountProduct(Set<ID> accountIdSet, Set<ID> prodIdSet, Set<ID> materialIdSet, String year) {
        Map<String, List<Forecast__c>> returnMap = new Map<String, List<Forecast__c>>();
        
        for (Forecast__c f: getForecastListByAccountProduct(accountIdSet, prodIdSet, materialIdSet, year)) {
            String keyString = f.Month__r.Customer__c + ':' + (f.SAP_Material_Code__c != null ? f.SAP_Material_Code__c : f.Product__c);
            
            List<Forecast__c> fcpList = returnMap.get(keyString);
            if (fcpList == null) fcpList = new List<Forecast__c>();
            fcpList.add(f); 
            returnMap.put(keyString, fcpList);
        }
        return returnMap; 
    }
        
    public List<Forecast__c> getForecastListByAccountProduct(Set<ID> accountIdSet, Set<ID> prodIdSet, Set<ID> materialIdSet, String year) {
        List<Forecast__c> returnList = new List<Forecast__c>();
        
        for (List<Forecast__c> fList: [
            SELECT
                Id, Name, Month__c, Month_No__c, Calendar_Month__c, Year__c, Month__r.Customer__c, Customer_A_c_No__c,
                Product__c, Product__r.Bottle_Identifier__c, Product_Name__c, Product_Description__c, SAP_Material_Code__c, SAP_Material_Code__r.Name, Unique_ID__c,
                Budget__c, Budget_Tonnage__c, Forecast__c, Forecast_Tonnage__c, 
                Total_Units_Rounded__c, Total_Tonnage_Rounded__c, Total_Actual_Units__c, Total_Actual_Tonnage__c
            FROM 
                Forecast__c 
            WHERE
                Month__r.Customer__c in :accountIdSet
            AND
                (Product__c IN :prodIdSet OR SAP_Material_Code__c IN :materialIdSet)
            AND
                Year__c = :year
        ]) {
            returnList.addAll(fList);
        }
        return returnList; 
    }

    // Note that the map key here includes either bottle Salesforce Id or SAP material Salesforce Id
    public Map<String, List<Forecast__c>> getForecastListMapByAccountProduct2(Set<ID> accountIdSet, Set<ID> prodIdSet, String year) {
        Map<String, List<Forecast__c>> returnMap = new Map<String, List<Forecast__c>>();
        
        for (Forecast__c f: getForecastListByAccountProduct2(accountIdSet, prodIdSet, year)) {
            String keyString = f.Month__r.Customer__c + ':' + f.Product__c;
            List<Forecast__c> fcpList = returnMap.get(keyString);
            if (fcpList == null) fcpList = new List<Forecast__c>();
            fcpList.add(f); 
            returnMap.put(keyString, fcpList);
        }
        return returnMap; 
    }
        
    public List<Forecast__c> getForecastListByAccountProduct2(Set<ID> accountIdSet, Set<ID> prodIdSet, String year) {
        List<Forecast__c> returnList = new List<Forecast__c>();
        
        for (List<Forecast__c> fList: [
            SELECT
                Id, Name, Month__c, Month_No__c, Calendar_Month__c, Year__c, Month__r.Customer__c, Customer_A_c_No__c,
                Product__c, Product__r.Bottle_Identifier__c, Product_Name__c, Product_Description__c, SAP_Material_Code__c, SAP_Material_Code__r.Name, Unique_ID__c,
                Budget__c, Budget_Tonnage__c, Forecast__c, Forecast_Tonnage__c, 
                Total_Units_Rounded__c, Total_Tonnage_Rounded__c, Total_Actual_Units__c, Total_Actual_Tonnage__c
            FROM 
                Forecast__c 
            WHERE
                Month__r.Customer__c in :accountIdSet
            AND
                Product__c IN :prodIdSet
            AND
                Year__c = :year
        ]) {
            returnList.addAll(fList);
        }
        return returnList; 
    }

    public List<Forecast__c> getForecastListByAccountProductAndBottleId(Set<ID> accountIdSet, Set<ID> prodIdSet, Set<String> identifierIdSet, String year) {
        List<Forecast__c> returnList = new List<Forecast__c>();
        
        for (List<Forecast__c> fList: [
            SELECT
                Id, Name, Month__c, Month_No__c, Calendar_Month__c, Year__c, Month__r.Customer__c, Customer_A_c_No__c,
                Product__c, Product__r.Bottle_Identifier__c, Product_Name__c, Product_Description__c, SAP_Material_Code__c, SAP_Material_Code__r.Name, Unique_ID__c,
                Budget__c, Budget_Tonnage__c, Forecast__c, Forecast_Tonnage__c, 
                Total_Units_Rounded__c, Total_Tonnage_Rounded__c, Total_Actual_Units__c, Total_Actual_Tonnage__c, Month__r.Customer__r.SAP_Account_Number__c
            FROM 
                Forecast__c 
            WHERE
                Month__r.Customer__c in :accountIdSet
            AND
                (Product__c IN :prodIdSet OR Product__r.Bottle_Identifier__c IN :identifierIdSet)
            AND
                Year__c = :year
        ]) {
            returnList.addAll(fList);
        }
        return returnList; 
    }
    
    public List<Forecast__c> getForecastListByMonthId(Set<ID> monthIdSet) {
        return [
            SELECT
                Id, Name, Year__c, Month__c, Product__c, Product_Name__c, Product_Description__c, 
                SAP_Material_Code__c, SAP_Material_Code__r.Name, Unique_ID__c,
                Customer_Name__c, Customer_A_c_No__c, Month_No__c, Calendar_Month__c, 
                Budget__c, Forecast__c, Budget_Tonnage__c, Forecast_Tonnage__c, Budget_Tonnage_Display__c, Forecast_Tonnage_Display__c,
                Var_to_Forecast__c, T_Var_to_Forecast__c, Adh_to_Fcast__c, Adh_to_T_Fcast__c, 
                Year_Total__c, T_Year_Total__c, Year_Forecast__c, T_Year_Forecast__c, 
                Year_Budget__c, T_Year_Budget__c, Year_Var_to_Budget__c, T_Year_Var_to_Budget__c,
                Prior_Year__c, T_Prior_Year__c, Year_Prior_Yr__c, T_Year_Prior_Yr__c,
                Total_Units_Rounded__c, Total_Tonnage_Rounded__c, 
                Week_1_Units_Rounded__c,
                Week_2_Units_Rounded__c,
                Week_3_Units_Rounded__c,
                Week_4_Units_Rounded__c,
                Week_5_Units_Rounded__c,
                Week_6_Units_Rounded__c,
                Week_1_Tonnage_Rounded__c,
                Week_2_Tonnage_Rounded__c,
                Week_3_Tonnage_Rounded__c,
                Week_4_Tonnage_Rounded__c,
                Week_5_Tonnage_Rounded__c,
                Week_6_Tonnage_Rounded__c
            FROM
                Forecast__c
            WHERE
                Month__c in :monthIdSet
            ORDER BY
                Forecast__c DESC
        ];
    }
    
}*/