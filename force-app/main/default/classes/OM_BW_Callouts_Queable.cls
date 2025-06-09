public class OM_BW_Callouts_Queable implements Queueable, Database.AllowsCallouts{
    private String salesOrganization;
    private String salesGroup;
    private String month;
    private String year;
    public OM_BW_Callouts_Queable(String salesOrganization,String salesGroup) {
        this.salesGroup = salesGroup;
        this.salesOrganization = salesOrganization;
        this.month = String.valueOf(Date.Today().month() -1);
        this.year = this.month == '12' ? String.valueOf(Date.Today().year() -1) : String.valueOf(Date.Today().Year());
    }

    public OM_BW_Callouts_Queable(String salesOrganization,String salesGroup, String month, String year) {
        this.salesGroup = salesGroup;
        this.salesOrganization = salesOrganization;
        this.month = month;
        this.year = year;
    }

    public void execute(QueueableContext context) {
        String jsonFilter ='';
        try{
            String monthFrom = this.month;
            String monthTo = this.month;
            String yearFrom = this.year;
            String yearTo = this.year;
            jsonFilter = OM_BW_InsertActualSalesHistory.createJsonBWWrapper(yearFrom, yearTo, monthFrom, monthTo, salesOrganization, salesGroup);
            OM_BW_InsertActualSalesHistory.insertActualSalesHistory(jsonFilter);
        	
        }catch(Exception ex){
            System.debug('Entra catch: '+ex.getMessage());
        }
    }
}