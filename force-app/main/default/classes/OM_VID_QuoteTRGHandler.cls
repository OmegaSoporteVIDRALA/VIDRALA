public class OM_VID_QuoteTRGHandler {
    
    private static Boolean byPassApex = false;

	public static void setbyPassApex(Boolean skip){
		byPassApex = skip;        
	}

	public static Boolean getbyPassApex(){
		return byPassApex;
	}
    
    public static void execute(
        List<Quote> news,
        Map<Id, Quote> oldsMap,
        Boolean isBefore,
        Boolean isAfter,
        Boolean isInsert,
        Boolean isUpdate,
        Boolean isDelete
    ) {
        if (byPassApex) {
            return;
        }
        if (isBefore) {
            if (isInsert) {
            
            }

            if(isUpdate){
                
            }
        }

        if (isAfter) {
            if (isInsert) {
            	OM_VID_QuoteTRGHandlerMethods.quoteFieldsTranslation(news);
                OM_VID_QuoteTRGHandlerMethods.createTasksForSendingQuotes(news);
            }

            if(isUpdate){
               
            }
        }
    }

}