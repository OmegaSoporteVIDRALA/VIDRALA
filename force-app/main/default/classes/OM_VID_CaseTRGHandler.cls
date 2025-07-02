/*
* @TestedBy: OM_VID_CaseTRGHandler_Test
*/
public class OM_VID_CaseTRGHandler {
	
    public static void execute(
        List<Case> news,
        Map<Id, Case> oldsMap,
        Boolean isBefore,
        Boolean isAfter,
        Boolean isInsert,
        Boolean isUpdate,
        Boolean isDelete
    ) {

        if (isBefore) {
            if (isInsert) {
            	OM_VID_CaseTRGHandlerMethods.caseBeforeInsertActions(news);
            }

            if(isUpdate){
            }
        }

        if (isAfter) {
            if (isInsert) {
                OM_VID_CaseTRGHandlerMethods.caseAfterInsertActions(news);
            }

            if(isUpdate){
            }
        }
    }
}