/**
* @description       :
* @author            : mmadridp@omegacrmconsulting.com
* @group             :
* @last modified on  : 11-03-2024
* @last modified by  : mmadridp@omegacrmconsulting.com
**/
public with sharing class OM_VID_OpportunityTRGHandler {
    private static final String OpportunityRTFiftyId = [SELECT Id FROM RecordType WHERE SObjectType = :OM_VID_Constants.oppName AND DeveloperName = :OM_VID_Constants.opportunityRTFifty LIMIT 1].Id;

    private static Boolean byPassApex = false;

	public static void setbyPassApex(Boolean skip){
		byPassApex = skip;        
	}

	public static Boolean getbyPassApex(){
		return byPassApex;     
        
        
	}

    public static void execute(
        List<Opportunity> news,
        Map<Id, Opportunity> oldsMap,
        Boolean isBefore,
        Boolean isAfter,
        Boolean isInsert,
        Boolean isUpdate,
        Boolean isDelete
    ) {
        if (byPassApex) {
            return;
        }
        if (isBefore) {
            if (isInsert) {
            
            }

            if(isUpdate){
                updateOppCloseDate(news, oldsMap);
            }
        }

        if (isAfter) {
            if (isInsert) {
            
            }

            if(isUpdate){
                createQuoteAndQuoteLineCotizacion(news, oldsMap);
                checkProductosGanadores(news, oldsMap);
            }
        }
    }

    public static void updateOppCloseDate(List<Opportunity> news, Map<Id, Opportunity> oldsMap){

        for(Opportunity opp : news){
            //ejecutar lógica solo si cambia el estado a Quotation y si es una OPP de fifty
            if((opp.StageName != oldsMap.get(opp.Id).StageName) && opp.StageName == OM_VID_Constants.opportunityStatusQuotation && opp.RecordTypeId == OpportunityRTFiftyId){
                opp.CloseDate = Date.today() + 30;
            }
        }
    }

    public static void createQuoteAndQuoteLineCotizacion(List<Opportunity> news, Map<Id, Opportunity> oldsMap){
        Set<Id> setOppIds = new Set<Id>();
        List<Quote> quoteToInsert = new List<Quote>();
        Map<Id, QuoteLineItem> mapQLine = new Map<Id, QuoteLineItem>();

        for(Opportunity opp : news){
            //ejecutar lógica solo si cambia el estado a Quotation y si es una OPP de fifty
            if((opp.StageName != oldsMap.get(opp.Id).StageName) && opp.StageName == OM_VID_Constants.opportunityStatusQuotation && opp.RecordTypeId == OpportunityRTFiftyId){
                setOppIds.add(opp.Id);
            }
        }

        if(!setOppIds.isEmpty()){
            String recordTypeId = [SELECT Id from RecordType where SobjectType = :OM_VID_Constants.quoteName and DeveloperName = :OM_VID_Constants.quoteRTFifty].Id;
            //rellenamos una lista de las Quote a insertar
            quoteToInsert.addAll(createQuoteCotizacion(news, recordTypeId));
            
            if(!quoteToInsert.isEmpty()){
                insert quoteToInsert;
            }

            //traer las OppLineItem asociadas a las opp modificadas
            List<OpportunityLineItem > oppLineList = [SELECT ID, Quantity, PricebookEntryId, Product2Id, UnitPrice, Description, TotalPrice, OpportunityId, Price_Includes_Delivery__c, Pallet_Volume__c FROM OpportunityLineItem WHERE OpportunityId IN :setOppIds];
            Map<Id, List<OpportunityLineItem>> mapOppLineItems = new Map<Id, List<OpportunityLineItem>>();

            /*
                rellenar un mapa con Id de Opp y lista de las OppLineItem asociadas a esa Opp para poder crear las QuoteLine
                ya que por cada n Opp se crearan n Quotes, y cada Opp puede tener n OppLineItem, que se traducirá a n QuoteLine
                por ejemplo si se actualizan 2 Opps cada una con 2 OppLine, crear 2 Quotes con 2 QLine cada una
            */
            for(OpportunityLineItem oppLineItem : oppLineList){

                // Check whether the value for that key exists
                if (!mapOppLineItems.containsKey(oppLineItem.OpportunityId) || mapOppLineItems.get(oppLineItem.OpportunityId) == null)
                {
                    // instantiate a new list
                    mapOppLineItems.put(oppLineItem.OpportunityId, new List <OpportunityLineItem> ());
                }

                // add the element to the list
                mapOppLineItems.get(oppLineItem.OpportunityId).add(oppLineItem);
            }

            //recuperamos el Id de las Quote insertadas (revisar si es realmente necesaria esta query)
            List<Quote> quoteInsertedList = [SELECT ID, OpportunityId FROM Quote WHERE OpportunityId IN :setOppIds];
            //rellenamos una lista de las QuoteLine con las OppLine relacionadas a cada Opp y las relacionamos a la nueva Quote creada para esa Opp
            mapQLine = createQuoteLineItems(quoteInsertedList, mapOppLineItems);

            if(mapQLine != null){
                insert mapQLine.values();
            }
        }
    }

    private static List<Quote> createQuoteCotizacion(List<Opportunity> oppList, String recordTypeId){
        List<Quote> returnedQuotes = new List<Quote>();
        for(Opportunity opp : oppList){
            Quote q = new Quote();
            //recupero cuantas quotes tiene cada Opp?
            q.Name = opp.Name + '_v' + String.valueOf(opp.OM_VID_NumQuotes__c + 1);
            q.OpportunityId = opp.Id;
            q.recordTypeId = recordTypeId;
            q.ExpirationDate = Date.today() + 30;
            q.OM_VID_DetallesAdicionales__c = opp.Description;
            q.ContactId = opp.Contact__c;
            //rellenar campos
            returnedQuotes.add(q);
        }
        
        return returnedQuotes;        
    }


    private static Map<Id,QuoteLineItem> createQuoteLineItems(List<Quote> listQuotes, Map<Id, List<OpportunityLineItem>> mapOppLineItems){
        Map<Id,QuoteLineItem> returnQuoteLines = new Map<Id, QuoteLineItem>();
        for(Quote q : listQuotes){
            if(mapOppLineItems.get(q.OpportunityId) != null){
                for(OpportunityLineItem oppLine : mapOppLineItems.get(q.OpportunityId)){
                    QuoteLineItem qLine = new QuoteLineItem();
                    qLine.OpportunityLineItemId = oppLine.Id;
                    qLine.QuoteId = q.Id;
                    qLine.Quantity = oppLine.Quantity;
                    qLine.PricebookEntryId = oppLine.PricebookEntryId;
                    qLine.Product2Id = oppLine.Product2Id;
                    qLine.UnitPrice = oppLine.UnitPrice;
                    qLine.Description = oppLine.Description;
                    qLine.OM_VID_Incoterms__c = oppLine.Price_Includes_Delivery__c;
                    qLine.OM_VID_Pallet_Volume__c = oppLine.Pallet_Volume__c;
                    
                    //¿rellenar más campos?
                    returnQuoteLines.put(qLine.OpportunityLineItemId, qLine);
                }
            }  
        }

        return returnQuoteLines;
    }
    
    public static void checkProductosGanadores(List<Opportunity> updatedOpps, Map<Id, Opportunity> oldOppsMap) {
        List<OpportunityLineItem> toUpdate = new List<OpportunityLineItem>();
        
        List<Opportunity> oppsToCheck = new List<Opportunity>();
        for (Opportunity opp : updatedOpps) {
            Opportunity oldOpp = oldOppsMap.get(opp.Id);
            if (
                opp.StageName == 'Closed Won' &&
                oldOpp.StageName != 'Closed Won' &&
                opp.RecordTypeId == OpportunityRTFiftyId
            ) {
                oppsToCheck.add(opp);
            }
        }
        
        if (oppsToCheck.isEmpty()) return;
        
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : oppsToCheck) {
            oppIds.add(opp.Id);
        }
        
        List<OpportunityLineItem> allLineItems = [
            SELECT Id, OM_VID_ProductoGanador__c, OpportunityId
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ];
        
        Map<Id, List<OpportunityLineItem>> oppLineMap = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : allLineItems) {
            if (!oppLineMap.containsKey(oli.OpportunityId)) {
                oppLineMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            oppLineMap.get(oli.OpportunityId).add(oli);
        }
        
        for (Opportunity opp : oppsToCheck) {
            List<OpportunityLineItem> prods = oppLineMap.get(opp.Id);
            Integer prodGanadores = 0;
            
            if (prods != null) {
                for (OpportunityLineItem oli : prods) {
                    if (oli.OM_VID_ProductoGanador__c == true) {
                        prodGanadores++;
                    }
                }
            }
            
            if (prodGanadores == 0) {
                if (prods == null || prods.isEmpty() || prods.size() > 1) {
                    opp.addError('Para cerrar la oportunidad como ganadora, debes elegir algún producto como ganador en la oportunidad.');
                } else {
                    OpportunityLineItem prod = prods[0];
                    prod.OM_VID_ProductoGanador__c = true;
                    toUpdate.add(prod);
                }
            }
         }
        
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}