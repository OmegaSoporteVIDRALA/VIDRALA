/**
* @description       :
* @author            : mmadridp@omegacrmconsulting.com
* @group             :
* @last modified on  : 11-03-2024
* @last modified by  : mmadridp@omegacrmconsulting.com
**/
public with sharing class OM_VID_OpportunityTRGHandler {
    
    private static final String CLASS_NAME = OM_VID_OpportunityTRGHandler.class.getName();
    private static final String OpportunityRTFiftyId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(OM_VID_Constants.opportunityRTFifty).getRecordTypeId();

    private static Boolean byPassApex = false;
    private static final String QUEUE_DEVNAME_FILTER = 'Vidrala_Europe_Sales_%';

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
                createTasksForSendingQuotes(news, oldsMap);
                createQuoteAndQuoteLineCotizacion(news, oldsMap);
                checkProductosGanadores(news, oldsMap);
            }
        }
    }
    
    /*
    *********************************************************
    @Method Name    : createTasksForSendingQuotes
    @author         : maria.lopez@omegacrmconsulting.com
    @description    : Creates follow-up tasks for opportunities that meet specific criteria, such as stage change to "Quotation" and matching record type.
					  Tasks are assigned to Account's Sales Office or predefined queues in Market field in Opportunity.
	@param          : List<Opportunity> newOpps - List of newly updated Opportunity records from the trigger.
	@param          : Map<Id, Opportunity> oldOppsMap - Map of old Opportunity records keyed by Id, used to detect changes.
	@return         : void
    ********************************************************
    */
    private static void createTasksForSendingQuotes(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppsMap){
        final String METHOD_NAME = 'createTasksForSendingQuotes';
        List<Task> tasksToInsert = new List<Task>();
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Start');
        if (newOpps.isEmpty()) {
            System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: No opportunities to process');
            return;
        }
        Map<String, Group> queueMap = getRelevantQueues();
        for (Opportunity opp : newOpps) {
            if (isToCreateTask(opp, oldOppsMap.get(opp.Id))){
                Task newTaskToInsert = constructNewTask(opp, queueMap);
                if(newTaskToInsert != null){
                    tasksToInsert.add(newTaskToInsert);
                }
            }
        }
        if (!tasksToInsert.isEmpty()) {
            try {
                insert tasksToInsert;
                System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Inserted ' + tasksToInsert.size() + ' tasks');
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: DML Error: ' + e.getMessage());
            }
        } else {
            System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: No tasks to insert');
        }
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: End');
    }
    
    /*
    *********************************************************
    @Method Name    : getRelevantQueues
    @author         : maria.lopez@omegacrmconsulting.com
    @description    : Retrieves and maps relevant queue groups by Name for task assignment.
	@return         : Map<String, Group> - Map of Group records keyed by Name.
    ********************************************************
    */
    private static Map<String, Group> getRelevantQueues() {
        final String METHOD_NAME = 'getRelevantQueues';
        Map<String, Group> queueMap = new Map<String, Group>();
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Start');
        for (Group groupItem : [
            SELECT Id, Name 
            FROM Group 
            WHERE Type = :OM_VID_Constants.groupTypeQueue 
            AND DeveloperName LIKE :QUEUE_DEVNAME_FILTER
            AND Name != null
        ]) {
            queueMap.put(groupItem.Name.toUpperCase(), groupItem);
        }
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: End');
        return queueMap;
    }
    
    /*
    *********************************************************
    @Method Name    : isToCreateTask
    @author         : maria.lopez@omegacrmconsulting.com
    @description    : Determines whether a task should be created based on stage change and record type.
	@param          : Opportunity newOpp - The updated opportunity record.
	@param          : Opportunity oldOpp - The previous opportunity record.
	@return         : Boolean - True if a task should be created, false otherwise.
    ********************************************************
    */
    private static Boolean isToCreateTask(Opportunity newOpp, Opportunity oldOpp){
        final String METHOD_NAME = 'isToCreateTask';
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Start');
        if (newOpp == null || oldOpp == null) {
            System.debug(LoggingLevel.WARN, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Null opportunity detected');
            return false;
        }
        Boolean result = newOpp?.RecordTypeId == OpportunityRTFiftyId && 
            oldOpp?.StageName != OM_VID_Constants.opportunityStatusQuotation &&
            newOpp?.StageName == OM_VID_Constants.opportunityStatusQuotation;
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Result: ' + result);
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: End');
		return result;
    }
    
    /*
    *********************************************************
    @Method Name    : constructNewTask
    @author         : maria.lopez@omegacrmconsulting.com
    @description    : Builds a new Task record for an Opportunity marked for quotation.
					  The task is assigned either to the Sales Office of the Account or to a queue based on the Market field.
	@param          : Opportunity newOpp - The updated opportunity record.
	@param          : Map<String, Group> queueMap - Map of available Group queues keyed by DeveloperName or Name.
    @return         : Task newTask - A configured Task ready for insertion.
    ********************************************************
    */
    private static Task constructNewTask(Opportunity newOpp, Map<String, Group> queueMap){
    	final String METHOD_NAME = 'constructNewTask';
        Task newTask = new Task();
    	System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Start');
        if (newOpp == null) {
            System.debug(LoggingLevel.WARN, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Opportunity is null');
            return null;
        }
        newTask.Subject = OM_VID_Constants.taskSubjectSendQuotation;
        newTask.WhatId = newOpp.Id;
        newTask.Status = OM_VID_Constants.taskStatusOpen;
        newTask.Priority = OM_VID_Constants.taskPriorityNormal;
        newTask.ActivityDate = System.today().addDays(1);
        if (newOpp.Account?.Sales_Office__c != null) {
            newTask.OwnerId = newOpp.Account.Sales_Office__c;
        } else if (newOpp.Market__c != null && String.isNotBlank(newOpp.Market__c)) {
            for (Group queue : queueMap.values()) {
                if (queue?.Name?.toUpperCase().contains(newOpp.Market__c.toUpperCase())) {
                    newTask.OwnerId = queue.Id;
                    break;
                }
            }
        } else {
            System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: No user/queue found to assign this task.');
            return null;
        }
		System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: End');
    	return newTask;
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