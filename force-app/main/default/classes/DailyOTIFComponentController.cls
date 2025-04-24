/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DailyOTIFComponentController.cls
   Description: Controller Class for the Daily OTIF Email Visualforce Component
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Sep 2024     2.0     Globant             Added comments and Code refactoring
------------------------------------------------------------------------------------------------------------------------ */        
     
public class DailyOTIFComponentController {
    private DispatchProvider dProvider; 
    private final List<AggregateResult> thisMonthTotalList; 
    private final List<AggregateResult> last48hourTotalList; 
    private final String baseURL;
    private final DC_Report_Ids__c cs;  // Report Ids Custom Setting
    
    /**
     * Constructor initializes the controller by retrieving aggregate data for the current month and the last 48 hours,
     * as well as setting up the base URL and custom setting for report IDs.
     */
    public DailyOTIFComponentController() {
        dProvider = new DispatchProvider();   
        thisMonthTotalList = dProvider.currentMonthLateLoadTotals();
        last48hourTotalList = dProvider.last48hourLateLoadTotals();
        baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        cs = DC_Report_Ids__c.getInstance();
    }

    /**
     * Retrieves a list of records representing totals of early, late, and collapsed loads for the current month and 
     * the last 48 hours.
     * 
     * @return A list of ThisMonthRecord objects containing the totals and customer-specific metrics.
     */
    public List<ThisMonthRecord> getRecords() {
        List<ThisMonthRecord> rList = new List<ThisMonthRecord>();      

        if (last48hourTotalList != null && !last48hourTotalList.isEmpty()) {
            rList.add(createTotalRecord('Previous 48 Hour Totals', last48hourTotalList));
            addCustomerRecords(rList, last48hourTotalList);
        }
        
        if (thisMonthTotalList != null && !thisMonthTotalList.isEmpty()) {
            rList.add(createTotalRecord('Current Month Totals', thisMonthTotalList));
            addCustomerRecords(rList, thisMonthTotalList);
        }

        return rList; 
    }

    /**
     * Creates a record for total metrics based on aggregate results.
     *
     * @param title The title for the record.
     * @param aggregateList The list of aggregate results.
     * @return A ThisMonthRecord object containing the totals.
     */
    private ThisMonthRecord createTotalRecord(String title, List<AggregateResult> aggregateList) {
        if (aggregateList == null || aggregateList.isEmpty()) {
            throw new IllegalArgumentException('Aggregate list is null or empty');
        }
        Integer earlyTotal = 0, lateTotal = 0, collapsedTotal = 0;
        for (AggregateResult r : aggregateList) {
            earlyTotal += toInteger(r.get('early'));
            lateTotal += toInteger(r.get('late'));
            collapsedTotal += toInteger(r.get('collapsed'));
        }
        return new ThisMonthRecord(title, lateTotal, earlyTotal, collapsedTotal);
    }

    /**
     * Adds customer-specific records to the list based on aggregate results.
     *
     * @param rList The list to add the records to.
     * @param aggregateList The list of aggregate results.
     */
    private void addCustomerRecords(List<ThisMonthRecord> rList, List<AggregateResult> aggregateList) {
        if (aggregateList == null || aggregateList.isEmpty()) {
            throw new IllegalArgumentException('Aggregate list is null or empty');
        }
        for (AggregateResult r : aggregateList) {
            String customer = String.valueOf(r.get('customer'));
            Integer early = toInteger(r.get('early'));
            Integer late = toInteger(r.get('late'));
            Integer collapsed = toInteger(r.get('collapsed'));

            rList.add(new ThisMonthRecord(customer, late, early, collapsed));
        }
    }

    /**
     * Converts an object to an Integer value safely.
     * 
     * @param value The value to convert.
     * @return The Integer representation of the value or 0 if null.
     */
    private Integer toInteger(Object value) {
    	return value != null ? ((Decimal) value).intValue() : 0;
	}

    /**
     * Retrieves the URL for the "Previous 48 Hour Late Load List" report.
     * 
     * @return The URL string for the report.
     */
    public String getLast48hourLateReportLink() {
        return buildReportLink(cs.OTIF_Previous_48Hour_Late_Load_List__c);
    }

    /**
     * Retrieves the URL for the "Previous 48 Hour Early Load List" report.
     * 
     * @return The URL string for the report.
     */
    public String getLast48hourEarlyReportLink() {
        return buildReportLink(cs.OTIF_Previous_48Hour_Early_Load_List__c);
    }

    /**
     * Retrieves the URL for the "Previous 48 Hour Collapsed Load List" report.
     * 
     * @return The URL string for the report.
     */
    public String getLast48hourCollapsedReportLink() {
        return buildReportLink(cs.OTIF_Previous_48Hour_Collapsed_Load_List__c);
    }

    /**
     * Retrieves the URL for the "Current Month Late Load List" report.
     * 
     * @return The URL string for the report.
     */
    public String getLateLoadReportLink() {
        return buildReportLink(cs.OTIF_Current_Month_Late_Load_List__c);
    }

    /**
     * Retrieves the URL for the "Current Month Early Load List" report.
     * 
     * @return The URL string for the report.
     */
    public String getEarlyLoadReportLink() {
        return buildReportLink(cs.OTIF_Current_Month_Early_Load_List__c);
    }

    /**
     * Retrieves the URL for the "Current Month Collapsed Load List" report.
     * 
     * @return The URL string for the report.
     */
    public String getCollapsedLoadReportLink() {
        return buildReportLink(cs.OTIF_Current_Month_Collapsed_Load_List__c);
    }

    /**
     * Constructs a report link URL based on the base URL and the report ID.
     *
     * @param reportId The report ID to use.
     * @return The complete report URL.
     */
    private String buildReportLink(String reportId) {
        return baseURL + '/' + reportId;
    }

    /**
     * Inner class representing a record for this month's metrics.
     */
    public class ThisMonthRecord {      
        public String customer {get; set;}
        public Integer late {get; set;}
        public Integer early {get; set;}
        public Integer collapsed {get; set;}
        
        /**
         * Constructor initializes the ThisMonthRecord with customer and load metrics.
         * 
         * @param customer - The name of the customer.
         * @param late - The total count of late loads.
         * @param early - The total count of early loads.
         * @param collapsed - The total count of collapsed loads.
         */
        public ThisMonthRecord(String customer, Integer late, Integer early, Integer collapsed) {
            this.customer = customer;
            this.late = late;
            this.early = early;
            this.collapsed = collapsed;
        }
    }
}



/*public class DailyOTIFComponentController {
    private DispatchProvider dProvider; 
    private final List<AggregateResult> thisMonthTotalList; 
    private final List<AggregateResult> last48hourTotalList; 
    private final String baseURL;
    private final DC_Report_Ids__c cs;  // Report Ids Custom Setting
    
    public DailyOTIFComponentController() {
        dProvider = new DispatchProvider();   
        thisMonthTotalLIst = dProvider.currentMonthLateLoadTotals();
        last48hourTotalLIst = dProvider.last48hourLateLoadTotals();
        baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        cs = DC_Report_Ids__c.getInstance();
    }

    public List<ThisMonthRecord> getRecords() {
        List<ThisMonthRecord> rList = new List<ThisMonthRecord>();      
        Long earlyTotal = 0;
        Long lateTotal = 0;
        Long collapsedTotal = 0;
        
        for (AggregateResult r: last48hourTotalList) {
            earlyTotal += Double.valueOf(r.get('early')).longValue();
            lateTotal += Double.valueOf(r.get('late')).longValue();
            collapsedTotal += Double.valueOf(r.get('collapsed')).longValue();
        } 
        rList.add(
            new ThisMonthRecord(
                'Previous 48 Hour Totals', lateTotal, earlyTotal, collapsedTotal
            )
        );
        for (AggregateResult r: last48hourTotalList) {
            String customer = String.valueOf(r.get('customer'));
            Long early = Double.valueOf(r.get('early')).longValue();
            Long late = Double.valueOf(r.get('late')).longValue();
            Long collapsed = Double.valueOf(r.get('collapsed')).longValue();
            
            rList.add(
                new ThisMonthRecord(
                    customer, late, early, collapsed
                )
            );
        }
        
        earlyTotal = 0;
        lateTotal = 0;
        collapsedTotal = 0;
        for (AggregateResult r: thisMonthTotalList) {
            earlyTotal += Double.valueOf(r.get('early')).longValue();
            lateTotal += Double.valueOf(r.get('late')).longValue();
            collapsedTotal += Double.valueOf(r.get('collapsed')).longValue();
        } 
        rList.add(
            new ThisMonthRecord(
                'Current Month Totals', lateTotal, earlyTotal, collapsedTotal
            )
        );
        for (AggregateResult r: thisMonthTotalList) {
            String customer = String.valueOf(r.get('customer'));
            Long early = Double.valueOf(r.get('early')).longValue();
            Long late = Double.valueOf(r.get('late')).longValue();
            Long collapsed = Double.valueOf(r.get('collapsed')).longValue();
            
            rList.add(
                new ThisMonthRecord(
                    customer, late, early, collapsed
                )
            );
        }
        return rList; 
    }
    
    public String getLast48hourLateReportLink() {
        return  baseURL + '/' + cs.OTIF_Previous_48Hour_Late_Load_List__c;
    }
    
    public String getLast48hourEarlyReportLink() {
        return baseURL + '/' + cs.OTIF_Previous_48Hour_Early_Load_List__c;
    }
    
    public String getLast48hourCollapsedReportLink() {
        return baseURL + '/' + cs.OTIF_Previous_48Hour_Collapsed_Load_List__c;
    }
    
    public String getLateLoadReportLink() {
        return baseURL + '/' + cs.OTIF_Current_Month_Late_Load_List__c;
    }
    
    public String getEarlyLoadReportLink() {
        return baseURL + '/' + cs.OTIF_Current_Month_Early_Load_List__c;
    }
    
    public String getCollapsedLoadReportLink() {
        return baseURL + '/' + cs.OTIF_Current_Month_Collapsed_Load_List__c;
    }
    
    public class ThisMonthRecord {      
        public String customer      {get; set;}
        public Long late            {get; set;}
        public Long early           {get; set;}
        public Long collapsed       {get; set;}
        
        public ThisMonthRecord(String customer, Long late, Long early, Long collapsed) {
            this.customer = customer;
            this.late = late;
            this.early = early;
            this.collapsed = collapsed;
        }
    }
    
}*/