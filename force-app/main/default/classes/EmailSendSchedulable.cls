/* -----------------------------------------------------------------------------------------------------------------------
   Name:        EmailSendSchedulable.cls
   Description: Schedule asynchronous email sends, 10 emails at a time
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Sep 2024     1.1     Globant             Code Refactoring and Added Comments
------------------------------------------------------------------------------------------------------------------------ */

global class EmailSendSchedulable implements Schedulable {
    private String emailTemplateId;
    private List<ID> userIdList;
    
    /**
     * Constructor for EmailSendSchedulable.
     * Initializes the schedulable class with the email template ID and the list of user IDs.
     * 
     * @param emailTemplateId - The ID of the email template to use for sending emails.
     * @param userIdList - The list of user IDs to whom the emails will be sent.
     */
    global EmailSendSchedulable(String emailTemplateId, List<ID> userIdList) {
        this.emailTemplateId = emailTemplateId;
        this.userIdList = userIdList;
    }
    
    /**
     * Executes the scheduled job to send emails in batches of 10 users.
     * 
     * @param sc - The context of the scheduled job.
     */
    global void execute(SchedulableContext sc) {
        List<ID> emailUserIdList = new List<ID>();
        for(ID userId: userIdList) {
            emailUserIdList.add(userId);
            if (emailUserIdList.size() == 10) {
                AsyncEmailSend.sendTemplateEmail(emailTemplateId, emailUserIdList);
                emailUserIdList.clear();
            }
        }
        if (emailUserIdList.size() > 0) {
            AsyncEmailSend.sendTemplateEmail(emailTemplateId, emailUserIdList);
        }
    }
}



/*global class EmailSendSchedulable implements Schedulable {
    private String emailTemplateId;
    private List<ID> userIdList;
    
    global EmailSendSchedulable(String emailTemplateId, List<ID> userIdList) {
        this.emailTemplateId = emailTemplateId;
        this.userIdList = userIdList;
    }
    
    global void execute(SchedulableContext sc) {
        List<ID> emailUserIdList = new List<ID>();
        for(ID userId: userIdList) {
            emailUserIdList.add(userId);
            if (emailUserIdList.size() == 10) {
                AsyncEmailSend.sendTemplateEmail(emailTemplateId, emailUserIdList);
                emailUserIdList.clear();
            }
        }
        if (emailUserIdList.size() > 0 && !Test.isRunningTest()) AsyncEmailSend.sendTemplateEmail(emailTemplateId, emailUserIdList);
    }
}*/