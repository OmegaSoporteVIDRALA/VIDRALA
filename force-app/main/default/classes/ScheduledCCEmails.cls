/**
 *  Apex class to send email on a specific time period/interval
 *
 *  @author  Globant 
 *  @since   July 2023
 */
public without Sharing class ScheduledCCEmails implements Schedulable {

    private static final String UNKNOWN_PLANT = 'Unknown';
    private static final String ELTON_PLANT = 'Elton';
    private static final String DERRYLIN_PLANT = 'Derrylin';
    private static final String CORSICO_PLANT = 'Corsico';
    
    private static final String CONSUMER_COMPLAINTS_QMS_ELTON_GROUP_MEMBER = 'Consumer_Complaints_QMs_Elton';
    private static final String CONSUMER_COMPLAINTS_QMS_DERRYLIN_GROUP_MEMBER = 'Consumer_Complaints_QMs_Derrylin';
    private static final String CONSUMER_COMPLAINTS_QMS_ITALY_GROUP_MEMBER = 'Consumer_Complaints_QMs_Italy';
    private static final String CONSUMER_COMPLAINTS_ADMIN_GROUP_MEMBER = 'Consumer_Complaints_Admin';
    
    private static final String NO_QM_COMMENTS_EMAIL_TEMPLATE = 'X3_Days_and_no_QM_Comments';
    private static final String X7_WORKING_DAYS_NO_COMPLAINT_EMAIL_TEMPLATE = 'X7_Working_Days_No_Complaint_Types_Report_not_Completed';
    private static final String X7_WORKING_DAYS_ONE_COMPLAINT_EMAIL_TEMPLATE = 'X7_Working_Days_One_Complaint_Type_Report_not_Completed';
    private static final String X15_WORKING_DAYS_ONE_COMPLAINT_EMAIL_TEMPLATE = 'X15_Working_Days_One_Complaint_Type_Independent_analysis_Report_not_Complet';

    static String userPrefix = Schema.SObjectType.User.getKeyPrefix();

    /**
     *  Custom Exception class
     */
    private class ScheduledCCEmailsException extends Exception { }

    /**
     *  This function is used to send email to the selected users 
     * 
     *  @param  SchedulableContext  This parameter is logic to execute the data on a specific time interval - Schedulable Context 
     */
    public void execute(SchedulableContext sc) {

        try {
            
            BusinessHours hours = [
                SELECT ID FROM BusinessHours 
                WHERE IsDefault = true LIMIT 1
            ];
        
            List<Consumer_Complaint__c> complaints = [
                SELECT  Complaint_Type_Confirmed_Date__c, Sample_Arrived__c, 
                Manufacturing_Fault_Present__c, Legal__c, Injury__c, Plant__c,
                Quality_Managers_Comments__c, Report_Complete__c, Independent_Analysis__c, CreatedDate
                FROM Consumer_Complaint__c 
                WHERE Complaint_Type_Confirmed_Date__c = LAST_N_DAYS:10 OR Sample_Arrived__c = LAST_N_DAYS:30
            ];
            
            setupEmails(calculateWorkDays(complaints, hours));
        } catch (Exception ex) {
            
            throw new ScheduledCCEmailsException(ex.getMessage());
        }
    }

    /**
     *  This function is used to send email
     * 
     *  @param  consumerComplaintMapByDays  This parameter is map of the Consumer Complaint by number of days
     */
    @TestVisible
    private static void setupEmails(Map<Integer, List<Consumer_Complaint__c>> consumerComplaintMapByDays) {

        if (!consumerComplaintMapByDays.containsKey(3) 
            && !consumerComplaintMapByDays.containsKey(7) 
            && !consumerComplaintMapByDays.containsKey(15)) {
            
            return;
        }

        Map<String, Map<Id, GroupMember>> groupMemberMapByDeveloperName = getGroupMembersMapByDeveloperName();
        Map<String, EmailTemplate> emailTemplateMapByDeveloperName = getEmailTemplateMapByDeveloperName();
        List<GroupMember> ccAdmin = groupMemberMapByDeveloperName.get(CONSUMER_COMPLAINTS_ADMIN_GROUP_MEMBER).values();
        Map<String, List<GroupMember>> groupMembersByPlantMap =  createGroupMembersByPlantMap(groupMemberMapByDeveloperName);

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        // 3 work days after Complaint_Type_Confirmed_Date__c emails
        if (consumerComplaintMapByDays.containsKey(3)) {

            List<GroupMember> groupMembers = new List<GroupMember>();

            EmailTemplate noQMComments = emailTemplateMapByDeveloperName.get(NO_QM_COMMENTS_EMAIL_TEMPLATE);

            for (Consumer_Complaint__c cc : consumerComplaintMapByDays.get(3)) {
                
                if (cc.Complaint_Type_Confirmed_Date__c != null && cc.Quality_Managers_Comments__c == null
                    && (cc.Manufacturing_Fault_Present__c == 'Yes' || cc.Legal__c == 'Yes' || cc.Injury__c == 'Yes')
                    && String.isNotBlank(cc.Plant__c) && groupMembersByPlantMap.containsKey(cc.Plant__c)) {
                    
                    groupMembers = groupMembersByPlantMap.get(cc.Plant__c);

                    mails.addAll(
                        addEmailToStoredEmailTemplate(
                            groupMembers,
                            noQMComments.Id, 
                            cc
                        )
                    );
                }
            }
        }

        // 7 work days after Sample_Arrived__c emails
        if (consumerComplaintMapByDays.containsKey(7)) {
            
            EmailTemplate noComplaintEmailTemplate = emailTemplateMapByDeveloperName.get(X7_WORKING_DAYS_NO_COMPLAINT_EMAIL_TEMPLATE);
            EmailTemplate oneComplaintEmailTemplate = emailTemplateMapByDeveloperName.get(X7_WORKING_DAYS_ONE_COMPLAINT_EMAIL_TEMPLATE);

            for (Consumer_Complaint__c cc : consumerComplaintMapByDays.get(7)) {
                
                Id emailTemplateId;

                if (!cc.Report_Complete__c 
                    && (cc.Manufacturing_Fault_Present__c == 'No' || cc.Manufacturing_Fault_Present__c == null) 
                    && (cc.Legal__c == 'No' || cc.Legal__c == null) 
                    && (cc.Injury__c == 'No' || cc.Injury__c == null)) {
                    
                    emailTemplateId = noComplaintEmailTemplate.Id;
                }

                if (!cc.Report_Complete__c && cc.Independent_Analysis__c == 'No' 
                    && (cc.Manufacturing_Fault_Present__c == 'Yes' || cc.Legal__c == 'Yes' || cc.Injury__c == 'Yes')) {
                    
                    emailTemplateId = oneComplaintEmailTemplate.Id;
                }

                if (emailTemplateId != null) {
                    
                    mails.addAll(
                        addEmailToStoredEmailTemplate(
                            ccAdmin,
                            emailTemplateId, 
                            cc
                        )
                    );
                }
            }
        }

        // 15 work days after Sample_Arrived__c email
        if(consumerComplaintMapByDays.containsKey(15)) {

            EmailTemplate oneComplaint15WorkingDaysEmailTemplate = emailTemplateMapByDeveloperName.get(X15_WORKING_DAYS_ONE_COMPLAINT_EMAIL_TEMPLATE);

            for (Consumer_Complaint__c cc : consumerComplaintMapByDays.get(15)) {

                if (!cc.Report_Complete__c && cc.Independent_Analysis__c == 'Yes' && (cc.Manufacturing_Fault_Present__c == 'Yes' || cc.Legal__c == 'Yes' || cc.Injury__c == 'Yes')) {
                    
                    mails.addAll(
                        addEmailToStoredEmailTemplate(
                            ccAdmin,
                            oneComplaint15WorkingDaysEmailTemplate.Id, 
                            cc
                        )
                    );
                }
            }
        }

        if (mails.size() > 0) {
        
            Messaging.sendEmail(mails);
        }           
    }

    /**
     *  This function is used to get group members by plant 
     * 
     *  @param  groupMemberMapByDeveloperName  This parameter is map of map of the Group members
     *  @return                                It returns map of the group members by plant
     */
    @TestVisible
    private static Map<String, List<GroupMember>> createGroupMembersByPlantMap(Map<String, Map<Id, GroupMember>> groupMemberMapByDeveloperName) {
        
        Map<String, List<GroupMember>> groupMembersByPlantMap = new Map<String, List<GroupMember>> {

            UNKNOWN_PLANT => groupMemberMapByDeveloperName.get(CONSUMER_COMPLAINTS_ADMIN_GROUP_MEMBER).values(),
            ELTON_PLANT => groupMemberMapByDeveloperName.get(CONSUMER_COMPLAINTS_QMS_ELTON_GROUP_MEMBER).values(),
            DERRYLIN_PLANT  => groupMemberMapByDeveloperName.get(CONSUMER_COMPLAINTS_QMS_DERRYLIN_GROUP_MEMBER).values(),
            CORSICO_PLANT => groupMemberMapByDeveloperName.get(CONSUMER_COMPLAINTS_QMS_ITALY_GROUP_MEMBER).values()
        };

        return groupMembersByPlantMap;
    }

    /**
     *  This function is used to get calculated Work Days 
     * 
     *  @param  complaints  This parameter is list of Consumer Complaints
     *  @param  bh          This parameter is Business Hours
     *  @return             It returns map of the Consumer complaints
     */
    @TestVisible
    private static Map<Integer, List<Consumer_Complaint__c>> calculateWorkDays(List<Consumer_Complaint__c> complaints, BusinessHours bh) {
        
        Integer sampleArrivedIsInBusinessHours;
        Integer complaintTypeConfirmedDateIsWithinBusinessHours;
           
        Map<Integer, List<Consumer_Complaint__c>> ccByDays = new Map<Integer, List<Consumer_Complaint__c>>();
        //List to overwrite position 3 of final map, CC by Complaint_Type_Confirmed_Date__c 3 work days ago
        List<Consumer_Complaint__c> ccByConfirmedDate = new List<Consumer_Complaint__c>();

        for (Consumer_Complaint__c cc : complaints) {

            sampleArrivedIsInBusinessHours = ScheduledCCEmails.getNumberOfBusinessDaysByGivenDate(cc.Sample_Arrived__c, 0, bh);
            complaintTypeConfirmedDateIsWithinBusinessHours = ScheduledCCEmails.getNumberOfBusinessDaysByGivenDate(cc.Complaint_Type_Confirmed_Date__c, 0, bh);
            
            
            if (sampleArrivedIsInBusinessHours != null) {
                
                if (!ccByDays.containsKey(sampleArrivedIsInBusinessHours)) {

                    ccByDays.put(sampleArrivedIsInBusinessHours, new List<Consumer_Complaint__c>{cc});
                } else {

                    ccByDays.get(sampleArrivedIsInBusinessHours).add(cc);
                }
            }

            if (complaintTypeConfirmedDateIsWithinBusinessHours != null 
                && complaintTypeConfirmedDateIsWithinBusinessHours == 3) {
                
                ccByConfirmedDate.add(cc);
            }
        }

        if (ccByConfirmedDate.size() > 0) {
        
            ccByDays.put(3, ccByConfirmedDate);
        } else {
        
            ccByDays.remove(3);
        }

        return ccByDays;
    }

    /**
     *  This function is used to get number of business days by given date, with slightly different
     *  logic depending on which type of date is being checked
     * 
     *  @param  initialDate  This parameter is initial Date
     *  @param  count        This parameter is count of business days
     *  @param  bh           This parameter is Business Hours
     *  @return              It returns number of business days by given date
     */
    @TestVisible
    private static Integer getNumberOfBusinessDaysByGivenDate(DateTime initialDate, Integer count, BusinessHours bh) {
        
        if (initialDate == null) {
            
            return null;
        }
        
        DateTime now = ScheduledCCEmails.initiateDateTimeWith9PM();

        if (initialDate.hour() < 8) {
        
            initialDate = initialDate.addHours(8);
        }
    
        if (initialDate.hour() > 18) {
        
            initialDate = initialDate.addHours(-6);
        }
    
        while (initialDate <= now) {
    
            if (BusinessHours.isWithin(bh.Id, initialDate)) {
                
                count++;
            }
            
            initialDate = initialDate.addDays(1);
        }

        return count;
    }

    /**
     *  This function is used to get an initialize date time (Today 9PM)
     * 
     *  @return  It returns initial date time
     */
    @TestVisible
    private static DateTime initiateDateTimeWith9PM() {
        
        DateTime now = System.now();
        return DateTime.newInstance(now.year(), now.month(), now.day(), 21, 00, 0);
    }

    /**
     *  This function is used to add email to stored email template object
     * 
     *  @param  members         This parameter is group members
     *  @param  noQMCommentsId  This parameter is email template Id
     *  @param  cc              This parameter is consumer complaints records
     *  @return                 It returns list of SingleEmailMessage object
     */
    @TestVisible
    private static List<Messaging.SingleEmailMessage> addEmailToStoredEmailTemplate(List<GroupMember> members, Id noQMCommentsId, Consumer_Complaint__c cc) {
        
        Messaging.SingleEmailMessage mail;
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        for (GroupMember member : members) {
                            
            if (((String) member.UserOrGroupId).startsWith(userPrefix)) {
               
                mail = Messaging.renderStoredEmailTemplate(noQMCommentsId, member.UserOrGroupId, cc.Id);
                mail.setSaveAsActivity(false);
                mails.add(mail);
            }
        }

        return mails;
    }

    /**
     *  This function is used to get list of the required email templates 
     * 
     *  @return  It returns map of the Email Templates
     */
    @TestVisible
    private static Map<String, EmailTemplate> getEmailTemplateMapByDeveloperName() {
        
        Map<String, EmailTemplate> resultMap = new Map<String, EmailTemplate>();

        // Developer names to query
        List<String> developerNames = new List<String>{
            NO_QM_COMMENTS_EMAIL_TEMPLATE,
            X7_WORKING_DAYS_NO_COMPLAINT_EMAIL_TEMPLATE,
            X7_WORKING_DAYS_ONE_COMPLAINT_EMAIL_TEMPLATE,
            X15_WORKING_DAYS_ONE_COMPLAINT_EMAIL_TEMPLATE
        };

        List<EmailTemplate> emailTemplates = [
            SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body
            FROM EmailTemplate
            WHERE DeveloperName IN :developerNames
        ];

        // Organize the emailTemplates in the resultMap
        for (EmailTemplate template : emailTemplates) {

            resultMap.put(template.DeveloperName, template);
        }

        return resultMap;
    }

    /**
     *  This function is used to get the required list of group members 
     * 
     *  @return  It returns map of map of group members
     */
    @TestVisible
    private static Map<String, Map<Id, GroupMember>> getGroupMembersMapByDeveloperName() {
        
        Map<String, Map<Id, GroupMember>> resultMap = new Map<String, Map<Id, GroupMember>>();

        // Developer names to query
        List<String> developerNames = new List<String>{
            CONSUMER_COMPLAINTS_QMS_ELTON_GROUP_MEMBER, 
            CONSUMER_COMPLAINTS_QMS_DERRYLIN_GROUP_MEMBER, 
            CONSUMER_COMPLAINTS_QMS_ITALY_GROUP_MEMBER,
            CONSUMER_COMPLAINTS_ADMIN_GROUP_MEMBER
        };

        List<GroupMember> groupMembers = [
            SELECT Id, GroupId, UserOrGroupId, Group.DeveloperName
            FROM GroupMember
            WHERE Group.DeveloperName IN :developerNames
        ];

        // Organize the groupMembers in the resultMap
        for (GroupMember gm : groupMembers) {

            String developerName = gm.Group.DeveloperName;

            if (!resultMap.containsKey(developerName)) {

                resultMap.put(developerName, new Map<Id, GroupMember>());
            }

            resultMap.get(developerName).put(gm.Id, gm);
        }

        return resultMap;
    }
}