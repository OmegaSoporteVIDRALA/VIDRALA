public class OM_VID_QuoteTRGHandlerMethods {

    private static final String CLASS_NAME = OM_VID_QuoteTRGHandlerMethods.class.getName();
    private static final String OpportunityRTFiftyId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(OM_VID_Constants.opportunityRTFifty).getRecordTypeId();
    private static final String QuoteRTFiftyId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(OM_VID_Constants.quoteRTFifty).getRecordTypeId();

    public static void quoteFieldsTranslation(List<Quote> newQuotes) {
        
        OM_Utils.FieldTranslations translations = new OM_Utils.FieldTranslations();
        translations.getTranslationMap(); 

        List<Quote> quotesUpdate = new List<Quote>();

        for(Quote q : newQuotes) {

            if(q.RecordTypeId == QuoteRTFiftyId) { 

                Quote qUpdate = new Quote(Id = q.Id); 

                
                if(q.OM_VID_Idioma__c != null && q.OM_VID_PaymentMethod__c != null ) {
                    String paymentMethodTranslated = translations.getTranslation(
                        'Account',
                        'OM_VID_PaymentMethods__c',
                        q.OM_VID_PaymentMethod__c,
                        q.OM_VID_Idioma__c
                    );
                    
                    qUpdate.OM_VID_OpportunityPaymentMethods__c = paymentMethodTranslated != null ? paymentMethodTranslated : '';
                }

                
                if(q.OM_VID_Idioma__c != null && q.OM_VID_AgreedTerms__c != null) {
                    String agreedTermsTranslated = translations.getTranslation(
                        'Account',
                        'OM_VID_AgreedTerms__c',
                        q.OM_VID_AgreedTerms__c,
                        q.OM_VID_Idioma__c
                    );
                    
                    qUpdate.OM_VID_OpportunityAgreedTerms__c = agreedTermsTranslated != null ? agreedTermsTranslated : '';
                }

                quotesUpdate.add(qUpdate);
            }
        }

        if(!quotesUpdate.isEmpty()){
            OM_Utils.shouldSkipTriggerGlobal = true;
            update quotesUpdate;
        }
    }

    /*
    *********************************************************
    @Method Name    : createTasksForSendingQuotes
    @author         : soporte.vidrala@omegacrmconsulting.com
    @description    : Creates follow-up tasks for opportunities that meet specific criteria, such as stage change to "Quotation" and matching record type.
					  Tasks are assigned to Account's Sales Office or predefined queues in Market field in Opportunity.
    ********************************************************
    */
    public static void createTasksForSendingQuotes(List<Quote> listNewQuotes){
        final String METHOD_NAME = 'createTasksForSendingQuotes';
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Start');
        
        Map<Id, Quote> mapIdQuote = getMapIdQuoteInfo(listNewQuotes);
        Map<String, Group> queueMap = getRelevantQueues();
        List<Task> tasksToInsert = getTasksToInsert(listNewQuotes, mapIdQuote, queueMap);
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
    @Method Name    : getMapIdQuoteInfo
    @author         : soporte.vidrala@omegacrmconsulting.com
    @description    : Retrieves information about the related Opportunity and Account
    ********************************************************
    */
    private static Map<Id, Quote> getMapIdQuoteInfo (List<Quote> listNewQuotes) {
        final String METHOD_NAME = 'getMapIdQuoteInfo';
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Start');
        List<Id> listIdQuotesToProcess = new List<Id>();
        for(Quote quo : listNewQuotes) {
            if (quo.RecordTypeId == QuoteRTFiftyId){
                listIdQuotesToProcess.add(quo.Id);
            }
        }
        Map<Id, Quote> mapIdQuote = new Map<Id, Quote>([
            SELECT Id, Opportunity.Market__c, Opportunity.StageName, Opportunity.Account.Sales_Office__c 
            FROM Quote 
            WHERE Id IN :listIdQuotesToProcess AND Quote.Opportunity.StageName = :OM_VID_Constants.opportunityStatusQuotation
        ]);
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: End');
        return mapIdQuote;
    }
    /*
    *********************************************************
    @Method Name    : getRelevantQueues
    @author         : soporte.vidrala@omegacrmconsulting.com
    @description    : Retrieves and maps relevant queue groups by Name for task assignment.
    ********************************************************
    */
    private static Map<String, Group> getRelevantQueues() {
        final String METHOD_NAME = 'getRelevantQueues';
        final String QUEUE_DEVNAME_FILTER = 'Vidrala_Europe_Sales_%';
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
    @Method Name    : getTasksToInsert
    @author         : soporte.vidrala@omegacrmconsulting.com
    @description    : Creates tasks to insert afterwards.
    ********************************************************
    */
    private static List<Task> getTasksToInsert (List<Quote> listNewQuotes, Map<Id, Quote> mapIdQuote, Map<String, Group> queueMap) {
        final String METHOD_NAME = 'getTasksToInsert';
        List<Task> tasksToInsert = new List<Task>();
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Start');
        for (Quote quo : listNewQuotes) {
            if (isToCreateTask(quo, mapIdQuote)){
                Task newTaskToInsert = constructNewTask(quo, mapIdQuote, queueMap);
                if(newTaskToInsert != null){
                    tasksToInsert.add(newTaskToInsert);
                }
            }
        }
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: End');
        return tasksToInsert;
    }
    /*
    *********************************************************
    @Method Name    : isToCreateTask
    @author         : soporte.vidrala@omegacrmconsulting.com
    @description    : Determines whether a task should be created based on opportunity stage and record type.
    ********************************************************
    */
    private static Boolean isToCreateTask(Quote newQuote, Map<Id, Quote> mapIdQuoteInput){
        final String METHOD_NAME = 'isToCreateTask';
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Start');
        Boolean result = newQuote?.RecordTypeId == QuoteRTFiftyId && 
            mapIdQuoteInput?.get(newQuote.Id)?.Opportunity?.StageName == OM_VID_Constants.opportunityStatusQuotation;
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Result: ' + result);
        System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: End');
		return result;
    }
    /*
    *********************************************************
    @Method Name    : constructNewTask
    @author         : soporte.vidrala@omegacrmconsulting.com
    @description    : Builds a new Task record for an Opportunity marked for quotation.
					  The task is assigned either to the Sales Office of the Account or to a queue based on the Market field.
    ********************************************************
    */
    private static Task constructNewTask(Quote newQuote, Map<Id, Quote> mapIdQuote, Map<String, Group> queueMap){
    	final String METHOD_NAME = 'constructNewTask';
        Task newTask = new Task();
    	System.debug(LoggingLevel.INFO, CLASS_NAME + ' :: ' + METHOD_NAME + ' :: Start');
        newTask.Subject = OM_VID_Constants.taskSubjectSendQuotation;
        newTask.WhatId = newQuote.OpportunityId;
        newTask.Status = OM_VID_Constants.taskStatusOpen;
        newTask.Priority = OM_VID_Constants.taskPriorityNormal;
        newTask.ActivityDate = System.today().addDays(1);
        String marketStr = mapIdQuote?.get(newQuote.Id)?.Opportunity?.Market__c;
        if (marketStr != null && String.isNotBlank(marketStr)) {
            for (Group queue : queueMap.values()) {
                if (queue?.Name?.toUpperCase().contains(marketStr.toUpperCase())) {
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
}