/**
 *  Apex test class of the ScheduledCCEmails.cls
 *
 *  @author  Globant 
 *  @since   July 2023
 */
@isTest
public with sharing class ScheduledCCEmailsTest {

    @TestSetup
    static void makeData(){

        Account acc = new Account();
        acc.Name = 'testAccount';
        insert acc;

        List<Consumer_Complaint__c> ccs = new List<Consumer_Complaint__c>();
        
        for (Integer i = 0; i < 25; i++) {
            Consumer_Complaint__c cc = new Consumer_Complaint__c();
            cc.Customer__c = acc.Id;
            cc.Manufacturing_Fault_Present__c = 'Yes';
            cc.Independent_Analysis__c = 'No';
            ccs.add(cc);
        }
        insert ccs;

        Integer offset = 0;

        for (Consumer_Complaint__c cc : ccs) {
            cc.Sample_Arrived__c = System.today().addDays(offset);
            cc.Complaint_Type_Confirmed_Date__c = System.today().addDays(offset);
            offset--;
        }
        update ccs;
    }

    @isTest
    static void itShouldSetupEmail(){
        
        BusinessHours hours = [SELECT ID FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        List<Consumer_Complaint__c> complaints = [
            SELECT Complaint_Type_Confirmed_Date__c, Sample_Arrived__c, Manufacturing_Fault_Present__c,
                Legal__c, Injury__c, Plant__c, Quality_Managers_Comments__c, Report_Complete__c, Independent_Analysis__c, CreatedDate
            FROM Consumer_Complaint__c 
            WHERE Complaint_Type_Confirmed_Date__c = LAST_N_DAYS:10 OR Sample_Arrived__c = LAST_N_DAYS:30
        ];
        
        Test.startTest();

            Assert.areEqual(0, Limits.getEmailInvocations(), 'No emails should be sent.');

            Map<Integer, List<Consumer_Complaint__c>> ccByDays = ScheduledCCEmails.calculateWorkDays(complaints, hours);
            ScheduledCCEmails.setupEmails(ccByDays);
            
            for (Consumer_Complaint__c cc : complaints) {
                cc.Plant__c = 'Unknown';
            }

            ccByDays = ScheduledCCEmails.calculateWorkDays(complaints, hours);
            ScheduledCCEmails.setupEmails(ccByDays);
            
            for (Consumer_Complaint__c cc : complaints) {
                cc.Plant__c = 'Elton';
            }

            ccByDays = ScheduledCCEmails.calculateWorkDays(complaints, hours);
            ScheduledCCEmails.setupEmails(ccByDays);
    
            for (Consumer_Complaint__c cc : complaints) {
                cc.Plant__c = 'Derrylin';
            }

            ccByDays = ScheduledCCEmails.calculateWorkDays(complaints, hours);
            ScheduledCCEmails.setupEmails(ccByDays);
    
            for (Consumer_Complaint__c cc : complaints) {
                cc.Plant__c = 'Corsico';
            }

            ccByDays = ScheduledCCEmails.calculateWorkDays(complaints, hours);
            ScheduledCCEmails.setupEmails(ccByDays);
    
            for (Consumer_Complaint__c cc : complaints) {
                cc.Plant__c = null;
                cc.Manufacturing_Fault_Present__c = null;
            }

            ccByDays = ScheduledCCEmails.calculateWorkDays(complaints, hours);
            ScheduledCCEmails.setupEmails(ccByDays);
    
            for (Consumer_Complaint__c cc : complaints) {
                cc.Independent_Analysis__c = 'Yes';
                cc.Manufacturing_Fault_Present__c = 'Yes';
            }

            ccByDays = ScheduledCCEmails.calculateWorkDays(complaints, hours);
            ScheduledCCEmails.setupEmails(ccByDays);
    
            ScheduledCCEmails s = new ScheduledCCEmails();
            String sch = '0 0 0 31 DEC ? 2030';
            String jobId = System.schedule('Test Job', sch, s);

            // Assert that the job has been scheduled
            Assert.areNotEqual(null, jobId, 'Job Id should be create.');

            // Use other assertions as needed to check job properties, such as the job name, schedule time, etc.
            CronTrigger scheduledJob = [SELECT Id, CronExpression, NextFireTime FROM CronTrigger WHERE Id = :jobId];
            Assert.areNotEqual(null, scheduledJob, 'Job should be scheduled.');
            Assert.areEqual(7, Limits.getEmailInvocations(), 'Emails should be sent.');
        Test.stopTest();
    }

    @isTest
    static void itShouldNotSetupEmail(){
        
        Test.startTest();

            Assert.areEqual(0, Limits.getEmailInvocations(), 'No emails should be sent.');
    
            ScheduledCCEmails s = new ScheduledCCEmails();
            String sch = '0 0 0 31 DEC ? 2030';
            String jobId = System.schedule('Test Job', sch, s);

            // Assert that the job has been scheduled
            Assert.areNotEqual(null, jobId, 'Job Id should be create.');

            // Use other assertions as needed to check job properties, such as the job name, schedule time, etc.
            CronTrigger scheduledJob = [SELECT Id, CronExpression, NextFireTime FROM CronTrigger WHERE Id = :jobId];
            Assert.areNotEqual(null, scheduledJob, 'Job should be scheduled.');
            Assert.areEqual(0, Limits.getEmailInvocations(), 'Emails should be sent.');
        Test.stopTest();
    }

    @isTest
    static void itShouldCreateGroupMembersByPlantMap(){

        Test.startTest();

            Map<String, Map<Id, GroupMember>> groupMemberMap = ScheduledCCEmails.getGroupMembersMapByDeveloperName();
            Map<String, List<GroupMember>> groupNumbers = ScheduledCCEmails.createGroupMembersByPlantMap(groupMemberMap);
            
            //Assert
            Assert.areEqual(4, groupNumbers.size(), 'It should have group numbers.');
        Test.stopTest();
    }

    @isTest
    static void itShouldNotCreateGroupMembersByPlantMap(){

        String errorMessage;

        Test.startTest();

            try {
                
                Map<String, List<GroupMember>> groupNumbers = ScheduledCCEmails.createGroupMembersByPlantMap(null);
            } catch (Exception ex) {
                
                errorMessage = ex.getMessage();
            }
            
            //Assert
            Assert.areNotEqual(null, errorMessage, 'It should throw error.');
        Test.stopTest();
    }

    @isTest
    static void itShouldGetEmailTemplateMapByDeveloperName(){

        Test.startTest();

            Map<String, EmailTemplate> templates = ScheduledCCEmails.getEmailTemplateMapByDeveloperName();
            
            //Assert
            Assert.areEqual(4, templates.size(), 'It should have templates.');
        Test.stopTest();
    }

    @isTest
    static void itShouldInitiateDateTimeWith9PM(){

        DateTime now = System.now();
        now = DateTime.newInstance(now.year(), now.month(), now.day(), 21, 00, 0);

        Test.startTest();

            DateTime dt = ScheduledCCEmails.initiateDateTimeWith9PM();
            
            //Assert
            Assert.areEqual(now, dt, 'It should have initial datetime as 9 PM.');
        Test.stopTest();
    }

    @isTest
    static void itShouldAddEmailToStoredEmailTemplate(){

        BusinessHours hours = [SELECT ID FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        List<Consumer_Complaint__c> complaints = [
            SELECT Complaint_Type_Confirmed_Date__c, Sample_Arrived__c, Manufacturing_Fault_Present__c,
                Legal__c, Injury__c, Plant__c, Quality_Managers_Comments__c, Report_Complete__c, Independent_Analysis__c, CreatedDate
            FROM Consumer_Complaint__c 
            WHERE Complaint_Type_Confirmed_Date__c = LAST_N_DAYS:10 OR Sample_Arrived__c = LAST_N_DAYS:30
        ];

        Map<String, EmailTemplate> templates = ScheduledCCEmails.getEmailTemplateMapByDeveloperName();
        Map<String, Map<Id, GroupMember>> groupMemberMap = ScheduledCCEmails.getGroupMembersMapByDeveloperName();
        
        Test.startTest();

            List<Messaging.SingleEmailMessage> singleMessage = ScheduledCCEmails.addEmailToStoredEmailTemplate(
                groupMemberMap.get('Consumer_Complaints_Admin').values(),
                templates.get('X3_Days_and_no_QM_Comments').Id,
                complaints.get(0)
            );
            
            //Assert
            Assert.areNotEqual(null, singleMessage, 'It should add email template.');
        Test.stopTest();
    }

    @isTest
    static void itShouldNotAddEmailToStoredEmailTemplate(){
        
        String errorMessage;

        Test.startTest();

            try {
                
                List<Messaging.SingleEmailMessage> singleMessage = ScheduledCCEmails.addEmailToStoredEmailTemplate(
                    null, null, null
                );
            } catch (Exception ex) {
                
                errorMessage = ex.getMessage();
            }
            //Assert
            Assert.areNotEqual(null, errorMessage, 'It should throw Error.');
        Test.stopTest();
    }
}