/**
* @description       :
* @author            : mmadridp@omegacrmconsulting.com
* @group             :
* @last modified on  : 14-03-2024
* @last modified by  : mmadridp@omegacrmconsulting.com
**/
@isTest
public with sharing class OM_VID_OpportunityTRGTest {
    
    @isTest
    public static void testCreateQuoteFifty(){
        
        List<Opportunity> listOpps1 = OM_VID_TestUtils.createOpportunities(2);
        OM_VID_TestUtils.createOpportunityLineItems(listOpps1, 2, '');
        
        String recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = :OM_VID_Constants.oppName AND DeveloperName =: OM_VID_Constants.opportunityRTFifty LIMIT 1].Id;
        List<Opportunity> listOpps = [SELECT Id, Name, CloseDate FROM Opportunity WHERE RecordTypeId = :recordTypeId LIMIT 1];

        Test.startTest();
        for(Opportunity opp : listOpps){
            opp.StageName = OM_VID_Constants.opportunityStatusQuotation;
        }

        update listOpps;
        Test.stopTest();

        System.assertEquals(listOpps.size(), [SELECT Id FROM Quote].size());
        //System.assertEquals([SELECT Id FROM OpportunityLineItem].size(), [SELECT Id FROM QuoteLineItem].size());
        //System.assertEquals(listOpps[0].CloseDate, Date.today() + 30);
    }
    
    @isTest static void testOportunidadSinProductos() {
        List<Opportunity> opps = OM_VID_TestUtils.createOpportunities(1);
        Opportunity opp = opps[0];
        
         
        opp.StageName = 'Closed Won';

        Boolean threwError = false;
        try {
            update opp;
        } catch (DmlException e) {
            threwError = e.getMessage().contains('debes elegir algún producto como ganador');
        }

        System.assert(threwError, 'Debe lanzar error porque la oportunidad no tiene productos relacionados.');
    }

    @isTest
    public static void testOportunidadConUnProductoGanador() {
        List<Opportunity> opps = OM_VID_TestUtils.createOpportunities(1);
        Opportunity opp = opps[0];
        OM_VID_TestUtils.createOpportunityLineItems(new List<Opportunity>{opp}, 1, '');

        // Marcar el único producto como ganador
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id LIMIT 1];
        oli.OM_VID_ProductoGanador__c = true;
        update oli;
        

        opp.StageName = 'Closed Won';
        update opp;

        // Refrescar el producto para validar
        OpportunityLineItem oliCheck = [SELECT OM_VID_ProductoGanador__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id LIMIT 1];
        System.assert(oliCheck.OM_VID_ProductoGanador__c, 'El producto debe seguir marcado como ganador.');
    }

    @isTest static void testOportunidadConVariosProductosSinGanador() {
        List<Opportunity> opps = OM_VID_TestUtils.createOpportunities(1);
        Opportunity opp = opps[0];
        OM_VID_TestUtils.createOpportunityLineItems(new List<Opportunity>{opp}, 2, '');
		
        
        opp.StageName = 'Closed Won';

        Boolean threwError = false;
        try {
            update opp;
        } catch (DmlException e) {
            threwError = e.getMessage().contains('debes elegir algún producto como ganador');
        }
        System.assert(threwError, 'Debe lanzar error porque hay varios productos sin ganador marcado.');
    }
    

     @isTest
    static void testOportunidadConUnProductoSinGanador() {
        // Crear 1 oportunidad
        List<Opportunity> opps = OM_VID_TestUtils.createOpportunities(1);
        Opportunity opp1 = opps[0];
    
        // Crear 1 line item
        OM_VID_TestUtils.createOpportunityLineItems(new List<Opportunity>{opp1}, 1, '');
        
    
        // Cambiar StageName para activar trigger/logic
        opp1.StageName = 'Closed Won';
        update opp1; 
    
        // Consultar el line item relacionado
        OpportunityLineItem oli1 = [SELECT Id, OM_VID_ProductoGanador__c 
                                   FROM OpportunityLineItem 
                                   WHERE OpportunityId = :opp1.Id 
                                   LIMIT 1];
    
        // Comprobar que se marcó automáticamente como ganador
        System.assertEquals(true, oli1.OM_VID_ProductoGanador__c, 
            'El único producto de la oportunidad debería haberse marcado como ganador automáticamente.');
    }
}