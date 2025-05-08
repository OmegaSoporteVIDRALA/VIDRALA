/**
* @description       :
* @author            : mmadridp@omegacrmconsulting.com
* @group             :
* @last modified on  : 14-03-2024
* @last modified by  : mmadridp@omegacrmconsulting.com
**/
@isTest
public with sharing class OM_VID_OpportunityTRGTest {
    @TestSetup
    static void makeData(){
        List<Opportunity> listOpps = OM_VID_TestUtils.createOpportunities(2);
        OM_VID_TestUtils.createOpportunityLineItems(listOpps, 2, '');

    }

    @isTest
    public static void testCreateQuoteFifty(){
        String recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = :OM_VID_Constants.oppName AND DeveloperName =: OM_VID_Constants.opportunityRTFifty LIMIT 1].Id;
        List<Opportunity> listOpps = [SELECT Id, Name, CloseDate FROM Opportunity WHERE RecordTypeId = :recordTypeId LIMIT 1];

        Test.startTest();
        for(Opportunity opp : listOpps){
            opp.StageName = OM_VID_Constants.opportunityStatusQuotation;
        }

        update listOpps;
        Test.stopTest();

        System.assertEquals(listOpps.size()+1, [SELECT Id FROM Quote].size());
        //System.assertEquals([SELECT Id FROM OpportunityLineItem].size(), [SELECT Id FROM QuoteLineItem].size());
        //System.assertEquals(listOpps[0].CloseDate, Date.today() + 30);
    }
}