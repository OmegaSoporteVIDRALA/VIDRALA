/**
 *  Apex class to send email to the selected users
 *
 *  @author  Globant 
 *  @since   July 2023
 */
public class SendNotificationEmail {

    private static final String SEPARATOR = ',';
    private static final String NEW_LINE = '\n';
    @TestVisible private static final String ERROR_MESSAGE = 'Email, subject and email content are mandatory.';
    
    /**
     *  Custom Exception class
     */
    private class SendNotificationEmailException extends Exception { }

    /**
     *  This function is used to send email to the selected users 
     * 
     *  @param  dispatchStagings  This parameter is used to get all potential Dispatch Staging records
     */
    public static void sendEmailsToUsers(List<Dispatch_Staging__c> dispatchStagings) {

        try {
            
            List<Messaging.SingleEmailMessage> singleEmailMessages = new List<Messaging.SingleEmailMessage>();
            Integer dispatchStagingsSize = !dispatchStagings.isEmpty() 
                                                ? dispatchStagings.size() 
                                                : null;
            
            String emailAddress;
            String emailSubject;
            String emailBody;

            List<User> emailRecipients = [
                SELECT Name, Email 
                FROM User
                WHERE Name IN :System.Label.UserNameToSendNotificationEmail.split(SEPARATOR)
            ];
                
            for (User recipient :emailRecipients) {
                
                emailAddress = recipient.Email;
                emailSubject = dispatchStagingsSize != null 
                                    ? System.Label.SuccessLoadDataSubject
                                    : System.Label.FailedLoadDataSubject;
                emailBody = dispatchStagingsSize != null 
                                ? formattedSuccessEmailBody(dispatchStagingsSize)
                                : System.Label.FailedLoadDataBody;

                singleEmailMessages.add(
                    sendEmailHelper(
                        emailAddress, 
                        emailSubject, 
                        emailBody
                    )
                );
            }

            List<Messaging.SendEmailResult> messagingResultSet = Messaging.sendEmail(singleEmailMessages);            
            throwErrorsIfAnyEmailFailedToSend(messagingResultSet);
        } catch (Exception ex) {
            
            throw new SendNotificationEmailException(ex.getMessage());
        }
    }

    /**
     *  This function is helper method used to send email
     * 
     *  @param  emailAddress             The email address where email need to send
     *  @param  loadDispatchStagingSize  The size of the load Dispatch Staging object 
     *  @param  subject                  Subject of the email 
     *  @param  body                     Content/Body of the email 
     *  @return                          A singleEmailMessage instance as needed to send email
     *  @see                             SingleEmailMessage
     */
    @TestVisible
    private static Messaging.SingleEmailMessage sendEmailHelper(String emailAddress, String emailSubject, String emailBody) {
        
        if (String.isBlank(emailAddress)
                || String.isBlank(emailSubject)
                || String.isBlank(emailBody)) {
            
            throw new SendNotificationEmailException(ERROR_MESSAGE);
        }

        Messaging.SingleEmailMessage singleEmailMessage = new Messaging.SingleEmailMessage();

        singleEmailMessage.setToAddresses(new List<String>{ emailAddress });
        singleEmailMessage.setSubject(emailSubject);
        singleEmailMessage.setPlainTextBody(emailBody);

        return singleEmailMessage;
    }

    /**
     *  This function is used to format the String
     * 
     *  @param  dispatchStagingsSize  This parameter is used to have size of the dispatch stagings
     *  @return                         returns formatted body of the success email
     */
    @TestVisible
    private static String formattedSuccessEmailBody(Integer dispatchStagingsSize) {
        
        return String.format(System.Label.SuccessLoadDataBody, new List<Object> { dispatchStagingsSize });
    }

    /**
     *  This function is used to throw the errors if encounter while email sending 
     * 
     *  @param  messagingResultSet  This parameter is used to send result of the message sending
     */
    @TestVisible
    private static void throwErrorsIfAnyEmailFailedToSend(List<Messaging.SendEmailResult> messagingResultSet) {
        
        List<Messaging.SendEmailError> sendEmailErrors;
        String errors = '';

        for (Messaging.SendEmailResult sendEmailResult : messagingResultSet) {
            
            if (sendEmailResult.isSuccess()) {

                continue;
            }

            sendEmailErrors = sendEmailResult.getErrors();

            for (Messaging.SendEmailError e: sendEmailErrors) {
                
                errors += e.getStatusCode() + SEPARATOR + e.getMessage() + NEW_LINE;
            }    
        }

        if (String.isNotBlank(errors)) {
            
            throw new SendNotificationEmailException(errors);
        }
    }
}