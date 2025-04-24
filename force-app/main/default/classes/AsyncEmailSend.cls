/* -----------------------------------------------------------------------------------------------------------------------
   Name:        AsyncEmailSend.cls
   Description: Send up to 10 emails to Users using a future method
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Sep 2024     2.0     Globant   			Code Refactoring
------------------------------------------------------------------------------------------------------------------------ */     

public class AsyncEmailSend {

    @future
    public static void sendTemplateEmail(String emailTemplateId, List<ID> userIdList) {
        if (emailTemplateId != null && !userIdList.isEmpty()) {
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            Integer max = userIdList.size() > 10 ? 10 : userIdList.size();
            
            for (Integer i = 0; i < max; i++) {
                ID userId = userIdList[i];
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(emailTemplateId);
                mail.setTargetObjectId(userId);
                mail.setSaveAsActivity(false);
                emailList.add(mail);
            }
            
            if (!emailList.isEmpty()) {
                Messaging.sendEmail(emailList);
            }
        }
    }
}



/*public class AsyncEmailSend {
    
    @future
    public static void sendTemplateEmail (String emailTemplateId, List<ID> userIdList) {
        if (emailTemplateId != null) {
            Integer max = userIdList.size() > 10 ? 10 : userIdList.size();
            for(Integer i=0; i<max; i++) {
                ID userId = userIdList[i];
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(emailTemplateId);
                mail.setTargetObjectId(userId);
                mail.setSaveAsActivity(false);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }

}*/