/**
 *  Apex test class of the SendNotificationEmail.cls
 *
 *  @author  Globant 
 *  @since   July 2023
 */
@isTest
public class SendNotificationEmailTest {

    private static String numOfHaulier = '1234';
    private static Integer numOfBottles = 200000;
    private static Integer numOfTonnes = 20;

    @isTest
    static void itShouldSendEmail() {

        //Create Test Data (create one Account)
        List<Account> aList = TestDataFactory.createAccountsWithMonths(1, 10001);
        String acctNumber = aList[0].SAP_Account_Number__c;

        //create 1 dispatch staging record(s)
        List<Dispatch_Staging__c> dList = TestDataFactory.createDispatchStaging(1, acctNumber, numOfHaulier, numOfBottles, numOfTonnes);
    
        Test.startTest();

            Assert.areEqual(0, Limits.getEmailInvocations(), 'No emails should be sent.');
            // Call the method being tested
            SendNotificationEmail.sendEmailsToUsers(dList);
            //Assert
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Emails should be sent.');
        Test.stopTest();
    }

    @isTest
    static void itShouldNotSendEmail() {

        String errorMessage;
        
        Test.startTest();

            Assert.areEqual(0, Limits.getEmailInvocations(), 'No emails should be sent.');
            
            try {
                
                // Call the method being tested
                SendNotificationEmail.sendEmailsToUsers(null);
            } catch (Exception ex) {
                
                errorMessage = ex.getMessage();
            }
            //Assert
            Assert.areEqual(0, Limits.getEmailInvocations(), 'Email should not be sent.');
            Assert.areNotEqual(null, errorMessage, 'Error should be thrown.');
        Test.stopTest();
    }

    @isTest
    static void itShouldInitiateSendEmail() {

        String emailAddress = 'example@encric.com';
        String emailSubject = 'Testing Subject';
        String emailBody = 'Testing Body';

        Test.startTest();

            // Call the method being tested
            Messaging.SingleEmailMessage singleEmail = SendNotificationEmail.sendEmailHelper(
                emailAddress, 
                emailSubject, 
                emailBody
            );
            //Assert
            Assert.areEqual(singleEmail.getToAddresses().get(0), 'example@encric.com', 'Emails instance should have email address');
            Assert.areEqual(singleEmail.getSubject(), 'Testing Subject', 'Emails instance should have subject');
            Assert.areEqual(singleEmail.getPlainTextBody(), 'Testing Body', 'Emails instance should have body');
        Test.stopTest();
    }

    @isTest
    static void itShouldNotInitiateSendEmail() {

        String emailAddress = null;
        String emailSubject = 'Testing Subject';
        String emailBody = 'Testing Body';

        Test.startTest();

            try {
                
                // Call the method being tested
                Messaging.SingleEmailMessage singleEmail = SendNotificationEmail.sendEmailHelper(
                    emailAddress, 
                    emailSubject, 
                    emailBody
                );
            } catch (Exception ex) {
                
                //Assert
                Assert.areEqual(ex.getMessage(), SendNotificationEmail.ERROR_MESSAGE, 'It should throw an error.');
            }
        Test.stopTest();
    }

    @isTest
    static void itShouldReturnFormattedSuccessEmailBody() {
    
        Integer dispatchStagingsSize = 1;
        String emailBody = '';

        Test.startTest();

            // Call the method being tested
            emailBody = SendNotificationEmail.formattedSuccessEmailBody(dispatchStagingsSize);
        Test.stopTest();

        //Assert
        Assert.isTrue(emailBody.contains('1'), 'It should contain 1 in the email body');
    }

    @isTest
    static void itShouldNotReturnFormattedSuccessEmailBody() {
    
        String errorMessage;

        Test.startTest();

            try {
                
                // Call the method being tested
                SendNotificationEmail.formattedSuccessEmailBody(null);
            }
            catch (Exception ex) {
                
                errorMessage = ex.getMessage();
            }

            //Assert
            Assert.areEqual(null, errorMessage, 'Error should be thrown.');
        Test.stopTest();
    }

    @isTest
    static void itShouldThrowErrorsIfAnyEmailFailedToSend() {
    
        String errorMessage;

        Test.startTest();

            try {
                
                // Call the method being tested
                List<Messaging.SendEmailResult> resultSet = Messaging.sendEmail(null);            
                SendNotificationEmail.throwErrorsIfAnyEmailFailedToSend(resultSet);
            } catch (Exception ex) {
              
                errorMessage = ex.getMessage();
            }
        Test.stopTest();

        //Assert
        Assert.areNotEqual(null, errorMessage, 'Error should be thrown.');
    }
}