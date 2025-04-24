/* -----------------------------------------------------------------------------------------------------------------------
   Name:        AccountTriggerHandler.cls
   Description: Handler class for processing of the Accounts
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Oct 2024     1.0     globant             After update, recalculate child object Apex sharing if Account Owner has changed 
                                            or Recalculate_Apex_Sharing__c = true
------------------------------------------------------------------------------------------------------------------------ */        
public with sharing class AccountTriggerHandler {

    public static void processAccountRecords(List<Account> triggerNew, Map<Id, Account> triggerOldMap) {

        //Change Month Forecast Owners if Owner has changed
        ForecastHandler handler = new ForecastHandler();
        handler.copyChangedAccountOwner(triggerNew, triggerOldMap);
        
        //Sharing changes on change of Account Owner
        //In all cases below, action only if Owner has changed or Recalculate_Apex_Sharing__c = true
        ApexSharingManager sharingManager1 = new ApexSharingManager(
            Schema.SObjectType.Rebate__c.Name, 
            Schema.Rebate__Share.rowCause.Apex__c
        );
        sharingManager1.newAccountOwner(Schema.SObjectType.Rebate__c.Fields.Account__c.RelationshipName, triggerNew, triggerOldMap); 
        
        ApexSharingManager sharingManager2 = new ApexSharingManager(
            Schema.SObjectType.Commercial_Contracts__c.Name, 
            Schema.Commercial_Contracts__Share.rowCause.Apex__c
        );
        sharingManager2.newAccountOwner(Schema.SObjectType.Commercial_Contracts__c.Fields.Account__c.RelationshipName, triggerNew, triggerOldMap); 
        
        ApexSharingManager sharingManager3 = new ApexSharingManager(
            Schema.SObjectType.Customer_Tender_Stroke_Quotes__c.Name, 
            Schema.Commercial_Contracts__Share.rowCause.Apex__c
        );
        sharingManager3.newAccountOwner(Schema.SObjectType.Customer_Tender_Stroke_Quotes__c.Fields.Account__c.RelationshipName, triggerNew, triggerOldMap); 
        
        ApexSharingManager sharingManager4 = new ApexSharingManager(
            Schema.SObjectType.Pricing_Model__c.Name, 
            Schema.Commercial_Contracts__Share.rowCause.Apex__c
        );
        sharingManager4.newAccountOwner(Schema.SObjectType.Pricing_Model__c.Fields.Account__c.RelationshipName, triggerNew, triggerOldMap); 
    }
}