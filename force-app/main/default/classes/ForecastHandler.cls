/* -----------------------------------------------------------------------------------------------------------------------
   Name:        ForecastHandler.cls
   Description: Handler class for processing of the Forecast__c object
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2016     1.0     M.Witchalls(Ciber)  Initial Release 
   Mar 2017     1.1     M.Witchalls(Cloud9) Change Month Forecast Owners when Account Owner is changed  
   May 2018     2.0     M.Witchalls(Cloud9) Actual Sales History and Forecast records now include SAP Material Code
   Nov 2021     2.1.    J.Kennedy(Cloudshift) newSalesHistoryTotals: Added a check for when the Sales Organisation = 'VD10' to skip 
											newSalesHistoryTotals: Added a clear error message and break for when the SAP_Account_Number__c is missing
   Sep 2024     3.0     Globant             Refactor
------------------------------------------------------------------------------------------------------------------------ */        
public class ForecastHandler {

    private ForecastProvider fProvider; 
    private SalesHistoryProvider sProvider;
    
    private static final String successString = 'Success';
    private static final String newApprovalStatus = 'New - Unsubmitted';
    private static final String approvedValue = 'Approved'; 
    public static Boolean notDone = true;
    
    /**
     * Constructs a ForecastHandler instance with initialized providers.
     */
    public ForecastHandler() {
        // Initialize the ForecastProvider for managing forecast-related operations
        fProvider = new ForecastProvider();
        
        // Initialize the SalesHistoryProvider for handling sales history operations
        sProvider = new SalesHistoryProvider();
    }
    
    /**
     * Copy Account Owners to Forecast Month records (Copies the owner ID from the Account to the Month__c 
     * records based on the Customer__c field.)
     * 
     * @param mList A list of Month__c records to be updated with the corresponding owner IDs.
     */
    public void copyAccountOwner(List<Month__c> mList) {
        // Exit early if the input list is empty
        if (mList == null || mList.isEmpty()) {
            return;
        }

        // Create a set to store unique Account IDs from the Month__c records
        Set<ID> accountIdSet = new Set<ID>();
        for (Month__c m : mList) {
            accountIdSet.add(m.Customer__c);
        }

        // Retrieve the mapping of Account IDs to Owner IDs
        Map<ID, ID> accountOwnerMap = fProvider.getAccountOwnersByAccountId(accountIdSet);

        // Update each Month__c record with the corresponding Owner ID
        for (Month__c m : mList) {
            ID ownerId = accountOwnerMap.get(m.Customer__c);
            if (ownerId != null) {
                m.OwnerId = ownerId;
            }
        }
    }
    
    /**
     * Copy Changed Account Owners to Forecast Month records (Mar 2017) (Updates Month__c records with 
     * new Account Owner IDs where the owner has changed.)
     * 
     * @param aList    A list of updated Account records.
     * @param oldMap   A map of old Account records by ID, used to compare owner changes.
     */
    public void copyChangedAccountOwner(List<Account> aList, Map<ID, Account> oldMap) {
        // Guard clauses to check for invalid parameters
        if (aList == null || aList.isEmpty()) {
            // No Accounts to process
            return;
        }

        if (oldMap == null) {
            // Old map is required for comparison, aborting
            throw new IllegalArgumentException('Old map cannot be null');
        }

        // List to hold Month__c records that need to be updated
        List<Month__c> monthUpdateList = new List<Month__c>();
        
        // Set to track Account IDs where the owner has changed
        Set<ID> ownerChangedIdSet = new Set<ID>();
        
        // Identify Accounts with changed owners
        for (Account a : aList) {
            Account old = oldMap.get(a.Id);
            if (old != null && a.OwnerId != old.OwnerId) {
                ownerChangedIdSet.add(a.Id);
            }
        }

        // Proceed only if there are Accounts with changed owners
        if (!ownerChangedIdSet.isEmpty()) {
            // Get the corresponding Month__c records for the Accounts with changed owners
            Map<ID, Account> ownerChangedMap = fprovider.getMonthsByAccountId(ownerChangedIdSet);
            
            // Update Month__c records with the new owner IDs
            for (ID accountId : ownerChangedIdSet) {
                Account a = ownerChangedMap.get(accountId);
                if (a != null && a.Months__r != null) {
                    for (Month__c m : a.Months__r) {
                        m.OwnerId = a.OwnerId;
                        monthUpdateList.add(m);
                    }
                }
            }
        }

        // Update the Month__c records if there are any to update
        if (!monthUpdateList.isEmpty()) {
            update monthUpdateList;
        }
    }
    
    /**
     * Copy Risk/Upside fields to Forecast Month records (Updates Forecast Month records with Risk and Upside 
     * fields from the provided Forecast_Risk_Upside__c records if their approval status has changed to approved.)
     * 
     * @param fruList  A list of Forecast_Risk_Upside__c records with updated Risk and Upside fields.
     * @param oldMap   A map of old Forecast_Risk_Upside__c records by ID, used to compare approval status changes.
     */
    public void copyRiskUpsideFields(List<Forecast_Risk_Upside__c> fruList, Map<ID, Forecast_Risk_Upside__c> oldMap) {
        // Guard clauses to check for invalid parameters
        if (fruList == null || fruList.isEmpty()) {
            // No records to process
            return;
        }

        if (oldMap == null) {
            // Old map is required for comparison, aborting
            throw new IllegalArgumentException('Old map cannot be null');
        }

        // Set to track Month IDs that need to be updated
        Set<ID> monthIdSet = new Set<ID>();

        // Identify Months where the approval status has changed to approved
        for (Forecast_Risk_Upside__c fru : fruList) {
            Forecast_Risk_Upside__c oldFru = oldMap.get(fru.Id);
            if (fru.Approval_Status__c == approvedValue && (oldFru == null || oldFru.Approval_Status__c != approvedValue)) {
                monthIdSet.add(fru.Month__c);
            }
        }

        // Proceed only if there are Months to update
        if (!monthIdSet.isEmpty()) {
            // Get the corresponding Month__c records for the identified Month IDs
            Map<ID, Month__c> monthMap = fProvider.getMonthsById(monthIdSet);
            Map<ID, Month__c> monthUpdateMap = new Map<ID, Month__c>();

            // Update each Month__c record with Risk and Upside values from Forecast_Risk_Upside__c records
            for (Forecast_Risk_Upside__c fru : fruList) {
                Month__c m = monthMap.get(fru.Month__c);
                if (m != null) {
                    m.Risks__c = -fru.Risks__c;  // Assume Risks__c needs to be negated
                    m.Upsides__c = fru.Upsides__c;
                    m.Risk_Upside_Comments__c = fru.Comments__c;
                    monthUpdateMap.put(m.Id, m);
                }
            }

            // Update the Month__c records if there are any to update
            if (!monthUpdateMap.isEmpty()) {
                update monthUpdateMap.values();
            }
        }
    }

    /**
     * Updates Forecast records with Prior Month Budget totals based on previous month's data.
     * 
     * @param fList A list of Forecast__c records to be updated with prior month budget totals.
     */
    public void priorMonthBudgetTotals(List<Forecast__c> fList) {
        if (fList == null || fList.isEmpty()) {
            return;
        }

        // Extract IDs and year from the forecast list
        Set<ID> monthIdSet = new Set<ID>();
        Set<ID> prodIdSet = new Set<ID>();
        Set<ID> accountIdSet = new Set<ID>();
        String year;

        extractIdsAndYear(fList, monthIdSet, prodIdSet, accountIdSet, year);

        // Retrieve Month records and account IDs
        Map<ID, Month__c> monthMap = fProvider.getMonthsById(monthIdSet);
        year = getYearFromMonthMap(monthMap, accountIdSet);

        // Retrieve Forecast records based on Account and Product
        Map<String, List<Forecast__c>> forecastMap = fProvider.getForecastListMapByAccountProduct2(accountIdSet, prodIdSet, year);

        // Update each Forecast record with Prior Month Budget totals
        updatePriorMonthTotals(fList, monthMap, forecastMap);
    }

    /**
     * Extracts IDs and year from the provided Forecast__c records.
     * 
     * @param fList         The list of Forecast__c records.
     * @param monthIdSet    A set to store Month IDs.
     * @param prodIdSet     A set to store Product IDs.
     * @param accountIdSet  A set to store Account IDs.
     * @param year          The year extracted from Month records.
     */
    private void extractIdsAndYear(List<Forecast__c> fList, Set<ID> monthIdSet, Set<ID> prodIdSet, Set<ID> accountIdSet, String year) {
        for (Forecast__c f : fList) {
            monthIdSet.add(f.Month__c);
            if (f.Product__c != null) prodIdSet.add(f.Product__c);
        }

        Map<ID, Month__c> monthMap = fProvider.getMonthsById(monthIdSet);
        for (Month__c m : monthMap.values()) {
            accountIdSet.add(m.Customer__c);
            year = m.Year__c;
        }
    }

    /**
     * Retrieves the year from the Month records.
     * 
     * @param monthMap      A map of Month records by ID.
     * @param accountIdSet  A set to store Account IDs.
     * @return              The year extracted from the Month records.
     */
    private String getYearFromMonthMap(Map<ID, Month__c> monthMap, Set<ID> accountIdSet) {
        String year = null;
        for (Month__c m : monthMap.values()) {
            accountIdSet.add(m.Customer__c);
            year = m.Year__c;
        }
        return year;
    }

    /**
     * Updates the Prior Month Budget totals for each Forecast__c record.
     * 
     * @param fList         A list of Forecast__c records to be updated.
     * @param monthMap      A map of Month__c records by ID.
     * @param forecastMap   A map of Forecast__c records by Account and Product.
     */
    private void updatePriorMonthTotals(List<Forecast__c> fList, Map<ID, Month__c> monthMap, Map<String, List<Forecast__c>> forecastMap) {
        for (Forecast__c f : fList) {
            Month__c m = monthMap.get(f.Month__c);
            if (m == null) continue;

            List<Forecast__c> fpList = forecastMap.get(m.Customer__c + ':' + f.Product__c);
            if (fpList == null) fpList = new List<Forecast__c>();

            f.Prior_Month_Budget_Total__c = 0;
            f.Prior_Month_Budget_Tonnage__c = 0;
            for (Forecast__c fp : fpList) {
                if (fp.Budget__c == null) fp.Budget__c = 0;
                if (fp.Budget_Tonnage__c == null) fp.Budget_Tonnage__c = 0;
                if (fp.Month_No__c < Integer.valueOf(m.Month_Number__c)) {
                    f.Prior_Month_Budget_Total__c += fp.Budget__c;
                    f.Prior_Month_Budget_Tonnage__c += fp.Budget_Tonnage__c;
                }
            }
        }
    }
    
    /**
     * Update current month Forecast records when Actual Sales History has been created/updated
     * 
     * @param sList         A list of Actual_Sales_History__c records to be updated.
     */
    public void newSalesHistoryTotals(List<Actual_Sales_History__c> sList) {

        // Guard clauses to check for invalid parameters
        if (sList == null || sList.isEmpty()) {
            // No records to process
            return;
        }

        Set<ID> accountIdSet = new Set<ID>();
        Set<ID> prodIdSet = new Set<ID>();
        Set<String> identifierIdSet = new Set<String>();
        Set<String> prodNameSet = new Set<String>();
        Date todayDate = System.today();
        String monthNo = String.valueOf(todayDate.month()).leftPad(2).replace(' ','0');
        String year = String.valueOf(todayDate.year());
        
        for (Actual_Sales_History__c s: sList) {

            accountIdSet.add(s.Account__c);
            
            if (s.Item__c != null) {
                prodNameSet.add(s.Item__c);
            }

            if (s.Bottle__c != null) {
                prodIdSet.add(s.Bottle__c);
            }
        }

        Map<ID, Account> accountMap = fProvider.getAccountNumsByAccountId(accountIdSet);
        Map<String, Bottle__c> prodMap = fProvider.getProductByName(prodNameSet);
        Map<ID, Bottle__c> bottleMap = fProvider.getProductById(prodIdSet);

        for (Bottle__c b: prodMap.values()) {

            if (!bottleMap.containsKey(b.Id)) {
                prodIdSet.add(b.Id);
                identifierIdSet.add(b.Bottle_Identifier__c);
            }
        }

        for(Bottle__c b: bottleMap.values()) {
            identifierIdSet.add(b.Id);
        }

        // Note that the map key here includes either bottle identifier or SAP material name
        Map<String, Forecast__c> fMap = fProvider.getForecastMapByAccountProduct(accountIdSet, prodIdSet, identifierIdSet, year);
        
        Map<String, Bottle__c> prodUpsertMap = new Map<String, Bottle__c>();
        Map<String, Month__c> monthUpsertMap = new Map<String, Month__c>();
        Map<String, Forecast__c> forecastUpsertMap = new Map<String, Forecast__c>();
        
        for (Actual_Sales_History__c s: sList) {

            if (s.Bottle__c == null && s.Item__c == null) {
                continue;  // M.Witchalls May 2018
            }

            if (s.Sales_Organization__c == 'VD10') {
                continue;  // J.Kennedy Nov 2021
            }

            String accountNum = accountMap.get(s.Account__c).SAP_Account_Number__c;
            
            if(accountNum == '' || accountNum == null) { // J.Kennedy Nov 2021
            	String message = 'CUSTOM_VALIDATION_EXCEPTION, Account has no SAP_Account_Number';
                Trigger.new[0].addError(message);
                continue;
            }
            
            String bottleCode;
            String bottleId;
            if (s.Bottle__c != null) {
                bottleCode = bottleMap.get(s.Bottle__c).Bottle_Identifier__c;
                bottleId = s.Bottle__c;
            }
            //TBD
            if (s.Item__c != null) {
                Bottle__c b = prodMap.get(s.Item__c);
                if (b == null) {
                    Long wpu = (s.Volume_000_s__c == 0 || s.Volume_000_s__c == null) ? 0 : Math.roundToLong(1000 * s.Tonnes__c / s.Volume_000_s__c);
                    b = new Bottle__c(
                        Name = 'Bottle '+s.Item__c,
                        Bottle_Identifier__c = s.Item__c,
                        Weight_per_Unit__c = wpu
                    );
                    prodUpsertMap.put(s.Item__c, b);
                }
            }
            //
            String keyString = accountNum + ':' + monthNo + ':' + (s.Bottle__c != null ? bottleCode : s.Item__c);  
            Forecast__c f = fMap.get(keyString);

            if (f == null) {
                String monthUniqueID = s.Sales_Organization__c + '-' + accountNum.leftPad(7).replace(' ','0') + '-' + year + '-' + monthNo;
                String forecastUniqueID = monthUniqueID + '-' + (s.Bottle__c != null ? bottleCode : s.Item__c);
                String name = fProvider.monthMap.get(Integer.valueOf(monthNo));
                                
                Month__c mth = new Month__c(
                	Customer__c = s.Account__c,
                    Name = name,
                    Calendar_Month__c = name,
                    Year__c = year,
                    Unique_ID__c = monthUniqueID
                );                              
                monthUpsertMap.put(monthUniqueID, mth);
                f = new Forecast__c(
                    Month__r = new Month__c(Unique_ID__c = monthUniqueID),
                    Name = s.Item__c, 
                    Unique_ID__c = forecastUniqueID,
                    Budget__c = 0,
                    Forecast__c = 0,
                    Budget_Tonnage__c = 0,
                    Forecast_Tonnage__c = 0
                );
                //TBD
                if (s.Bottle__c != null) {
                	f.Product__c = bottleId;  
                    //f.SAP_Material_Code__r = new SAP_Material_Code__c(Material_Code_Key__c = materialCode);
                } else {
                	f.Product__r = new Bottle__c(Bottle_Identifier__c = s.Item__c); 
                }
                //
                forecastUpsertMap.put(forecastUniqueID, f);
            }   
        }

        if (prodUpsertMap.size() > 0) {
            upsert prodUpsertMap.values() Bottle_Identifier__c;
        }
        if (monthUpsertMap.size() > 0) {
            upsert monthUpsertMap.values() Unique_ID__c;
        }
        if (forecastUpsertMap.size() > 0) {
            upsert forecastUpsertMap.values() Unique_ID__c;
        }
        
        List<Forecast__c> fList = fProvider.getForecastListByAccountProductAndBottleId(accountIdSet, prodIdSet, identifierIdSet, year);
        
        if (fList.size() > 0) {

            salesHistoryTotals(fList);
            update fList;
        }
    }

    /**
     * Before insert/update, update Forecast records with This Year/Last Year totals from Actual Sales History
     * 
     * @param fList   A list of Forecast__c records to be updated.
     */
    public void salesHistoryTotals(List<Forecast__c> fList) {

        // Guard clauses to check for invalid parameters
        if (fList == null || fList.isEmpty()) {
            // No records to process
            return;
        }

        Set<ID> monthIdSet = new Set<ID>();
        Set<ID> prodIdSet = new Set<ID>();
        Set<String> identifireIdSet = new Set<String>();  // M.Witchalls May 2018
        Set<ID> accountIdSet = new Set<ID>();
        Set<String> prodNameSet = new Set<String>();
        String thisYear;
        
        // First look up Month, Account records
        for (Forecast__c f: fList) {
            monthIdSet.add(f.Month__c);
            if (f.Product__c != null) prodIdSet.add(f.Product__c);
        }
        Map<ID, Month__c> monthMap = fProvider.getMonthsById(monthIdSet);
        for (Month__c m: monthMap.values()) {
            accountIdSet.add(m.Customer__c);
            thisYear = m.Year__c;
        }
        String lastYear = String.valueOf(Integer.valueOf(thisYear) - 1);

        Map<ID, Bottle__c> prodMap = fProvider.getProductById(prodIdSet);
        for (Bottle__c b: prodMap.values()) prodNameSet.add(b.Bottle_Identifier__c);
        
        // Get Sales History by Account and Product for Current Year (map key includes either bottle identifier or SAP material name)
        Map<String, List<Actual_Sales_History__c>> sThisYearMap 
            = sProvider.getSalesHistorysByAccountProduct2(accountIdSet, prodNameSet, thisYear);

        for (Forecast__c f: fList) {
            Month__c m = monthMap.get(f.Month__c);
            Bottle__c b = prodMap.get(f.Product__c);
 
            List<Actual_Sales_History__c> shList = sThisYearMap.get(m.Customer__c + ':' + prodMap.get(f.Product__c).Bottle_Identifier__c);
            if (shList == null) {
                shList = new List<Actual_Sales_History__c>();
            }
            
            // Update the Prior Month totals
            f.Prior_Month_Actual_Total__c = 0;
            f.Prior_Month_Actual_Tonnage__c = 0;
            
            for (Actual_Sales_History__c sh: shList) {
                Long shUnits = (sh.Volume_000_s__c == null) ? 0 : Math.roundToLong(sh.Volume_000_s__c);
                Long shTonnes = (sh.Tonnes__c == null) ? 0 : Math.roundToLong(sh.Tonnes__c);
                
                if (sh.Date__c != null && sh.Date__c.month() < Integer.valueOf(m.Month_Number__c)) {
                    f.Prior_Month_Actual_Total__c += shUnits;
                    f.Prior_Month_Actual_Tonnage__c += shTonnes;
                }
                
            }
        }
        
        // Get Sales History by Account and Product for Last Year
        Map<String, List<Actual_Sales_History__c>> sLastYearMap 
            = sProvider.getSalesHistorysByAccountProduct2(accountIdSet, prodNameSet, lastYear);

        for (Forecast__c f: fList) {
            Month__c m = monthMap.get(f.Month__c);
            Bottle__c b = prodMap.get(f.Product__c);
 
            String prodString = b.Bottle_Identifier__c;
            List<Actual_Sales_History__c> shList = sLastYearMap.get(m.Customer__c + ':' + prodString);
            if (shList == null) shList = new List<Actual_Sales_History__c>();
            
            // Update the Prior Year totals
            f.Prior_Year__c = 0;
            f.T_Prior_Year__c = 0;
            f.Year_Prior_Yr__c = 0;
            f.T_Year_Prior_Yr__c = 0;
            
            for (Actual_Sales_History__c sh: shList) {
                Long shUnits = (sh.Volume_000_s__c == null) ? 0 : Math.roundToLong(sh.Volume_000_s__c);
                Long shTonnes = (sh.Tonnes__c == null) ? 0 : Math.roundToLong(sh.Tonnes__c);
                
                if (sh.Date__c.month() < Integer.valueOf(m.Month_Number__c)) {
                    f.Year_Prior_Yr__c += shUnits;
                    f.T_Year_Prior_Yr__c += shTonnes;
                } else if (sh.Date__c.month() == Integer.valueOf(m.Month_Number__c)) {
                    f.Prior_Year__c += shUnits;
                    f.T_Prior_Year__c += shTonnes; 
                    f.Year_Prior_Yr__c += shUnits;
                    f.T_Year_Prior_Yr__c += shTonnes;                   
                }
                
            }
        }
    }
}