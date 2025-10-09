/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchLoadBatch.cls
   Description: Batch job to upsert records from the Dispatch Staging object to the Dispatch object
                (This batch class processes records from the Dispatch_Staging__c object, updating their status and sending notifications.)

   Date         Version Author              Summary of Changes
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Nov 2017     1.0     M.Witchalls(Ciber)  Initial Release
   May 2018     2.0     M.Witchalls         SAP Version
   Sep 2024     3.0     Globant             Refactor
   Aug 2025		4.0		Globant				New fields Addition and Refactored Upsert logic for dispatch records
   Oct 2025		5.0		Globant				New fields addition for dispatch records - Case 00067826
------------------------------------------------------------------------------------------------------------------------ */
global class DispatchLoadBatch implements Database.Batchable<sObject>, Database.Stateful { 
    
    // Constants 
    private static final String SYSTEM_ADMIN_GROUP = 'System_admin_group';
    private static final String DC_RECIPIENT_GROUP = 'DC_Recipients';
    private static final String OTIF_RECIPIENT_GROUP = 'OTIF_Email_Recipients';
    private static final String DC_EMAIL_TEMPLATE_NAME = 'Daily_Comparatives';
    private static final String OTIF_EMAIL_TEMPLATE_NAME = 'Daily_OTIF';
    private static final Set<String> EXCLUDE_FROM_OTIF_SET = new Set<String>{'0', '11529'};
    
    private static final String NEW_STATUS = 'New';
    private static final String SUCCESS_STATUS = 'Success';
    private static final String ERROR_STATUS = 'Error';
    private static final String WARNING_STATUS = 'Warning';
    
    private static final Integer EMAIL_NOTIFICATION_DELAY_SECONDS = 3600;

    // Dispatch context
    private DispatchContext context;
    
    // Async Apex Job Id
    global String jobId;

    /** 
     * Starts the batch process by querying records from Dispatch_Staging__c based on status.
     * 
     * @param dbc The context of the batchable job.
     * @return    A QueryLocator that defines the records to be processed.
     */
    global Database.QueryLocator start(Database.BatchableContext dbc) { 
        
        setJobId(dbc); 
        return queryDispatchStagingRecords(); 
    }

    /** 
     * Processes each batch of Dispatch_Staging__c records.
     * 
     * @param dbc              The context for the batchable job.
     * @param dispatchLoadList The list of Dispatch_Staging__c records to process.
     */
    global void execute(Database.BatchableContext dbc, List<Dispatch_Staging__c> dispatchLoadList) { 
        
        // Null check and list should not empty
        if (dispatchLoadList == null || dispatchLoadList.isEmpty()) {

            return;
        }

        // Declare and initialize variable and process records
        context = new DispatchContext(dispatchLoadList, jobId);

        // Create Dispatch records from Dispatch Staging records
        for (Dispatch_Staging__c dl: dispatchLoadList) {

            prepareDispatchRecord(dl, context);
        }

        // Upsert records
        upsertRecords(context);
    }

    /** 
     * Handles the finish of the batch process.
     * 
     * @param dbc The context for the batchable job.
     */
    global void finish(Database.BatchableContext dbc) {

        if (jobId != null && context != null) {
        
            Map<String, ID> groupMap = getGroupMap(); 
            List<GroupMember> adminUserList = getGroupMembers(groupMap.get(SYSTEM_ADMIN_GROUP));
            List<GroupMember> dcList = getGroupMembers(groupMap.get(DC_RECIPIENT_GROUP)); 
            List<GroupMember> otifList = getGroupMembers(groupMap.get(OTIF_RECIPIENT_GROUP));
            
            if (!adminUserList.isEmpty()) { 
        
                sendErrorMessages(adminUserList, dcList, otifList); 
            } 
        
            if (!dcList.isEmpty()) { 
        
                scheduleEmailSending(dcList, DC_EMAIL_TEMPLATE_NAME, 'DCEmailSend', System.now().addSeconds(60)); 
            } 
        
            if (!otifList.isEmpty()) { 
        
                scheduleEmailSending(otifList, OTIF_EMAIL_TEMPLATE_NAME, 'OTIFEmailSend', System.now()); 
            }
        }
    }

    /** 
     * Sets the job ID if it is not already set.
     * 
     * @param dbc The context of the batchable job.
     */
    private void setJobId(Database.BatchableContext dbc) { 
        
        if (jobId == null) { 
            
            jobId = dbc.getJobId();
        }
    }

    /** 
     * Queries the Dispatch_Staging__c records that need to be processed.
     * 
     * @return A QueryLocator object for fetching the records.
     */
    private Database.QueryLocator queryDispatchStagingRecords() { 
        
        return Database.getQueryLocator([ 
            SELECT Id, Dispatch_ID__c, Unique_ID__c, Dispatch_Date__c, Month__c, Week__c, Week_in_Month__c, Calendar_Month__c, Year__c,
                   Forecast__c, Forecast_SAP__c, Dispatch_Time__c, Delivery_Name__c, Delivery_Code__c, Type__c,
                   Customer_Name__c, Encirc_Account_Number__c, Haulier_Code__c, Haulier_Name__c,
                   Planned_Delivery_Date__c, Planned_Delivery_Time__c, Site_ID__c, Warehouse_ID__c, Freight_Reference__c,
                   Bottle_Identifier__c, Bottle_Description__c, SAP_Model_Number__c, SAP_Material_Code__c,
                   Pack_Specification__c, Units__c, Tonnage__c, Weight_per_Unit__c, Process_Job__c, Process_Status__c,
                   Process_Error__c, Process_Date__c,  Store__c, Customer_Code__c, Item__c, Shipment_Number__c, Record_Creation_Date__c,
    			   Entry_Time__c, Plate_Number__c, Trailer_Plate_Number__c, Overall_Transportation_Status__c, End_of_Planning_Date__c,
 				   Scheduling_End_Time__c, Planned_Date_of_Check_In__c,	Planned_Check_In_Time__c, Actual_Date_of_Check_In__c,
    			   Current_Time_of_Check_In__c, Planned_Date_for_Start_of_Loading__c, Planned_Loading_Start_Time__c,
    			   Current_Date_for_Start_of_Loading__c, Actual_Loading_Start_Time__c,Planned_Date_for_End_of_Loading__c,
    			   Planned_Loading_End_Time__c, Actual_Date_for_End_of_Loading__c, Actual_Loading_End_Time__c,
    			   Planned_Date_for_Shipment_Completion__c, Planned_Time_for_Processing__c, Current_Date_of_Shipment_Completion__c,
    			   Time_of_Transportation_Processing__c, Planned_Date_for_Start_of_Shipment__c, Planned_Transport_Start_Time__c,
    			   Current_Date_for_Start_of_Shipment__c, Actual_Transport_Start_Time__c, Planned_Date_for_End_of_Shipment__c,
    			   Planned_Transport_End_Time__c, Actual_Date_for_End_of_Shipment__c, Actual_Shipment_End_Time__c, Purchasing_Document_Number__c,
    			   Sales_Document__c, Number_of_Material_Document__c, Material_Document_Year__c, Batch_Number__c, Series__c, Salesforce_Unique_ID__c
            FROM Dispatch_Staging__c
            WHERE Dispatch_ID__c != null AND Process_Status__c IN (:NEW_STATUS, :ERROR_STATUS)
            ORDER BY Dispatch_Date__c, Name
        ]);
    }

    /** 
     * Retrieves the group map with IDs for system admin, DC recipient, and OTIF recipient groups.
     * 
     * @return Map<String, ID> A map of group developer names to group IDs.
     */
    private Map<String, ID> getGroupMap() { 
        
        Map<String, ID> groupMap = new Map<String, ID>(); 
        
        for (Group g : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN (:SYSTEM_ADMIN_GROUP, :DC_RECIPIENT_GROUP, :OTIF_RECIPIENT_GROUP)]) { 
            
            groupMap.put(g.DeveloperName, g.Id); 
        } 

        return groupMap; 
    }

    /** 
     * Retrieves group members for a given group ID.
     * 
     * @param  groupId            The ID of the group to retrieve members from.
     * @return List<GroupMember>  A list of group members.
     */
    private List<GroupMember> getGroupMembers(ID groupId) { 
        
        if (groupId != null) { 
            
            return [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :groupId]; 
        } 

        return new List<GroupMember>(); 
    }

    /** 
     * Sends error messages to system administrators.
     * 
     * @param adminUserList List of group members who are system administrators.
     */
    private void sendErrorMessages(List<GroupMember> adminUserList, List<GroupMember> dcList, List<GroupMember> otifList) { 
        
        List<Dispatch_Staging__c> errorList = new List<Dispatch_Staging__c>(); 
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id = :jobId]; 
        
        if (context.errorWarningCount > 0) { 
        
            errorList = [SELECT Id, Dispatch_ID__c, Unique_ID__c, Dispatch_Date__c, Customer_Name__c, Encirc_Account_Number__c, Process_Status__c, Process_Error__c, Process_Date__c FROM Dispatch_Staging__c WHERE Process_Job__c = :jobId AND Process_Status__c != :SUCCESS_STATUS LIMIT 500];
        } 
        
        String emailBody = generateEmailBody(job, errorList, dcList, otifList);
        
        sendEmails(adminUserList, emailBody, 'Dispatch Batch Run ' + jobId + ' ' + System.now()); 
    }

    /**
     * Generates the body of the error email.
     * 
     * @param job        The AsyncApexJob object containing job details.
     * @param errorList  List of errors to include in the email.
     * @return           String The generated email body.
     */
    private String generateEmailBody(AsyncApexJob job, List<Dispatch_Staging__c> errorList, List<GroupMember> dcList, List<GroupMember> otifList) {
        
        String emailBody;
        
        if (job.NumberOfErrors == 0 && context.errorWarningCount == 0) {
        
            emailBody = 'Dispatch Batch Run completed successfully at ' + System.now() + '\n';
        } else {
        
            emailBody = 'Dispatch Batch Run finished with Warnings/Errors at ' + System.now() + '\n';
            
            for (Dispatch_Staging__c de : errorList) {
                
                emailBody += '\n' + de.Unique_ID__c + ': Customer ' + de.Encirc_Account_Number__c + ' ' + de.Process_Status__c + ': ' + de.Process_Error__c;
            }

            if (errorList.size() > 200) {
             
                emailBody += '\n...';
            }
        }

        emailBody += '\n-----------------------------------------------------------------------------------------------------------\n';
        emailBody += 'Daily Comparative Email Count: ' + dcList.size() + '\n';
        emailBody += 'OTIF Email Count: ' + otifList.size() + '\n';
        
        return emailBody;
    }

    /**
     * Sends an email to a list of users.
     * 
     * @param userList      List of users to send the email to.
     * @param emailBody     The body of the email.
     * @param emailSubject  The subject of the email.
     */
    private void sendEmails(List<GroupMember> userList, String emailBody, String emailSubject) { 
        
        Integer numberOfEmails = 0; 
        
        for (GroupMember recipient : userList) { 
            
            if (recipient.UserOrGroupId.getSObjectType() == User.SObjectType) { 
                
                numberOfEmails++; 
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
                mail.setTargetObjectId(recipient.UserOrGroupId); 
                mail.setSaveAsActivity(false); 
                mail.setSubject(emailSubject); 
                mail.setPlainTextBody(emailBody); 
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail}); 
            } 

            if (numberOfEmails == 10) {
                
                break;
            } 
        } 
    }

    /** 
     * Schedules email sending jobs.
     * 
     * @param userList       List of users to send the email to.
     * @param templateName   The name of the email template.
     * @param jobNamePrefix  The prefix for the scheduled job name.
     */
    private void scheduleEmailSending(List<GroupMember> userList, String templateName, String jobNamePrefix, Datetime dt) { 
        
        List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateName]; 
        ID emailTemplateId = (templateList.size() > 0) ? templateList[0].Id : null;
        
        if (emailTemplateId != null) { 

            List<ID> userIdList = new List<ID>(); 
            Boolean emailSendFlag = true;

            if (jobNamePrefix == 'OTIFEmailSend') {

                Date dateSch = dt.date();
                
                //Calculate index of current day of the week
                Date weekStart = dateSch.toStartofWeek();
                Integer indexDay = weekStart.daysBetween(dateSch);
                
                //Add the delay in seconds after the DispatchLoadBatch executed
                dt = dt.addSeconds(EMAIL_NOTIFICATION_DELAY_SECONDS);

                emailSendFlag = (indexDay < 5);
            }

            for (GroupMember recipient : userList) { 

                if (recipient.UserOrGroupId.getSObjectType() == User.SObjectType) { 
                    
                    userIdList.add(recipient.UserOrGroupId); 
                } 
            }

            if (!userIdList.isEmpty()) { 

                //Datetime dt = System.now().addSeconds(60); 
                List<String> parts = new List<String>{
                    String.valueOf(dt.second()), 
                    String.valueOf(dt.minute()), 
                    String.valueOf(dt.hour()), 
                    String.valueOf(dt.day()), 
                    String.valueOf(dt.month()), 
                    '?', 
                    String.valueOf(dt.year())
                };
                
                String cronExp = String.join(parts, ' ');                
                String strJobName = jobNamePrefix + '-' + dt.year() + '-' + dt.month() + '-' + dt.day() + '-' + dt.hour() + '-' + dt.minute(); 
                EmailSendSchedulable emailJob = new EmailSendSchedulable(emailTemplateId, userIdList);
                
                if (!Test.isRunningTest() && emailSendFlag) { 

                    system.schedule(strJobName, cronExp, emailJob); 
                }
            } 
        } 
    }

    /** 
     * Processes/prepare each dispatch record.
     * 
     * @param dl       The Dispatch Staging to process.
     * @param context  The context of the dispatch context.
     */
    private void prepareDispatchRecord(Dispatch_Staging__c dl, DispatchContext context) {

        // M.Witchalls May 2018
        String bottleIdentifier = dl.Bottle_Identifier__c;

        if (dl.Bottle_Identifier__c == null && dl.SAP_Model_Number__c != null) {
            
            bottleIdentifier = dl.SAP_Model_Number__c;
        }

        Account acct = new Account(SAP_Account_Number__c = dl.Encirc_Account_Number__c);
        Account SAPacct = new Account(SAP_Account_Number__c = dl.Encirc_Account_Number__c); // M.Witchalls May 2018

        Month__c mth = new Month__c(Unique_ID__c = context.monthKeyMap.get(dl.Month__c));
        Bottle__c prod = new Bottle__c(Bottle_Identifier__c = bottleIdentifier);
        SAP_Material_Code__c material;

        if (dl.SAP_Material_Code__c != null) {

            material = new SAP_Material_Code__c(Material_Code_Key__c = dl.SAP_Material_Code__c);
        }

        //Forecast__c fcast = new Forecast__c(Unique_ID__c = dl.Forecast__c);
        Haulier__c haulier = new Haulier__c(Haulier_Code__c = dl.Haulier_Code__c);

        if (bottleIdentifier != null) {

            createBottle(dl, context, bottleIdentifier);
        }

        // M.Witchalls May 2018
        if (dl.SAP_Material_Code__c != null && !context.materialExistsSet.contains(dl.SAP_Material_Code__c)) {
            
            createSAPMaterialCode(dl, context);
        }

        if (dl.Haulier_Code__c != null && !context.haulierExistsSet.contains(dl.Haulier_Code__c)) {
            
            createHaulier(dl, context);
        }

        createDispatchRecord(dl, context, acct, SAPacct, mth, prod, material, haulier);
    }

    /** 
     * To create dispatch record.
     * 
     * @param dl       The Dispatch Staging to process.
     * @param context  The context of the dispatch context.
     */
    private void createHaulier(Dispatch_Staging__c dl, DispatchContext context) {

        if (dl.Haulier_Name__c == null) {
                
            dl.Haulier_Name__c = 'Haulier ' + dl.Haulier_Code__c;
        }

        Boolean excludeFromOTIF = (EXCLUDE_FROM_OTIF_SET.contains(dl.Haulier_Code__c)) ? true : false;
        
        context.haulierInsertMap.put(
            dl.Haulier_Code__c,
            new Haulier__c(
                Name = dl.Haulier_Name__c,
                Haulier_Code__c = dl.Haulier_Code__c,
                Exclude_from_OTIF__c = excludeFromOTIF
            )
        );
    }

    /** 
     * To create dispatch record.
     * 
     * @param dl       The Dispatch Staging to process.
     * @param context  The context of the dispatch context.
     */
    private void createSAPMaterialCode(Dispatch_Staging__c dl, DispatchContext context) {
        
        SAP_Material_Code__c newRecord = new SAP_Material_Code__c(
            Name = dl.SAP_Material_Code__c,
            Material_Code_Key__c = dl.SAP_Material_Code__c,
            Bottle_Identifier__c = dl.Bottle_Identifier__c,
            Pack_Spec__c = dl.Pack_Specification__c
        );

        if (dl.SAP_Model_Number__c != null) {

            newRecord.Bottle__r = new Bottle__c(SAP_Model_Number__c = dl.SAP_Model_Number__c);
        } else if (dl.Bottle_Identifier__c != null) {
            
            newRecord.Bottle__r = new Bottle__c(Bottle_Identifier__c = dl.Bottle_Identifier__c);
        }

        context.materialUpsertMap.put(dl.SAP_Material_Code__c, newRecord);
    }

    /** 
     * To create dispatch record.
     * 
     * @param dl                The Dispatch Staging to process.
     * @param context           The context of the dispatch context.
     * @param bottleIdentifier  The bottleIdentifier for the bottle.
     */
    private void createBottle(Dispatch_Staging__c dl, DispatchContext context, String bottleIdentifier) {
        
        if (!context.prodExistsSet.contains(bottleIdentifier)) {

            if (dl.Bottle_Description__c == null) {
                
                dl.Bottle_Description__c = 'Bottle ' + bottleIdentifier;
            }

            context.prodUpsertMap.put(
                bottleIdentifier,
                new Bottle__c(
                    Name = dl.Bottle_Description__c,
                    Bottle_Identifier__c = bottleIdentifier,
                    SAP_Model_Number__c = dl.SAP_Model_Number__c,
                    SAP_Material_Code__c = dl.SAP_Material_Code__c,
                    Weight_per_Unit__c = dl.Weight_per_Unit__c
                )
            );
        }
    }

    /** 
     * To create dispatch record.
     * 
     * @param dl      The Dispatch Staging to process.
     * @param context The context of the dispatch context.
     */
    private void createDispatchRecord(Dispatch_Staging__c dl, DispatchContext context, 
                                    Account acct, Account SAPacct, Month__c mth, Bottle__c prod, 
                                    SAP_Material_Code__c material, Haulier__c haulier) {

        // M.Witchalls May 2018
        Boolean abortRecord = false;

        if (!context.accountExistsSet.contains(dl.Encirc_Account_Number__c)) {

            acct = SAPacct;

            // M.Witchalls May 2018
            if (!context.SAPaccountExistsMap.keySet().contains(dl.Encirc_Account_Number__c)) {
                abortRecord = true;
                // Missing Account is a fatal error
                dl.Process_Status__c = ERROR_STATUS;
                dl.Process_Error__c += 'Missing Account for Encirc/SAP Account Number '+ dl.Encirc_Account_Number__c + '\n';
                context.errorWarningCount++;
                System.debug('Process Status '+dl.Process_Status__c);
         		System.debug('Process Error '+dl.Process_Error__c);

            }
        }

        if (!abortRecord) {

            String monthKey = context.monthKeyMap.get(dl.Month__c);

            if (monthKey != null && !context.monthExistsSet.contains(monthKey)) {

                context.monthUpsertMap.put(
                    monthKey,
                    new Month__c(
                        Customer__r = acct,
                        Name = dl.Calendar_Month__c,
                        Calendar_Month__c = dl.Calendar_Month__c,
                        Year__c = dl.Year__c,
                        Unique_ID__c = monthKey
                    )
                );

                dl.Process_Status__c = WARNING_STATUS;
                dl.Process_Error__c += 'Missing Month record '+ monthKey + ';\n';
                context.errorWarningCount++;
            }

            Forecast__c fcast;

            String forecastKey = context.forecastKeyMap.get(dl.Forecast__c);
            String SAPforecastKey = context.forecastKeyMap.get(dl.Forecast_SAP__c);

            if (dl.Forecast_SAP__c != null && context.forecastSAPExistsSet.contains(SAPforecastKey)) {
                
                fcast = new Forecast__c(Unique_ID__c = SAPforecastKey);
            } else if (dl.Forecast__c != null && context.forecastExistsSet.contains(forecastKey)) {
                
                fcast = new Forecast__c(Unique_ID__c = forecastKey);
            } else if (dl.Forecast_SAP__c != null) {
                
                fcast = new Forecast__c(Unique_ID__c = SAPforecastKey);
                context.forecastUpsertMap.put(
                    SAPforecastKey,
                    new Forecast__c(
                        Month__r = mth,
                        Product__r = prod,
                        SAP_Material_Code__r = material,
                        Name = dl.Bottle_Identifier__c,//dl.SAP_Material_Code__c,
                        Unique_ID__c = SAPforecastKey,
                        Budget__c = 0,
                        Forecast__c = 0,
                        Budget_Tonnage__c = 0,
                        Forecast_Tonnage__c = 0
                    )
                );
            } else if (dl.Forecast__c != null) {
                
                fcast = new Forecast__c(Unique_ID__c = forecastKey);
                context.forecastUpsertMap.put(
                    forecastKey,
                    new Forecast__c(
                        Month__r = mth,
                        Product__r = prod,
                        Name = dl.Bottle_Identifier__c,
                        Unique_ID__c = forecastKey,
                        Budget__c = 0,
                        Forecast__c = 0,
                        Budget_Tonnage__c = 0,
                        Forecast_Tonnage__c = 0
                    )
                );
            } else {
                
                dl.Process_Status__c = WARNING_STATUS;
                dl.Process_Error__c += 'Unable to create new forecast for Dispatch '+ dl.Dispatch_ID__c + '\n';
                context.errorWarningCount++;
            }

            Datetime dispatchDateTime = null;

            if (dl.Dispatch_Date__c != null) {
                
                Integer dno = dl.Dispatch_Date__c.day();
                Integer mno = dl.Dispatch_Date__c.month();
                Integer yno = dl.Dispatch_Date__c.year();
                if (dl.Dispatch_Time__c == null) {
                    
                    dispatchDateTime = Datetime.newInstance(yno, mno, dno);
                } else {
                    
                    Integer hhno = Integer.valueOf(dl.Dispatch_Time__c.substring(0,2));
                    Integer mmno = Integer.valueOf(dl.Dispatch_Time__c.substring(3,5));
                    Integer ssno = Integer.valueOf(dl.Dispatch_Time__c.substring(6,8));
                    dispatchDateTime = Datetime.newInstance(yno, mno, dno, hhno, mmno, ssno);
                }
            }

            Datetime deliveryDate = null;

            if (dl.Planned_delivery_Date__c != null) {
                
                Integer dno = dl.Planned_delivery_Date__c.day();
                Integer mno = dl.Planned_delivery_Date__c.month();
                Integer yno = dl.Planned_delivery_Date__c.year();
                
                if (dl.Planned_delivery_Time__c == null) {
                
                    deliveryDate = Datetime.newInstance(yno, mno, dno);
                } else {
                
                    Integer hhno = Integer.valueOf(dl.Planned_delivery_Time__c.substring(0,2));
                    Integer mmno = Integer.valueOf(dl.Planned_delivery_Time__c.substring(3,5));
                    Integer ssno = Integer.valueOf(dl.Planned_delivery_Time__c.substring(6,8));
                    deliveryDate = Datetime.newInstance(yno, mno, dno, hhno, mmno, ssno);
                }
            }

            Dispatch__c du = new Dispatch__c(
                Name = getDispatchName(dl),
                Customer__r = acct,
                Month__r = mth,
                Bottle__r = prod,
                SAP_Material_Code__r = material,
                Forecast__r = fcast,
                Haulier__r = haulier,
                Type__c = dl.Type__c,
                Delivery_Code__c = dl.Delivery_Code__c,
                Dispatch_ID__c = dl.Dispatch_ID__c,
                Unique_ID__c = dl.Unique_ID__c,
                Dispatch_Date__c = dl.Dispatch_Date__c,
                Dispatch_Time__c = dl.Dispatch_Time__c,
                Dispatch_Date_Time__c = dispatchDateTime,
                Planned_Delivery_Date__c = deliveryDate,
                Site_ID__c = dl.Site_ID__c,
                Warehouse_ID__c = dl.Warehouse_ID__c,
                Freight_Reference__c = dl.Freight_Reference__c,
                Pack_Specification__c = dl.Pack_Specification__c,
                Units__c = dl.Units__c,
                Tonnage__c = dl.Tonnage__c,
                Load_Job_Id__c = jobId,
                Staging_Id__c = dl.Id,
                Week__c = dl.Week__c,
                Week_in_Month__c = dl.Week_in_Month__c,
                
                //Addition of new fields - Abhishek Aug 2025
                Store__c = dl.Store__c,
                Customer_Code__c = dl.Customer_Code__c,
                Item__c = dl.Item__c,
                Shipment_Number__c = dl.Shipment_Number__c,
                Record_Creation_Date__c = dl.Record_Creation_Date__c,
                Entry_Time__c = dl.Entry_Time__c,
                Plate_Number__c = dl.Plate_Number__c,
                Trailer_Plate_Number__c = dl.Trailer_Plate_Number__c,
                Overall_Transportation_Status__c = dl.Overall_Transportation_Status__c,
                End_of_Planning_Date__c = dl.End_of_Planning_Date__c,
                Scheduling_End_Time__c = dl.Scheduling_End_Time__c,
                Planned_Date_of_Check_In__c = dl.Planned_Date_of_Check_In__c,	
                Planned_Check_In_Time__c = dl.Planned_Check_In_Time__c,
                Actual_Date_of_Check_In__c = dl.Actual_Date_of_Check_In__c,
                Current_Time_of_Check_In__c = dl.Current_Time_of_Check_In__c,
                Planned_Date_for_Start_of_Loading__c = dl.Planned_Date_for_Start_of_Loading__c,
                Planned_Loading_Start_Time__c = dl.Planned_Loading_Start_Time__c,
                Current_Date_for_Start_of_Loading__c = dl.Current_Date_for_Start_of_Loading__c,
                Actual_Loading_Start_Time__c = dl.Actual_Loading_Start_Time__c,
                Planned_Date_for_End_of_Loading__c = dl.Planned_Date_for_End_of_Loading__c,
                Planned_Loading_End_Time__c = dl.Planned_Loading_End_Time__c,
                Actual_Date_for_End_of_Loading__c = dl.Actual_Date_for_End_of_Loading__c,
                Actual_Loading_End_Time__c = dl.Actual_Loading_End_Time__c,
                Planned_Date_for_Shipment_Completion__c = dl.Planned_Date_for_Shipment_Completion__c,
                Planned_Time_for_Processing__c = dl.Planned_Time_for_Processing__c,
                Current_Date_of_Shipment_Completion__c = dl.Current_Date_of_Shipment_Completion__c,
                Time_of_Transportation_Processing__c = dl.Time_of_Transportation_Processing__c,
                Planned_Date_for_Start_of_Shipment__c = dl.Planned_Date_for_Start_of_Shipment__c,
                Planned_Transport_Start_Time__c = dl.Planned_Transport_Start_Time__c,
                Current_Date_for_Start_of_Shipment__c = dl.Current_Date_for_Start_of_Shipment__c,
                Actual_Transport_Start_Time__c = dl.Actual_Transport_Start_Time__c,
                Planned_Date_for_End_of_Shipment__c = dl.Planned_Date_for_End_of_Shipment__c,
                Planned_Transport_End_Time__c = dl.Planned_Transport_End_Time__c,
                Actual_Date_for_End_of_Shipment__c = dl.Actual_Date_for_End_of_Shipment__c,
                Actual_Shipment_End_Time__c = dl.Actual_Shipment_End_Time__c,
                Purchasing_Document_Number__c = dl.Purchasing_Document_Number__c,
                Sales_Document__c = dl.Sales_Document__c,
                Number_of_Material_Document__c = dl.Number_of_Material_Document__c,
                Material_Document_Year__c = dl.Material_Document_Year__c,
                Batch_Number__c = dl.Batch_Number__c,
                Series__c = dl.Series__c,
                Salesforce_Unique_ID__c = dl.Salesforce_Unique_ID__c,
                
                //Case 00067826 - new fields addition - Abhishek Oct 2025
                Dispatch_Name__c = dl.Delivery_Name__c,
                Dispatch_Staging_Record__c = dl.Id
            );

            context.dispatchUpsertMap.put(dl.Unique_ID__c, du);
        }
    }

    /** 
     * Prepare dispatch name and return.
     * 
     * @param dl The dispatch staging record.
     */
    private String getDispatchName(Dispatch_Staging__c dl) {

        String name = dl.Dispatch_ID__c + '-';
            
        if (dl.Delivery_Name__c == null) {

            if (dl.Customer_Name__c.length() > 60) {
                
                name += dl.Customer_Name__c.substring(0,60) + '-' + String.valueOf(dl.Dispatch_Date__c);
            } else {
                
                name += dl.Customer_Name__c + '-' + String.valueOf(dl.Dispatch_Date__c);
            }
        } else {

            if (dl.Delivery_Name__c.length() > 60) {
                
                name += dl.Delivery_Name__c.substring(0,60) + '-' + String.valueOf(dl.Dispatch_Date__c);
            } else {
                
                name += dl.Delivery_Name__c + '-' + String.valueOf(dl.Dispatch_Date__c);
            }
        }

        return name;
    }

    /** 
     * Upsert records.
     * 
     * @param context The context of the dispatch context.
     */
    private void upsertRecords(DispatchContext context) {

        if (context.prodUpsertMap.size() > 0) {

            upsert context.prodUpsertMap.values() Bottle_Identifier__c;
        }

        // M.Witchalls May 2018
        if (context.materialUpsertMap.size() > 0) {

            List<Database.UpsertResult> mcResults = Database.upsert(context.materialUpsertMap.values(), false);
            
            for(Database.UpsertResult r: mcResults) {

                if(!r.isSuccess()) {

                    System.debug('SAP Material Code Upsert Error: '+ r.getErrors()[0].getMessage());
                }
            }
        }

        if (context.haulierInsertMap.size() > 0) {
            
            insert context.haulierInsertMap.values();
        }

        if (context.monthUpsertMap.size() > 0) {

            List<Database.UpsertResult> mresults = Database.upsert(context.monthUpsertMap.values(), false);
            
            for(Database.UpsertResult r: mresults) {

                if(!r.isSuccess()) {

                    system.debug('Month Upsert Error: '+ r.getErrors()[0].getMessage());
                }
            }
        }

        if (context.forecastUpsertMap.size() > 0) {

            List<Database.UpsertResult> fresults = Database.upsert(context.forecastUpsertMap.values(), false);
            for(Database.UpsertResult r: fresults) {

                if(!r.isSuccess()) {

                    system.debug('Forecast Upsert Error: '+ r.getErrors()[0].getMessage());
                }
            }
        }

    //Upsert Logic
    if (!context.dispatchUpsertMap.isEmpty()) {
    // Collect keys from staging
    Set<String> sfKeys = new Set<String>();
    Set<String> uniqueKeys = new Set<String>();
    
    for (Dispatch__c d : context.dispatchUpsertMap.values()) {
        if (String.isNotBlank(d.Salesforce_Unique_ID__c)) {
            sfKeys.add(d.Salesforce_Unique_ID__c);
        }
        if (String.isNotBlank(d.Unique_ID__c)) {
            uniqueKeys.add(d.Unique_ID__c);
        }
    }
    
    // Query existing Dispatch__c records
    Map<String, Dispatch__c> bySFKey = new Map<String, Dispatch__c>();
    Map<String, Dispatch__c> byUniqueKey = new Map<String, Dispatch__c>();
    
    if (!sfKeys.isEmpty() || !uniqueKeys.isEmpty()) {
        for (Dispatch__c existing : [
            SELECT Id, Salesforce_Unique_ID__c, Unique_ID__c
            FROM Dispatch__c
            WHERE Salesforce_Unique_ID__c IN :sfKeys
            OR Unique_ID__c IN :uniqueKeys
        ]) {
            if (String.isNotBlank(existing.Salesforce_Unique_ID__c)) {
                bySFKey.put(existing.Salesforce_Unique_ID__c, existing);
            }
            if (String.isNotBlank(existing.Unique_ID__c)) {
                byUniqueKey.put(existing.Unique_ID__c, existing);
            }
        }
    }
    
    // Separate into update and insert lists
    List<Dispatch__c> toInsert = new List<Dispatch__c>();
    List<Dispatch__c> toUpdate = new List<Dispatch__c>();
    Set<String> processedKeys = new Set<String>();
    
    for (Dispatch__c newRec : context.dispatchUpsertMap.values()) {
        String dedupKey = (newRec.Salesforce_Unique_ID__c != null ? newRec.Salesforce_Unique_ID__c : '') + '|' +
                          (newRec.Unique_ID__c != null ? newRec.Unique_ID__c : '');
        if (processedKeys.contains(dedupKey)) continue;
        processedKeys.add(dedupKey);
        
        if (bySFKey.containsKey(newRec.Salesforce_Unique_ID__c)) {
            newRec.Id = bySFKey.get(newRec.Salesforce_Unique_ID__c).Id;
            toUpdate.add(newRec);
        } else if (byUniqueKey.containsKey(newRec.Unique_ID__c)) {
            newRec.Id = byUniqueKey.get(newRec.Unique_ID__c).Id;
            toUpdate.add(newRec);
        } else {
            toInsert.add(newRec);
        }
    }
    
    // Perform update with partial success + error handling
    if (!toUpdate.isEmpty()) {
        List<Database.SaveResult> updateResults = Database.update(toUpdate, false);
        for (Integer i = 0; i < updateResults.size(); i++) {
            if (!updateResults[i].isSuccess()) {
                Dispatch__c failedRec = toUpdate[i];
                String uniqueId = failedRec.Unique_ID__c;
                Dispatch_Staging__c stagingRec = context.dispatchLoadMap.get(uniqueId);
                stagingRec.Process_Status__c = ERROR_STATUS;
                stagingRec.Process_Error__c = String.join(
                    new List<String>{
                        updateResults[i].getErrors()[0].getMessage()
                    }, ';'
                );
                System.debug('Update Error for Unique_ID__c=' + uniqueId + ': ' + stagingRec.Process_Error__c);
                context.errorWarningCount++;
            }
        }
    }
    
    // Perform insert with partial success + error handling
    if (!toInsert.isEmpty()) {
        List<Database.SaveResult> insertResults = Database.insert(toInsert, false);
        for (Integer i = 0; i < insertResults.size(); i++) {
            if (!insertResults[i].isSuccess()) {
                Dispatch__c failedRec = toInsert[i];
                String uniqueId = failedRec.Unique_ID__c;
                Dispatch_Staging__c stagingRec = context.dispatchLoadMap.get(uniqueId);
                stagingRec.Process_Status__c = ERROR_STATUS;
                stagingRec.Process_Error__c = String.join(
                    new List<String>{
                        insertResults[i].getErrors()[0].getMessage()
                    }, ';'
                );
                	System.debug('Insert Error for Unique_ID__c=' + uniqueId + ': ' + stagingRec.Process_Error__c);
                	context.errorWarningCount++;
           	 }
       	   }
    	 }
       }

        // Update staging records after processing
        update context.dispatchLoadMap.values();
   }
    
        
    /** 
     * Wrapper/helper class of the dispatch context to process the data.
     */
    public class DispatchContext {
        
        public String jobId;
        public Integer errorWarningCount;
        public Map<String, Dispatch_Staging__c> dispatchLoadMap;
        public Map<String, Dispatch__c> dispatchUpsertMap;
        public Map<String, Bottle__c> prodUpsertMap;
        public Map<String, SAP_Material_Code__c> materialUpsertMap;
        public Map<String, Haulier__c> haulierInsertMap;
        public Map<String, Month__c> monthUpsertMap;
        public Map<String, Forecast__c> forecastUpsertMap;
    
        public Set<String> prodCodeSet;
        public Set<String> materialCodeSet;
        public Set<String> haulierCodeSet;
        public Set<String> monthSet;
        public Set<String> forecastSet;
        public Set<String> SAPforecastSet;
        public Set<String> accountSet;
    
        public Set<String> prodExistsSet;
        public Set<String> materialExistsSet;
        public Set<String> haulierExistsSet;
        public Set<String> monthExistsSet;
        public Set<String> forecastExistsSet;
        public Set<String> forecastSAPExistsSet;
        public Set<String> accountExistsSet;
    
        public Map<String, String> monthKeyMap;
        public Map<String, String> forecastKeyMap;
    
        public Map<String, Account> SAPaccountExistsMap;
    
        /** 
         * Processes/prepare each dispatch record.
         * 
         * @param dispatchLoadList The Dispatch Staging to process.
         * @param jobId            The jobId of the batch.
         */
        public DispatchContext(List<Dispatch_Staging__c> dispatchLoadList, String jobId) {

            this.errorWarningCount = 0;
            this.dispatchLoadMap = new Map<String, Dispatch_Staging__c>();
            this.dispatchUpsertMap = new Map<String, Dispatch__c>();
            this.prodUpsertMap = new Map<String, Bottle__c>();
            this.materialUpsertMap = new Map<String, SAP_Material_Code__c>();
            this.haulierInsertMap = new Map<String, Haulier__c>();
            this.monthUpsertMap = new Map<String, Month__c>();
            this.forecastUpsertMap = new Map<String, Forecast__c>();
    
            this.prodCodeSet = new Set<String>();
            this.materialCodeSet = new Set<String>();
            this.haulierCodeSet = new Set<String>();
            this.monthSet = new Set<String>();
            this.forecastSet = new Set<String>();
            this.SAPforecastSet = new Set<String>();
            this.accountSet = new Set<String>();
    
            this.prodExistsSet = new Set<String>();
            this.materialExistsSet = new Set<String>();
            this.haulierExistsSet = new Set<String>();
            this.monthExistsSet = new Set<String>();
            this.forecastExistsSet = new Set<String>();
            this.forecastSAPExistsSet = new Set<String>();
            this.accountExistsSet = new Set<String>();
    
            this.monthKeyMap = new Map<String, String>();
            this.forecastKeyMap = new Map<String, String>();    
            this.SAPaccountExistsMap = new Map<String, Account>();

            populateSets(dispatchLoadList);

            populateExistingRecords(dispatchLoadList, jobId);            
        }

        /** 
         * Populate sets to processes record.
         * 
         * @param dispatchLoadList The dispatch Staging to process.
         */
        private void populateSets(List<Dispatch_Staging__c> dispatchLoadList) {
            
            for (Dispatch_Staging__c dl: dispatchLoadList) {

                if (dl.SAP_Material_Code__c != null) {
                 
                    materialCodeSet.add(dl.SAP_Material_Code__c);  // M.Witchalls May 2018
                }

                if (dl.Bottle_Identifier__c != null) {
                    
                    prodCodeSet.add(dl.Bottle_Identifier__c);
                }

                if (dl.Bottle_Identifier__c == null && dl.SAP_Model_Number__c != null) {
                    
                    prodCodeSet.add(dl.SAP_Model_Number__c); // M.Witchalls May 2018
                }

                haulierCodeSet.add(dl.Haulier_Code__c);
                accountSet.add(dl.Encirc_Account_Number__c);
            }
        }

        /** 
         * Populate sets to processes record.
         * 
         * @param dispatchLoadList The dispatch Staging to process records.
         */
        private void populateExistingRecords(List<Dispatch_Staging__c> dispatchLoadList, String jobId) {

            for (Account a: [
                SELECT Id, SAP_Account_Number__c FROM Account WHERE SAP_Account_Number__c in :accountSet
            ]) {

                accountExistsSet.add(a.SAP_Account_Number__c);
                SAPaccountExistsMap.put(a.SAP_Account_Number__c, a);
            }
    
            for (Dispatch_Staging__c dl: dispatchLoadList) {
                
                processDispatchLoadRecord(dl, jobId);
            }
    
            for (Bottle__c p: [
                SELECT
                    Id, Name, Bottle_Identifier__c
                FROM
                    Bottle__c
                WHERE
                    Bottle_Identifier__c IN :prodCodeSet
            ]) {

                // If a dummy Bottle record has been created, update it
                if (!p.Name.startsWith('Bottle ')) {

                    prodExistsSet.add(p.Bottle_Identifier__c);
                }
            }
            // M.Witchalls May 2018
            for (SAP_Material_Code__c mc: [
                SELECT
                    Id, Name, Material_Code_Key__c, Bottle_Identifier__c
                FROM
                    SAP_Material_Code__c
                WHERE
                    Material_Code_Key__c in :materialCodeSet
            ]) {

                materialExistsSet.add(mc.Name);
            }
    
            for (Haulier__c h: [
                SELECT Id, Haulier_Code__c FROM Haulier__c WHERE Haulier_Code__c in :haulierCodeSet
            ]) {

                haulierExistsSet.add(h.Haulier_Code__c);
            }
    
            for (Month__c m: [
                SELECT Id, Unique_ID__c FROM Month__c WHERE Unique_ID__c in :monthSet
            ]) {

                monthExistsSet.add(m.Unique_ID__c);
            }
    
            for (Forecast__c f: [
                SELECT Id, Unique_ID__c FROM Forecast__c WHERE Unique_ID__c in :forecastSet
            ]) {

                forecastExistsSet.add(f.Unique_ID__c);
            }

            for (Forecast__c f: [
                SELECT Id, Unique_ID__c FROM Forecast__c WHERE Unique_ID__c in :SAPforecastSet
            ]) {

                forecastSAPExistsSet.add(f.Unique_ID__c);
            }
        }

        /** 
         * Populate sets to processes record.
         * 
         * @param dl The dispatch Staging to process record.
         */
        private void processDispatchLoadRecord(Dispatch_Staging__c dl, String jobId) {

            dl.Process_Job__c = jobId;
            dl.Process_Status__c = SUCCESS_STATUS;
            dl.Process_Date__c = System.now();
            dl.Process_Error__c = '';
            dispatchLoadMap.put(dl.Unique_ID__c, dl);

            // M.Witchalls May 2018
            String monthKey = dl.Month__c;
            String forecastKey = dl.Forecast__c;
            String SAPforecastKey = dl.Forecast_SAP__c;

            if (!accountExistsSet.contains(dl.Encirc_Account_Number__c)) {

                // M.Witchalls May 2018
                Account a = SAPaccountExistsMap.get(dl.Encirc_Account_Number__c);

                if (a != null) {

                    String encircNo = a.SAP_Account_Number__c.leftPad(7).replace(' ','0');
                    String SAPNo = a.SAP_Account_Number__c.leftPad(7).replace(' ','0');
                    monthKey = monthKey.replace(SAPNo, encircNo);
                    
                    if (dl.Forecast__c != null) {
                        
                        forecastKey = forecastKey.replace(SAPNo, encircNo);
                    }

                    if (dl.Forecast_SAP__c != null) {
                        
                        SAPforecastKey = SAPforecastKey.replace(SAPNo, encircNo);
                    }
                }
            }

            monthSet.add(monthKey);
            forecastSet.add(forecastKey);
            SAPforecastSet.add(SAPforecastKey);

            monthKeyMap.put(dl.Month__c, monthKey);

            if (dl.Forecast__c != null) {

                forecastKeyMap.put(dl.Forecast__c, forecastKey);
            } 
            if (dl.Forecast_SAP__c != null) {

                forecastKeyMap.put(dl.Forecast_SAP__c, SAPforecastKey);
            }
        }
    }
}





// TODO remove once it has been tested/validated/QA-ed
/*global class DispatchLoadBatch implements Database.Batchable<sObject>, Database.Stateful{
    global static final String systemAdminGroup = 'System_admin_group';
    global static final String dcRecipientGroup = 'DC_Recipients';
    global static final String otifRecipientGroup = 'OTIF_Email_Recipients';
    global static final String dcEmailTemplateName = 'Daily_Comparatives';
    global static final String otifEmailTemplateName = 'Daily_OTIF';

    global static final Set<String> EXCLUDE_FROM_OTIF_SET = new Set<String>{'0','11529'};

    global static final String newStatus = 'New';
    global static final String SUCCESS_STATUS = 'Success';
    global static final String ERROR_STATUS = 'Error';
    global static final String WARNING_STATUS = 'Warning';
    
    //Email Notification Time Delay
    private integer delaySeconds = 3600;

    // Async Apex Job Id
    global String jobId;

    global Integer errorWarningCount = 0;

    // This method defines the records which are to be processed
    global Database.QueryLocator start(Database.BatchableContext dbc){
        if (jobId == null) {
            jobId = dbc.getJobId();
            system.debug('Batch Job Id: '+jobId);
        }
        return Database.getQueryLocator([
            SELECT
                Id, Dispatch_ID__c, Unique_ID__c, Dispatch_Date__c, Month__c, Week__c, Week_in_Month__c, Calendar_Month__c, Year__c,
                Forecast__c, Forecast_SAP__c, Dispatch_Time__c, // M.Witchalls May 2018
                Delivery_Name__c, Delivery_Code__c, Type__c,
                Customer_Name__c, Encirc_Account_Number__c, Haulier_Code__c, Haulier_Name__c,
                Planned_Delivery_Date__c, Planned_Delivery_Time__c,
                Site_ID__c, Warehouse_ID__c, Freight_Reference__c,
                Bottle_Identifier__c, Bottle_Description__c,
                SAP_Model_Number__c, SAP_Material_Code__c,  // M.Witchalls May 2018
                Pack_Specification__c, Units__c, Tonnage__c, Weight_per_Unit__c,
                Process_Job__c, Process_Status__c, Process_Error__c, Process_Date__c
            FROM
                Dispatch_Staging__c
            WHERE
                Dispatch_ID__c != null AND Process_Status__c IN (:newStatus,:ERROR_STATUS)
                //Dispatch_ID__c != null AND Process_Status__c IN (:newStatus,:ERROR_STATUS,:SUCCESS_STATUS,:WARNING_STATUS)
            ORDER BY
                Dispatch_Date__c, Name
        ]);
    }

    // This method works on each batch according to the batch size. Each batch is passed as the second parameter to this method
    global void execute(Database.BatchableContext dbc, List<Dispatch_Staging__c> dispatchLoadList){
        errorWarningCount = 0;
        Map<String, Dispatch_Staging__c> dispatchLoadMap = new Map<String, Dispatch_Staging__c>();
        Map<String, Dispatch__c> dispatchUpsertMap = new Map<String, Dispatch__c>();

        Map<String, Bottle__c> prodUpsertMap = new Map<String, Bottle__c>();
        Map<String, SAP_Material_Code__c> materialUpsertMap = new Map<String, SAP_Material_Code__c>();

        Map<String, Haulier__c> haulierInsertMap = new Map<String, Haulier__c>();
        Map<String, Month__c> monthUpsertMap = new Map<String, Month__c>();
        Map<String, Forecast__c> forecastUpsertMap = new Map<String, Forecast__c>();
        Set<String> prodCodeSet = new Set<String>();
        Set<String> prodExistsSet = new Set<String>();
        Set<String> materialCodeSet = new Set<String>();
        Set<String> materialExistsSet = new Set<String>();
        Set<String> haulierCodeSet = new Set<String>();
        Set<String> haulierExistsSet = new Set<String>();
        Set<String> forecastSet = new Set<String>();
        Set<String> SAPforecastSet = new Set<String>();
        Set<String> forecastExistsSet = new Set<String>();
        Set<String> forecastSAPExistsSet = new Set<String>();
        Set<String> monthSet = new Set<String>();
        Set<String> monthExistsSet = new Set<String>();
        Set<String> accountSet = new Set<String>();
        Set<String> accountExistsSet = new Set<String>();
        Map<String, String> monthKeyMap = new Map<String, String>();
        Map<String, String> forecastKeyMap = new Map<String, String>();

        // M.Witchalls May 2018
        Map<String,Account> SAPaccountExistsMap = new Map<String,Account>();

        for (Dispatch_Staging__c dl: dispatchLoadList) {
            if (dl.SAP_Material_Code__c != null) materialCodeSet.add(dl.SAP_Material_Code__c);  // M.Witchalls May 2018
            if (dl.Bottle_Identifier__c != null) prodCodeSet.add(dl.Bottle_Identifier__c);
            if (dl.Bottle_Identifier__c == null && dl.SAP_Model_Number__c != null) prodCodeSet.add(dl.SAP_Model_Number__c); // M.Witchalls May 2018
            haulierCodeSet.add(dl.Haulier_Code__c);
            accountSet.add(dl.Encirc_Account_Number__c);
        }
        system.debug('monthSet: '+monthSet);
        for (Account a: [
            SELECT Id, SAP_Account_Number__c FROM Account WHERE SAP_Account_Number__c in :accountSet
        ]) {
            accountExistsSet.add(a.SAP_Account_Number__c);
        }
        for (Account a: [
            SELECT Id, SAP_Account_Number__c FROM Account WHERE SAP_Account_Number__c in :accountSet
        ]) {
            SAPaccountExistsMap.put(a.SAP_Account_Number__c, a);
        }

        for (Dispatch_Staging__c dl: dispatchLoadList) {
            dl.Process_Job__c = jobId;
            dl.Process_Status__c = SUCCESS_STATUS;
            dl.Process_Date__c = System.now();
            dl.Process_Error__c = '';
            dispatchLoadMap.put(dl.Unique_ID__c, dl);

            // M.Witchalls May 2018
            String monthKey = dl.Month__c;
            String forecastKey = dl.Forecast__c;
            String SAPforecastKey = dl.Forecast_SAP__c;

            if (!accountExistsSet.contains(dl.Encirc_Account_Number__c)) {

                // M.Witchalls May 2018
                Account a = SAPaccountExistsMap.get(dl.Encirc_Account_Number__c);
                if (a != null) {
                    String encircNo = a.SAP_Account_Number__c.leftPad(7).replace(' ','0');
                    String SAPNo = a.SAP_Account_Number__c.leftPad(7).replace(' ','0');
                    monthKey = monthKey.replace(SAPNo, encircNo);
                    if (dl.Forecast__c != null) forecastKey = forecastKey.replace(SAPNo, encircNo);
                    if (dl.Forecast_SAP__c != null) SAPforecastKey = SAPforecastKey.replace(SAPNo, encircNo);
                }
            }

            monthSet.add(monthKey);
            forecastSet.add(forecastKey);
            SAPforecastSet.add(SAPforecastKey);

            monthKeyMap.put(dl.Month__c, monthKey);
            if (dl.Forecast__c != null) forecastKeyMap.put(dl.Forecast__c, forecastKey);
            if (dl.Forecast_SAP__c != null) forecastKeyMap.put(dl.Forecast_SAP__c, SAPforecastKey);
        }

        for (Bottle__c p: [
            SELECT
                Id, Name, Bottle_Identifier__c
            FROM
                Bottle__c
            WHERE
                Bottle_Identifier__c IN :prodCodeSet
        ]) {
            // If a dummy Bottle record has been created, update it
            if (!p.Name.startsWith('Bottle ')) {
                prodExistsSet.add(p.Bottle_Identifier__c);
            }
        }
        // M.Witchalls May 2018
        for (SAP_Material_Code__c mc: [
            SELECT
                Id, Name, Material_Code_Key__c, Bottle_Identifier__c
            FROM
                SAP_Material_Code__c
            WHERE
                Material_Code_Key__c in :materialCodeSet
        ]) {
            materialExistsSet.add(mc.Name);
        }

        for (Haulier__c h: [
            SELECT Id, Haulier_Code__c FROM Haulier__c WHERE Haulier_Code__c in :haulierCodeSet
        ]) {
            haulierExistsSet.add(h.Haulier_Code__c);
        }

        for (Month__c m: [
            SELECT Id, Unique_ID__c FROM Month__c WHERE Unique_ID__c in :monthSet
        ]) {
            monthExistsSet.add(m.Unique_ID__c);
        }
        system.debug('monthExistsSet: '+monthExistsSet);

        for (Forecast__c f: [
            SELECT Id, Unique_ID__c FROM Forecast__c WHERE Unique_ID__c in :forecastSet
        ]) {
            forecastExistsSet.add(f.Unique_ID__c);
        }
        for (Forecast__c f: [
            SELECT Id, Unique_ID__c FROM Forecast__c WHERE Unique_ID__c in :SAPforecastSet
        ]) {
            forecastSAPExistsSet.add(f.Unique_ID__c);
        }

        // Create Dispatch records from Dispatch Staging records
        for (Dispatch_Staging__c dl: dispatchLoadList) {

            // M.Witchalls May 2018
            String bottleIdentifier = dl.Bottle_Identifier__c;
            if (dl.Bottle_Identifier__c == null && dl.SAP_Model_Number__c != null) bottleIdentifier = dl.SAP_Model_Number__c;

            Account acct = new Account(SAP_Account_Number__c = dl.Encirc_Account_Number__c);
            Account SAPacct = new Account(SAP_Account_Number__c = dl.Encirc_Account_Number__c); // M.Witchalls May 2018

            Month__c mth = new Month__c(Unique_ID__c = monthKeyMap.get(dl.Month__c));
            Bottle__c prod = new Bottle__c(Bottle_Identifier__c = bottleIdentifier);
            SAP_Material_Code__c material;
            if (dl.SAP_Material_Code__c != null) {
                material = new SAP_Material_Code__c(Material_Code_Key__c = dl.SAP_Material_Code__c);
            }
            //Forecast__c fcast = new Forecast__c(Unique_ID__c = dl.Forecast__c);
            Haulier__c haulier = new Haulier__c(Haulier_Code__c = dl.Haulier_Code__c);

            if (bottleIdentifier != null) {
                if (!prodExistsSet.contains(bottleIdentifier)) {
                    if (dl.Bottle_Description__c == null) dl.Bottle_Description__c = 'Bottle '+bottleIdentifier;
                    prodUpsertMap.put(
                        bottleIdentifier,
                        new Bottle__c(
                            Name = dl.Bottle_Description__c,
                            Bottle_Identifier__c = bottleIdentifier,
                            SAP_Model_Number__c = dl.SAP_Model_Number__c,
                            Weight_per_Unit__c = dl.Weight_per_Unit__c
                        )
                    );
                }
            }
            // M.Witchalls May 2018
            if (dl.SAP_Material_Code__c != null && !materialExistsSet.contains(dl.SAP_Material_Code__c)) {
                SAP_Material_Code__c newRecord = new SAP_Material_Code__c(
                    Name = dl.SAP_Material_Code__c,
                    Material_Code_Key__c = dl.SAP_Material_Code__c,
                    Bottle_Identifier__c = dl.Bottle_Identifier__c,
                    Pack_Spec__c = dl.Pack_Specification__c
                );
                if (dl.SAP_Model_Number__c != null) {
                    newRecord.Bottle__r = new Bottle__c(SAP_Model_Number__c = dl.SAP_Model_Number__c);
                } else if (dl.Bottle_Identifier__c != null) {
                    newRecord.Bottle__r = new Bottle__c(Bottle_Identifier__c = dl.Bottle_Identifier__c);
                }
                materialUpsertMap.put(dl.SAP_Material_Code__c, newRecord);
            }

            if (dl.Haulier_Code__c != null && !haulierExistsSet.contains(dl.Haulier_Code__c)) {
                if (dl.Haulier_Name__c == null) dl.Haulier_Name__c = 'Haulier '+dl.Haulier_Code__c;
                Boolean excludeFromOTIF = (EXCLUDE_FROM_OTIF_SET.contains(dl.Haulier_Code__c)) ? true : false;
                haulierInsertMap.put(
                    dl.Haulier_Code__c,
                    new Haulier__c(
                        Name = dl.Haulier_Name__c,
                        Haulier_Code__c = dl.Haulier_Code__c,
                        Exclude_from_OTIF__c = excludeFromOTIF
                    )
                );
            }

            // M.Witchalls May 2018
            Boolean abortRecord = false;

            if (!accountExistsSet.contains(dl.Encirc_Account_Number__c)) {
                acct = SAPacct;

                // M.Witchalls May 2018
                if (!SAPaccountExistsMap.keySet().contains(dl.Encirc_Account_Number__c)) {
                    abortRecord = true;
                    // Missing Account is a fatal error
                    dl.Process_Status__c = ERROR_STATUS;
                    dl.Process_Error__c += 'Missing Account for Encirc/SAP Account Number '+ dl.Encirc_Account_Number__c + '\n';
                    errorWarningCount++;
                }
            }

            if (!abortRecord) {
                String monthKey = monthKeyMap.get(dl.Month__c);
                if (monthKey != null && !monthExistsSet.contains(monthKey)) {
                    monthUpsertMap.put(
                        monthKey,
                        new Month__c(
                            Customer__r = acct,
                            Name = dl.Calendar_Month__c,
                            Calendar_Month__c = dl.Calendar_Month__c,
                            Year__c = dl.Year__c,
                            Unique_ID__c = monthKey
                        )
                    );
                    dl.Process_Status__c = WARNING_STATUS;
                    dl.Process_Error__c += 'Missing Month record '+ monthKey + ';\n';
                    errorWarningCount++;
                }

                Forecast__c fcast;

                // M.Witchalls May 2018
                   ______________________________________________________________________________________

                   If there is a SAP Material Code, and the corresponding Forecast record exists, use it.
                   Otherwise if a product-level Forecast record exists, use it.
                   Otherwise if there is a SAP Material Code, create a material-level Forecast record
                   Otherwise create a product-level Forecast record
                   ______________________________________________________________________________________
                //
                String forecastKey = forecastKeyMap.get(dl.Forecast__c);
                String SAPforecastKey = forecastKeyMap.get(dl.Forecast_SAP__c);

                if (dl.Forecast_SAP__c != null && forecastSAPExistsSet.contains(SAPforecastKey)) {
                    fcast = new Forecast__c(Unique_ID__c = SAPforecastKey);
                } else if (dl.Forecast__c != null && forecastExistsSet.contains(forecastKey)) {
                    fcast = new Forecast__c(Unique_ID__c = forecastKey);
                } else if (dl.Forecast_SAP__c != null) {
                    fcast = new Forecast__c(Unique_ID__c = SAPforecastKey);
                    forecastUpsertMap.put(
                        SAPforecastKey,
                        new Forecast__c(
                            Month__r = mth,
                            Product__r = prod,
                            SAP_Material_Code__r = material,
                            Name = dl.SAP_Material_Code__c,
                            Unique_ID__c = SAPforecastKey,
                            Budget__c = 0,
                            Forecast__c = 0,
                            Budget_Tonnage__c = 0,
                            Forecast_Tonnage__c = 0
                        )
                    );
                } else if (dl.Forecast__c != null) {
                    fcast = new Forecast__c(Unique_ID__c = forecastKey);
                    forecastUpsertMap.put(
                        forecastKey,
                        new Forecast__c(
                            Month__r = mth,
                            Product__r = prod,
                            Name = dl.Bottle_Identifier__c,
                            Unique_ID__c = forecastKey,
                            Budget__c = 0,
                            Forecast__c = 0,
                            Budget_Tonnage__c = 0,
                            Forecast_Tonnage__c = 0
                        )
                    );
                } else {
                    dl.Process_Status__c = WARNING_STATUS;
                    dl.Process_Error__c += 'Unable to create new forecast for Dispatch '+ dl.Dispatch_ID__c + '\n';
                    errorWarningCount++;
                }

                Datetime dispatchDateTime = null;
                if (dl.Dispatch_Date__c != null) {
                    Integer dno = dl.Dispatch_Date__c.day();
                    Integer mno = dl.Dispatch_Date__c.month();
                    Integer yno = dl.Dispatch_Date__c.year();
                    If (dl.Dispatch_Time__c == null) {
                        dispatchDateTime = Datetime.newInstance(yno, mno, dno);
                    } else {
                        Integer hhno = Integer.valueOf(dl.Dispatch_Time__c.substring(0,2));
                        Integer mmno = Integer.valueOf(dl.Dispatch_Time__c.substring(3,5));
                        Integer ssno = Integer.valueOf(dl.Dispatch_Time__c.substring(6,8));
                        dispatchDateTime = Datetime.newInstance(yno, mno, dno, hhno, mmno, ssno);
                    }
                }
                Datetime deliveryDate = null;
                if (dl.Planned_delivery_Date__c != null) {
                    Integer dno = dl.Planned_delivery_Date__c.day();
                    Integer mno = dl.Planned_delivery_Date__c.month();
                    Integer yno = dl.Planned_delivery_Date__c.year();
                    If (dl.Planned_delivery_Time__c == null) {
                        deliveryDate = Datetime.newInstance(yno, mno, dno);
                    } else {
                        Integer hhno = Integer.valueOf(dl.Planned_delivery_Time__c.substring(0,2));
                        Integer mmno = Integer.valueOf(dl.Planned_delivery_Time__c.substring(3,5));
                        Integer ssno = Integer.valueOf(dl.Planned_delivery_Time__c.substring(6,8));
                        deliveryDate = Datetime.newInstance(yno, mno, dno, hhno, mmno, ssno);
                    }
                }
                String name = dl.Dispatch_ID__c + '-';
                If (dl.Delivery_Name__c == null) {
                    if (dl.Customer_Name__c.length() > 60) {
                        name += dl.Customer_Name__c.substring(0,60)+'-'+String.valueOf(dl.Dispatch_Date__c);
                    } else {
                        name += dl.Customer_Name__c+'-'+String.valueOf(dl.Dispatch_Date__c);
                    }
                } else {
                    if (dl.Delivery_Name__c.length() > 60) {
                        name += dl.Delivery_Name__c.substring(0,60)+'-'+String.valueOf(dl.Dispatch_Date__c);
                    } else {
                        name += dl.Delivery_Name__c+'-'+String.valueOf(dl.Dispatch_Date__c);
                    }
                }

                Dispatch__c du = new Dispatch__c(
                    Name = name,
                    Customer__r = acct,
                    Month__r = mth,
                    Bottle__r = prod,
                    SAP_Material_Code__r = material,
                    Forecast__r = fcast,
                    Haulier__r = haulier,
                    Type__c = dl.Type__c,
                    Delivery_Code__c = dl.Delivery_Code__c,
                    Dispatch_ID__c = dl.Dispatch_ID__c,
                    Unique_ID__c = dl.Unique_ID__c,
                    Dispatch_Date__c = dl.Dispatch_Date__c,
                    Dispatch_Time__c = dl.Dispatch_Time__c,
                    Dispatch_Date_Time__c = dispatchDateTime,
                    Planned_Delivery_Date__c = deliveryDate,
                    Site_ID__c = dl.Site_ID__c,
                    Warehouse_ID__c = dl.Warehouse_ID__c,
                    Freight_Reference__c = dl.Freight_Reference__c,
                    Pack_Specification__c = dl.Pack_Specification__c,
                    Units__c = dl.Units__c,
                    Tonnage__c = dl.Tonnage__c,
                    Load_Job_Id__c = jobId,
                    Staging_Id__c = dl.Id,
                    Week__c = dl.Week__c,
                    Week_in_Month__c = dl.Week_in_Month__c
                );
                dispatchUpsertMap.put(dl.Unique_ID__c, du);
            }

        }
        system.debug('prodUpsertMap: '+prodUpsertMap);
        system.debug('materialUpsertMap: '+materialUpsertMap);
        system.debug('haulierInsertMap: '+haulierInsertMap);
        system.debug('monthUpsertMap: '+monthUpsertMap);
        system.debug('forecastUpsertMap: '+forecastUpsertMap);

        if (prodUpsertMap.size() > 0) {
            upsert prodUpsertMap.values() Bottle_Identifier__c;
        }

        // M.Witchalls May 2018
        if (materialUpsertMap.size() > 0) {
            List<Database.UpsertResult> mcresults = Database.upsert(materialUpsertMap.values(), false);
            for(Database.UpsertResult r: mcresults) {
                if(!r.isSuccess()) {
                    system.debug('SAP Material Code Upsert Error: '+ r.getErrors()[0].getMessage());
                }
            }
        }
        if (haulierInsertMap.size() > 0) insert haulierInsertMap.values();
        if (monthUpsertMap.size() > 0) {
            List<Database.UpsertResult> mresults = Database.upsert(monthUpsertMap.values(), false);
            for(Database.UpsertResult r: mresults) {
                if(!r.isSuccess()) {
                    system.debug('Month Upsert Error: '+ r.getErrors()[0].getMessage());
                }
            }
        }
        if (forecastUpsertMap.size() > 0) {
            List<Database.UpsertResult> fresults = Database.upsert(forecastUpsertMap.values(), false);
            for(Database.UpsertResult r: fresults) {
                if(!r.isSuccess()) {
                    system.debug('Forecast Upsert Error: '+ r.getErrors()[0].getMessage());
                }
            }
        }

        List<Database.UpsertResult> results = Database.upsert(dispatchUpsertMap.values(), Dispatch__c.Fields.Unique_ID__c, false);
        for(Integer i=0; i < results.size(); i++) {
            if(!results[i].isSuccess()) {
                Database.UpsertResult r = results[i];
                Dispatch__c du = dispatchUpsertMap.values()[i];
                String uniqueId = du.Unique_ID__c;
                Dispatch_Staging__c dl = dispatchLoadMap.get(uniqueId);
                dl.Process_Status__c = ERROR_STATUS;
                dl.Process_Error__c = r.getErrors()[0].getMessage();
                for (Integer j=1; j < r.getErrors().size(); j++) dl.Process_Error__c += ';'+ r.getErrors()[j].getMessage();
                dl.Process_Error__c += '\n';
                System.debug('Dispatch Load Error Record ' + uniqueId + ': Customer '+ dl.Encirc_Account_Number__c + ' Error: ' + dl.Process_Error__c);
                errorWarningCount++;
            }
        }

        update dispatchLoadMap.values();
    }

    // This method defines logic that will be run once, after the last iteration of execute() has completed
    global void finish(Database.BatchableContext dbc){
        if (jobId != null) {
            Map<String, ID> groupMap = new Map<String, ID>();
            for (Group g: [select Id, DeveloperName from Group where DeveloperName in (:systemAdminGroup,:dcRecipientGroup,:otifRecipientGroup)]) {
                groupMap.put(g.DeveloperName, g.Id);
            }
            List<GroupMember> adminUserList = new List<GroupMember>();
            List<GroupMember> dcList = new List<GroupMember>();
            List<GroupMember> otifList = new List<GroupMember>();
            ID adminGroupId = groupMap.get(systemAdminGroup);
            ID dcGroupId = groupMap.get(dcRecipientGroup);
            ID otifGroupId = groupMap.get(otifRecipientGroup);
            if (adminGroupId != null) adminUserList = [select UserOrGroupId from GroupMember where GroupId = :adminGroupId];
            if (dcGroupId != null) dcList = [select UserOrGroupId from GroupMember where GroupId = :dcGroupId];
            if (otifGroupId != null) otifList = [select UserOrGroupId from GroupMember where GroupId = :otifGroupId];

            // Error Messages Email to up to 10 System Administrators
            if (adminUserList.size() > 0) {
                List<Dispatch_Staging__c> errorList = new List<Dispatch_Staging__c>();
                AsyncApexJob a = [
                    SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
                    FROM AsyncApexJob
                    WHERE Id = :jobId
                ];
                if (errorWarningCount > 0) {
                    errorList = [
                        SELECT
                            Id, Dispatch_ID__c, Unique_ID__c, Dispatch_Date__c, Customer_Name__c, Encirc_Account_Number__c,
                            Process_Status__c, Process_Error__c, Process_Date__c
                        FROM
                            Dispatch_Staging__c
                        WHERE
                            Process_Job__c = :jobId AND Process_Status__c != :SUCCESS_STATUS LIMIT 500
                    ];
                }

                String emailBody;
                String emailSubject;
                if (a.NumberOfErrors == 0 && errorWarningCount == 0) {
                    emailSubject = 'Dispatch Batch Run '+jobId+' '+System.now();
                    emailBody = 'Dispatch Batch Run completed successfully at '+System.now() + '\n';
                } else {
                    emailSubject = 'Dispatch Batch Run '+jobId+' '+System.now()+ ' WITH WARNINGS/ERRORS';
                    emailBody = 'Dispatch Batch Run finished with Warnings/Errors at '+System.now() + '\n';
                }
                for (Dispatch_Staging__c de: errorList) {
                    emailBody += '\n' + de.Unique_ID__c + ': Customer '+ de.Encirc_Account_Number__c + ' ' +de.Process_Status__c + ': ' + de.Process_Error__c;
                }
                if (errorList.size() > 200) emailBody += '\n...';
                emailBody += '\n-----------------------------------------------------------------------------------------------------------\n';
                emailBody += 'Daily Comparative Email Count: '+dcList.size() + '\n';
                emailBody += 'OTIF Email Count: '+otifList.size() + '\n';
                system.debug('@@ emailBody: '+emailBody);

                Integer numberOfEmails = 0;
                for (GroupMember adminUser: adminUserList) {
                    if (adminUser.UserOrGroupId.getSObjectType() == User.SObjectType) {
                        numberOfEmails++;
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTargetObjectId(adminUser.UserOrGroupId);
                        mail.setSaveAsActivity(false);
                        mail.setSubject(emailSubject);
                        mail.setPlainTextBody(emailBody);
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                    }
                    if (numberOfEmails == 10) break;
                }

            }

            // DC Comparatives Email
            List<emailTemplate> templateList = [select Id from EmailTemplate where DeveloperName = :dcEmailTemplateName];
            ID emailTemplateId = (templateList.size() > 0) ? templateList[0].Id : null;

            // Send up to 10 emails at a time asynchronously using a schedulable job
            List<ID> dcUserIdList = new List<ID>();
            if (emailTemplateId != null && dcList.size() > 0) {
                system.debug('emailTemplateId: '+emailTemplateId);

                for(GroupMember recipient :dcList) {
                    if (recipient.UserOrGroupId.getSObjectType() == User.SObjectType) {
                        dcUserIdList.add(recipient.UserOrGroupId);
                    }
                }
                if (dcUserIdList.size() > 0) {
                    Datetime dt = System.now().addSeconds(60);
                    String cronExp = '' + dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
                    String strJobName = 'DCEmailSend-' + dt.year() + '-' + dt.month() + '-' + dt.day() + '-' + dt.hour() + '-' + dt.minute();

                    EmailSendSchedulable dcJob = new EmailSendSchedulable(emailTemplateId, dcUserIdList);
                    if (!Test.isRunningTest()) String jobID = system.schedule(strJobName, cronExp, dcJob);
                }

            }

            // OTIF Email
            templateList = [select Id from EmailTemplate where DeveloperName = :otifEmailTemplateName];
            emailTemplateId = (templateList.size() > 0) ? templateList[0].Id : null;

            // Send up to 10 emails at a time asynchronously using a schedulable job
            List<ID> otifUserIdList = new List<ID>();
            if (emailTemplateId != null && otifList.size() > 0) {
                system.debug('emailTemplateId: '+emailTemplateId);

                for(GroupMember recipient :otifList) {
                    if (recipient.UserOrGroupId.getSObjectType() == User.SObjectType) {
                        otifUserIdList.add(recipient.UserOrGroupId);
                    }
                }
                if (otifUserIdList.size() > 0) {
                    //Extension - new scheduled time for email to be sent - Email notification scheduled - 8:00 AM Mon-Fri
                    Datetime dtSch = System.now();
                    Date dateSch = dtSch.date();
                    
                    //Calculate index of current day of the week
                    Date weekStart = dateSch.toStartofWeek();
                    integer indexDay = weekStart.daysBetween(dateSch);
                    
                    //Add the delay in seconds after the DispatchLoadBatch executed
                    dtSch = dtSch.addSeconds(delaySeconds);
                    String cronExp = '' + dtSch.second() + ' ' + dtSch.minute() + ' ' + dtSch.hour() + ' ' + dtSch.day() + ' ' + dtSch.month() + ' ? ' + dtSch.year();
                    String strJobName = 'OTIFEmailSend-' + dtSch.year() + '-' + dtSch.month() + '-' + dtSch.day() + '-' + dtSch.hour() + '-' + dtSch.minute();
                    EmailSendSchedulable otifJob = new EmailSendSchedulable(emailTemplateId, otifUserIdList);
                    
                    //Current Day Mon-Fri
                    if (!Test.isRunningTest() && indexDay < 5) String jobID = system.schedule(strJobName, cronExp, otifJob);
                }

            }

        }
    }

}*/