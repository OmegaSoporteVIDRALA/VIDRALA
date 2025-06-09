public class OM_BW_Callouts_Scheduler implements Schedulable {
    /*IMPORTANTE - HACER QUE SE EJECUTE EL DÍA 5 DE CADA MES A LAS 20:00. SERÁN 12 EJECUCIONES DE ESTE SCHEDULABLE, 1 POR CADA SALESGROUP (GRUPO DE VENTAS).
      PARA EJECUTAR: 
      String cronExpression = '0 0 20 5 * ?'; // Cron para el día 5 de cada mes a las 20:00
	  System.schedule('MonthlyActualSalesHistory', cronExpression, new OM_BW_Callouts_Scheduler());
	*/
    private String salesGroup;
    private String salesOrganization;
    
    public OM_BW_Callouts_Scheduler(String salesOrganization, String salesGroup) {
        this.salesGroup = salesGroup; 
        this.salesOrganization = salesOrganization;
    }

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new OM_BW_Callouts_Queable(salesOrganization, salesGroup));

    }
}