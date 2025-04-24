/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DailyComparativesComponentController.cls
   Description: Controller Class for the Daily Comparatives Visualforce Components
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2016     1.0     M.Witchalls(Ciber)  Initial Release 
   Dec 2017     1.1     M.Witchalls(Cloud9) Addition of DTG fields
   Sep 2024     2.0     Globant             Added Comments and Code Refactoring
------------------------------------------------------------------------------------------------------------------------ */        

public class DailyComparativesComponentController {
    private ForecastProvider fProvider;
    private final List<Month__c> unitsList;
    private final AggregateResult unitTotals;
    private final List<Month__c> tonnageList;
    private final AggregateResult tonnageTotals;
    private final String baseURL;
    private final DC_Report_Ids__c cs;  // Report Ids Custom Setting

    /**
     * Constructor initializes the controller by retrieving current month data for units and tonnage, as well as their totals.
     * Also sets up the base URL and custom settings for report IDs.
     */
    public DailyComparativesComponentController() {
        fProvider = new ForecastProvider();
        unitsList = fProvider.currentMonthUnits();
        tonnageList = fProvider.currentMonthTonnage();
        unitTotals = fProvider.currentMonthUnitTotals();
        tonnageTotals = fProvider.currentMonthTonnageTotals();
        baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        cs = DC_Report_Ids__c.getInstance();
    }

    /**
     * Retrieves a list of Top20Record objects representing the current month's unit metrics, including budget, forecast,
     * risks, upsides, revised forecast, actuals, adherence percentage, and DTG values.
     *
     * @return A list of Top20Record objects containing the units data.
     */
    public List<Top20Record> getUnits() {
        return getTopRecords(unitsList, unitTotals, Page.ProductForecastUnits);
    }

    /**
     * Retrieves a list of Top20Record objects representing the current month's tonnage metrics, including budget, forecast,
     * risks, upsides, revised forecast, actuals, adherence percentage, and DTG values.
     *
     * @return A list of Top20Record objects containing the tonnage data.
     */
    public List<Top20Record> getTonnage() {
        return getTopRecords(tonnageList, tonnageTotals, Page.ProductForecastTonnage);
    }

    /**
     * Retrieves the URL for the "Customer Units Current Month" report.
     *
     * @return The URL string for the report.
     */
    public String getUnitsReportLink() {
        return getReportLink(cs.DC_Customer_Units_Current_Month__c);
    }

    /**
     * Retrieves the URL for the "Customer Tonnage Current Month" report.
     *
     * @return The URL string for the report.
     */
    public String getTonnageReportLink() {
        return getReportLink(cs.DC_Customer_Tonnage_Current_Month__c);
    }

    /**
     * Retrieves a report link by appending the base URL with the report ID.
     *
     * @param reportId - The report ID to append to the base URL.
     * @return The complete report URL.
     */
    private String getReportLink(String reportId) {
        return baseURL + '/' + reportId;
    }

    /**
     * Retrieves a list of Top20Record objects based on the provided month list, totals, and page reference.
     *
     * @param monthList - The list of months to extract data from.
     * @param totals - The totals for the current month.
     * @param page - The PageReference for creating links.
     * @return A list of Top20Record objects.
     */
    private List<Top20Record> getTopRecords(List<Month__c> monthList, AggregateResult totals, PageReference page) {
        List<Top20Record> recordList = new List<Top20Record>();

        if (monthList.isEmpty() || totals == null) {
            return recordList;
        }

        recordList.add(createTotalRecord(totals));

        for (Month__c month : monthList) {
            recordList.add(createCustomerRecord(month, page));
        }

        return recordList;
    }

    /**
     * Creates a Top20Record object for the current month totals.
     *
     * @param totals - The AggregateResult containing the total values for the current month.
     * @return A Top20Record object representing the totals.
     */
    private Top20Record createTotalRecord(AggregateResult totals) {
        if (totals == null) {
            return null;  
        }
        return new Top20Record(
            'Current Month Totals',
            null,
            null,
            getIntegerValue(totals, 'budget'),
            getIntegerValue(totals, 'forecast'),
            getIntegerValue(totals, 'risks'),
            getIntegerValue(totals, 'opps'),
            getIntegerValue(totals, 'revised'),
            getIntegerValue(totals, 'actual'),
            calculatePercent(totals, 'revised', 'actual'),
            getIntegerValue(totals, 'dtg')
        );
    }

    /**
     * Creates a Top20Record object for a specific customer and month.
     *
     * @param month - The Month__c object containing the customer data.
     * @param page - The PageReference for creating links.
     * @return A Top20Record object representing the customer data.
     */
    private Top20Record createCustomerRecord(Month__c month, PageReference page) {
        if (month == null || month.Customer_A_c_No__c == null) {
            return null; 
        }
        page.getParameters().put('customerNo', month.Customer_A_c_No__c);
        String prodLink = baseURL + '/' + page.getUrl();

        return new Top20Record(
            month.Customer_Name_Text__c,
            month.Customer_A_c_No__c,
            prodLink,
            getNullableIntegerValue(month.Budget__c),
            getNullableIntegerValue(month.Forecast__c),
            getNullableIntegerValue(month.Risks__c),
            getNullableIntegerValue(month.Upsides__c),
            getNullableIntegerValue(month.Revised_Forecast__c),
            getNullableIntegerValue(month.Total_Units_Rounded__c),
            getNullableIntegerValue(month.Adh_to_Rev_Fcast__c),
            getNullableIntegerValue(month.DTG__c)
        );
    }

    /**
     * Converts a nullable Double value to an Integer.
     *
     * @param value - The Double value to convert.
     * @return The Integer value, or 0 if the input is null.
     */
    private Integer getNullableIntegerValue(Decimal value) {
        return (value == null) ? 0 : value.intValue();
    }

    /**
     * Retrieves an Integer value from an AggregateResult object.
     *
     * @param totals - The AggregateResult object containing the values.
     * @param key - The key to extract the value for.
     * @return The Integer value, or 0 if the key does not exist.
     */
    private Integer getIntegerValue(AggregateResult totals, String key) {
        if (totals == null || key == null) {
            return null;
        }
        Object value = totals.get(key);
        return (value == null) ? 0 : Double.valueOf(value.toString()).intValue();
    }

    /**
     * Calculates the adherence percentage based on revised and actual values.
     *
     * @param totals - The AggregateResult object containing the totals.
     * @param revisedKey - The key for the revised forecast value.
     * @param actualKey - The key for the actual value.
     * @return The adherence percentage as an Integer.
     */
    private Integer calculatePercent(AggregateResult totals, String revisedKey, String actualKey) {
        if (totals == null || revisedKey == null || actualKey == null) {
            return null;
        }
        Integer revised = getIntegerValue(totals, revisedKey);
        Integer actual = getIntegerValue(totals, actualKey);
        return (revised == 0) ? 0 : Math.round(100 * ((decimal) actual / revised));
    }

    /**
     * Inner class representing a record for the top 20 customers' metrics.
     */
    public class Top20Record {
        public String customer { get; set; }
        public String custNo { get; set; }
        public String hrefValue { get; set; }
        public Integer budget { get; set; }
        public Integer forecast { get; set; }
        public Integer risks { get; set; }
        public Integer opps { get; set; }
        public Integer revised { get; set; }
        public Integer actual { get; set; }
        public String percent { get; set; }
        public Integer dtg { get; set; }

        /**
         * Constructor initializes the Top20Record with customer metrics.
         *
         * @param customer - The name of the customer.
         * @param custNo - The customer number.
         * @param prodLink - The URL for the product forecast page.
         * @param budget - The budget value.
         * @param forecast - The forecast value.
         * @param risks - The risks value.
         * @param opps - The opportunities value.
         * @param revised - The revised forecast value.
         * @param actual - The actual value.
         * @param percent - The adherence percentage.
         * @param dtg - The DTG value.
         */
        public Top20Record(String customer, String custNo, String prodLink, Integer budget, Integer forecast, Integer risks, Integer opps, Integer revised, Integer actual, Integer percent, Integer dtg) {
            this.customer = customer;
            this.custNo = custNo;
            this.hrefValue = (custNo == null) ? '' : prodLink;
            this.budget = budget;
            this.forecast = forecast;
            this.risks = risks;
            this.opps = opps;
            this.revised = revised;
            this.actual = actual;
            this.percent = percent + '%';
            this.dtg = dtg;
        }
    }
}


/*public class DailyComparativesComponentController {
    private ForecastProvider fProvider; 
    private final List<Month__c> unitsList;
    private final AggregateResult unitTotals;
    private final List<Month__c> tonnageList;
    private final AggregateResult tonnageTotals;
    private final String baseURL;
    private final DC_Report_Ids__c cs;  // Report Ids Custom Setting
    
    public DailyComparativesComponentController() {
        fProvider = new ForecastProvider();   
        unitsList = fProvider.currentMonthUnits();
        tonnageList = fProvider.currentMonthTonnage();  
        unitTotals = fProvider.currentMonthUnitTotals();
        tonnageTotals = fProvider.currentMonthTonnageTotals();
        baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        cs = DC_Report_Ids__c.getInstance();
    }

    public List<Top20Record> getUnits() {
        List<Top20Record> uList = new List<Top20Record>();      
        PageReference pageRef = Page.ProductForecastUnits;
        
        if (unitsList.size() > 0) {
            Long budget = Double.valueOf(unitTotals.get('budget')).longValue();
            Long forecast = Double.valueOf(unitTotals.get('forecast')).longValue();
            Long risks = Double.valueOf(unitTotals.get('risks')).longValue();
            Long opps = Double.valueOf(unitTotals.get('opps')).longValue();
            Long revised = Double.valueOf(unitTotals.get('revised')).longValue();
            Long actual = Double.valueOf(unitTotals.get('actual')).longValue();
            Long percent = (revised == 0) ? 0 : Math.roundToLong(100 * Double.valueOf(unitTotals.get('actual')) / Double.valueOf(unitTotals.get('revised')));
            Long dtg = Double.valueOf(unitTotals.get('dtg')).longValue();
            uList.add(
                new Top20Record(
                    'Current Month Totals', null, null, budget, forecast, risks, opps, revised, actual, percent, dtg
                )
            );
            for (Month__c m: unitsList) {
                pageRef.getParameters().put('customerNo',m.Customer_A_c_No__c);
                String prodLink = baseURL + '/' + pageRef.getUrl();
                uList.add(
                    new Top20Record(
                        m.Customer_Name_Text__c,
                        m.Customer_A_c_No__c,
                        prodLink,
                        (m.Budget__c == null) ? 0 : m.Budget__c.longValue(),
                        (m.Forecast__c == null) ? 0 : m.Forecast__c.longValue(),
                        (m.Risks__c == null) ? 0 : m.Risks__c.longValue(),
                        (m.Upsides__c == null) ? 0 : m.Upsides__c.longValue(),
                        (m.Revised_Forecast__c == null) ? 0 : m.Revised_Forecast__c.longValue(),
                        (m.Total_Units_Rounded__c == null) ? 0 : m.Total_Units_Rounded__c.longValue(),
                        (m.Adh_to_Rev_Fcast__c == null) ? 0 : m.Adh_to_Rev_Fcast__c.longValue(),
                        (m.DTG__c == null) ? 0 : m.DTG__c.longValue()
                    )                   
                );
            }                   
        }
        return uList; 
    }

    public List<Top20Record> getTonnage() {
        List<Top20Record> tList = new List<Top20Record>();
        PageReference pageRef = Page.ProductForecastTonnage;
        
        if (tonnageList.size() > 0) {
            Long budget = Double.valueOf(tonnageTotals.get('budget')).longValue();
            Long forecast = Double.valueOf(tonnageTotals.get('forecast')).longValue();
            Long risks = Double.valueOf(tonnageTotals.get('risks')).longValue();
            Long opps = Double.valueOf(tonnageTotals.get('opps')).longValue();
            Long revised = Double.valueOf(tonnageTotals.get('revised')).longValue();
            Long actual = Double.valueOf(tonnageTotals.get('actual')).longValue();
            Long percent = (revised == 0) ? 0 : Math.roundToLong(100 * Double.valueOf(tonnageTotals.get('actual')) / Double.valueOf(tonnageTotals.get('revised')));
            Long dtg = Double.valueOf(tonnageTotals.get('dtg')).longValue();
            tList.add(
                new Top20Record(
                    'Current Month Totals', null, null, budget, forecast, risks, opps, revised, actual, percent, dtg
                )
            );
            for (Month__c m: tonnageList) {
                pageRef.getParameters().put('customerNo',m.Customer_A_c_No__c);
                String prodLink = baseURL + '/' + pageRef.getUrl();
                tList.add(
                    new Top20Record(
                        m.Customer_Name_Text__c,
                        m.Customer_A_c_No__c,
                        prodLink,
                        (m.Budget_Tonnage__c == null) ? 0 : m.Budget_Tonnage__c.longValue(),
                        (m.Forecast_Tonnage__c == null) ? 0 : m.Forecast_Tonnage__c.longValue(),
                        (m.Risk_Tonnage__c == null) ? 0 : m.Risk_Tonnage__c.longValue(),
                        (m.Upside_Tonnage__c == null) ? 0 : m.Upside_Tonnage__c.longValue(),
                        (m.Revised_T_Forecast__c == null) ? 0 : m.Revised_T_Forecast__c.longValue(),
                        (m.Total_Tonnage_Rounded__c == null) ? 0 : m.Total_Tonnage_Rounded__c.longValue(),
                        (m.Adh_to_Rev_T_Fcast__c == null) ? 0 : m.Adh_to_Rev_T_Fcast__c.longValue(),
                        (m.DTG_Tonnage__c == null) ? 0 : m.DTG_Tonnage__c.longValue()
                    )                   
                );
            }                   
        }
        return tList;
    }
    
    public String getUnitsReportLink() {
        return baseURL + '/' + cs.DC_Customer_Units_Current_Month__c;
    }
    
    public String getTonnageReportLink() {
        return baseURL + '/' + cs.DC_Customer_Tonnage_Current_Month__c;
    }
    
    public class Top20Record {      
        public String customer  {get; set;}
        public String custNo    {get; set;}
        public String hrefValue {get; set;}
        public Long budget      {get; set;}
        public Long forecast    {get; set;}
        public Long risks       {get; set;}
        public Long opps        {get; set;}
        public Long revised     {get; set;}
        public Long actual      {get; set;}
        public String percent   {get; set;}
        public Long dtg         {get; set;}
        
        public Top20Record(String customer, String custNo, String prodLink, Long budget, Long forecast, Long risks, Long opps, Long revised, Long actual, Long percent, Long dtg) {
            this.customer = customer;
            this.custNo = custNo;
            this.hrefValue = (custNo == null) ? '' : prodLink; 
            this.budget = budget;
            this.forecast = forecast;
            this.risks = risks;
            this.opps = opps;
            this.revised = revised;
            this.actual = actual;
            this.percent = String.valueOf(percent) + '%';
            this.dtg = dtg;
        }
    }

}*/