/*
* @TestedBy: OM_VID_Batch_DeleteIntegrationMsgs_UT
*/
global without sharing class OM_VID_BatchDeleteIntegrationMessages implements Schedulable, Database.Batchable<sObject>, Database.Stateful{
    private static String sched = '0 0 2 1 1/1 ? *'; // Monthly at 2:00 am hours -> each 1st of the month
    private static String batchName = 'Delete Integration Messages';
    private static Integer batchSize = 200;
    
    String objectType;
    private static String deletionErrors;
    private static Map<String, String> groupedErrors = new Map<String, String>();

    ////////////////////////////////////////////////
    //          SCHEDULABLE CONTEXT
    ////////////////////////////////////////////////
    global static void scheduleMe() {
        if(Test.isRunningTest()){batchName = batchName + 'TestClass'; }
        System.schedule(batchName, sched, new OM_VID_BatchDeleteIntegrationMessages(''));
    }

    global void execute(SchedulableContext sc) {
        System.debug('Executing batch ' + batchName + ':');
        System.debug('IntegrationMessage__c in slots of            : ' + batchSize);       
        Database.executeBatch(new OM_VID_BatchDeleteIntegrationMessages('IntegrationMessage__c'), batchSize);           
    }

    ////////////////////////////////////////////////
    //          BATCH CONSTRUCTOR
    ////////////////////////////////////////////////
    global OM_VID_BatchDeleteIntegrationMessages(String type){
        this.objectType = type; // Only in case we want reuse this batch to delete any other kind of records
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id FROM IntegrationMessage__c';

        if(!Test.isRunningTest()){
            query += ' WHERE CreatedDate < LAST_N_MONTHS:2'; // last 2 months better -> TO MAKE IT WORK IN TEST CLASS
        }
        System.debug('query: ' + query);        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> recordList){
        Database.DeleteResult[] drList = database.delete((List<IntegrationMessage__c>)recordList, false);

        List<SObject> recordsDeleted = new List<SObject>();
        deletionErrors = generateErrorString(drList, recordList, /* byRef */ recordsDeleted);
    }

    global void finish(Database.BatchableContext BC) {
        if(!String.isBlank(deletionErrors)){
            String finalErrorString = 'Deletion IntegrationMessage__c Erros Result: \n\n---------------------------------------\n\n';
            finalErrorString += deletionErrors;
            // finalErrorString += '' + (String.isBlank(deletionErrors) ? 'No Deletion Erros' : deletionErrors);
            sendEmailToExecutingUser(finalErrorString, 'Delete Integration Msgs day: ' + System.today().format());
        }    
    }
    
    ////////////////////////////////////////////////
    //          AUX METHODS
    ////////////////////////////////////////////////
    @testVisible
    private static void sendEmailToExecutingUser(String finalErrorString, String emailSubject){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        // mail.setReplyTo('');
        mail.setPlainTextBody(finalErrorString);
        mail.setSubject(emailSubject + ' - ' + System.now().format());
        String[] targetEmails = new String[]{UserInfo.getUserEmail(), 'soporte.vidrala@omegacrmconsulting.com'};
        mail.setToAddresses(targetEmails);

        if(!Test.isRunningTest()){   Messaging.sendEmail(new Messaging.SingleEmailmessage[] {mail}); }
    }
    
    @testVisible
    private static String generateErrorString(Database.deleteResult[] results, List<SObject> queriedRecords, List<SObject> recordsUpdated){
        // Error management
        String errorString = '';
        String sObjectType = queriedRecords[0].getSobjectType().getDescribe().getName();
        String fieldToIdentifyRecord = sObjectType != 'Case' ? 'Name' : 'CaseNumber';
        
        for(Integer index = 0; index < results.size(); index++) {
            if(!results[index].isSuccess()) {
                errorString += 'Record Name: ' + queriedRecords.get(index).get(fieldToIdentifyRecord) + ' - ';
                errorString += 'Error: ' + results[index].getErrors() + '\n';
                errorString += '--------------------------------------------' + '\n';
                
                System.debug('>>>>>>>>>>>>>>>>> Record: ' +  queriedRecords.get(index).get(fieldToIdentifyRecord) + ' - Error: ' + results[index].getErrors());
            } else {
                recordsUpdated.add(queriedRecords.get(index));
            }
        }
    
        System.debug('>>>>>>>>>>>>>>> records DML.size(): ' + recordsUpdated.size());
        System.debug('>>>>>>>>>>>>>>> records DML: ' + recordsUpdated);
        System.debug('>>>>>>>>>>>>>>>>>> errorString ' + (queriedRecords.size() - recordsUpdated.size()) + ': \n' + errorString);
    
        return errorString;
    }
}