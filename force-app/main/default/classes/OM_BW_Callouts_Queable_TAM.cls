public class OM_BW_Callouts_Queable_TAM implements Queueable, Database.AllowsCallouts {
    
    private String year;
    private String month;
    private String salesGroup;

    public OM_BW_Callouts_Queable_TAM(String year, String month, String salesGroup) {
        this.year = year;
        this.month = month;
        this.salesGroup = salesGroup;
    }

    public void execute(QueueableContext qc) {
        String jsonFilter = OM_BW_InsertTAMReport.createJsonBWWrapper(year, month, salesGroup);
        
        OM_BW_Wrapper.BWFilter filterWrapper = (OM_BW_Wrapper.BWFilter) JSON.deserialize(jsonFilter, OM_BW_Wrapper.BWFilter.class);
        
        OM_BW_InsertTAMReport.tamCalloutBW(filterWrapper);
        
        System.debug('TAM Queueable ejecutado para el periodo: ' + month + '.' + year);
    }
}