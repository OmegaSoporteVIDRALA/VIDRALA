@isTest
public with sharing class OM_VID_Batch_DeleteIntegrationMsgs_UT {
    @TestSetup
    static void makeData(){
        OM_Utils.IntegrationMsg.createRESTIntegrationMsg(OM_Utils.IntegrationMsg.OUTBOUND, 'www.test.com', 'POST');
        OM_Utils.IntegrationMsg.addBody('request body', 'response body');
        OM_Utils.IntegrationMsg.addStatusAndRecord(OM_Utils.IntegrationMsg.ERROR, '001215', 'Account', null);
        OM_Utils.IntegrationMsg.insertRecord();
    }

    @isTest static void schedulingTest(){
        OM_VID_BatchDeleteIntegrationMessages.scheduleMe();
    }

    @isTest static void batchContextTest(){
        OM_VID_BatchDeleteIntegrationMessages batchClass = new OM_VID_BatchDeleteIntegrationMessages('IntegrationMessage__c');
        batchClass.start(null);
        batchClass.execute(null, [SELECT Id FROM IntegrationMessage__c]);
        batchClass.finish(null);

        Assert.areEqual(0, [SELECT Id FROM IntegrationMessage__c].size(), 'All Records removed from the system');
    }
    
    @isTest static void auxMethodsTest(){
        OM_VID_BatchDeleteIntegrationMessages.sendEmailToExecutingUser('This is an error string', 'emailSubject');
    }

}