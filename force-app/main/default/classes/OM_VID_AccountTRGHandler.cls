/*
* @TestedBy: OM_VID_AccountTRGHandler_UT
*/
public class OM_VID_AccountTRGHandler{
         
    public static void execute(
        List<Account> news,
        Map<Id, Account> oldsMap,
        Boolean isBefore,
        Boolean isAfter,
        Boolean isInsert,
        Boolean isUpdate,
        Boolean isDelete
    ) {

        if (isBefore) {
            if (isInsert) {
               OM_VID_AccountTRGHandlerMethods.setOwnerId(news);
            }

            if(isUpdate){
            }
        }

        if (isAfter) {
            if (isInsert) {
            	OM_VID_AccountTRGHandlerMethods.customerInsertActions(news);
            }

            if(isUpdate){
            }
        }
    }
}