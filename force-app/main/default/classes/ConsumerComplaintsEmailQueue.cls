/* -----------------------------------------------------------------------------------------------------------------------
   Name:        ConsumerComplaintsEmailQueue.cls
   Description: Queueable class to handle sending emails related to consumer complaints to the appropriate users and groups.
                   
   Date         Version Author    Summary of Changes
   -----------  ------- --------- ------------------------------------------------------------------------------
   Sep 2024     1.0     Globant   Initial Release
----------------------------------------------------------------------------------------------------------------------- */

public with sharing class ConsumerComplaintsEmailQueue implements Queueable {
    private Map<String, List<Consumer_Complaint__c>> ccs;
    private static final String USER_PREFIX = Schema.SObjectType.User.getKeyPrefix();

    public ConsumerComplaintsEmailQueue(Map<String, List<Consumer_Complaint__c>> applicable) {
        this.ccs = applicable;
    }

    public void execute(QueueableContext qc) {
        sendEmails();
    }

    public void sendEmails() {
        if (ccs == null || ccs.isEmpty()) {
            return;
        }

        Map<String, EmailTemplate> templates = getEmailTemplates(new Set<String>{'QM_asked_to_complete_QM_Comments', 'QD_AM_informed_about_complaint'});
        Map<String, List<GroupMember>> groupMembers = getGroupMembers(new Set<String>{
            'Consumer_Complaints_QD_AM', 
            'Consumer_Complaints_Admin', 
            'Consumer_Complaints_QMs_Elton', 
            'Consumer_Complaints_QMs_Derrylin', 
            'Consumer_Complaints_QMs_Italy'
        });

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        processComplaintsForType('QD_AM', templates.get('QD_AM_informed_about_complaint'), groupMembers.get('Consumer_Complaints_QD_AM'), mails);

        processComplaintsForType('QM_Unk', templates.get('QM_asked_to_complete_QM_Comments'), groupMembers.get('Consumer_Complaints_Admin'), mails);
        processComplaintsForType('QM_Elt', templates.get('QM_asked_to_complete_QM_Comments'), groupMembers.get('Consumer_Complaints_QMs_Elton'), mails);
        processComplaintsForType('QM_Der', templates.get('QM_asked_to_complete_QM_Comments'), groupMembers.get('Consumer_Complaints_QMs_Derrylin'), mails);
        processComplaintsForType('QM_Cor', templates.get('QM_asked_to_complete_QM_Comments'), groupMembers.get('Consumer_Complaints_QMs_Italy'), mails);

        if (!mails.isEmpty()) {
            Messaging.sendEmail(mails);
        }
    }

    // Helper method to get email templates
    private Map<String, EmailTemplate> getEmailTemplates(Set<String> templateNames) {
        Map<String, EmailTemplate> templates = new Map<String, EmailTemplate>();
        for (EmailTemplate template : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :templateNames]) {
            templates.put(template.DeveloperName, template);
        }
        return templates;
    }

    private Map<String, List<GroupMember>> getGroupMembers(Set<String> groupNames) {
        Map<String, List<GroupMember>> membersByGroup = new Map<String, List<GroupMember>>();
        for (GroupMember member : [SELECT Group.DeveloperName, UserOrGroupId FROM GroupMember WHERE Group.DeveloperName IN :groupNames]) {
            if (!membersByGroup.containsKey(member.Group.DeveloperName)) {
                membersByGroup.put(member.Group.DeveloperName, new List<GroupMember>());
            }
            membersByGroup.get(member.Group.DeveloperName).add(member);
        }
        return membersByGroup;
    }

    private void processComplaintsForType(String complaintType, EmailTemplate template, List<GroupMember> groupMembers, List<Messaging.SingleEmailMessage> mails) {
        if (!ccs.containsKey(complaintType) || ccs.get(complaintType).isEmpty() || template == null) {
            return;
        }

        Map<Id, Id> accountEmailsByCC = new Map<Id, Id>();
        if (complaintType == 'QD_AM') {
            List<Consumer_Complaint__c> complaints = [SELECT Id, Customer__r.OwnerId FROM Consumer_Complaint__c WHERE Id IN :ccs.get(complaintType)];
            for (Consumer_Complaint__c cc : complaints) {
                if (cc.Customer__c != null) {
                    accountEmailsByCC.put(cc.Id, cc.Customer__r.OwnerId);
                }
            }
        }

        for (Consumer_Complaint__c cc : ccs.get(complaintType)) {
            if (accountEmailsByCC.containsKey(cc.Id)) {
                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(template.Id, accountEmailsByCC.get(cc.Id), cc.Id);
                mail.setSaveAsActivity(false);
                mails.add(mail);
            }
            if (groupMembers != null) {
                for (GroupMember member : groupMembers) {
                    if (((String)member.UserOrGroupId).startsWith(USER_PREFIX)) {
                        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(template.Id, member.UserOrGroupId, cc.Id);
                        mail.setSaveAsActivity(false);
                        mails.add(mail);
                    }
                }
            }
        }
    }
}


// TODO remove once it has been tested/validated/QA-ed
/*//Test coverage provided by ConsumerComplaintsHandlerTest

public with sharing class ConsumerComplaintsEmailQueue implements Queueable{

    private Map<String, List<Consumer_Complaint__c>> ccs;

    public ConsumerComplaintsEmailQueue(Map<String, List<Consumer_Complaint__c>> applicable) {
        this.ccs = applicable;
    }

    public void execute(QueueableContext qc) {
        sendEmails();
    }


    public void sendEmails() {        
        
        for(String key : this.ccs.keySet()) {
            System.debug(key + ' -\t' + this.ccs.get(key).size());
        }

        String userPrefix = Schema.SObjectType.User.getKeyPrefix();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        EmailTemplate noQMComments = [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName = 'QM_asked_to_complete_QM_Comments'];
        EmailTemplate amInformed = [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName = 'QD_AM_informed_about_complaint'];

        List<Consumer_Complaint__c> accLst = [SELECT Id, Customer__r.OwnerId FROM Consumer_Complaint__c WHERE Id IN :this.ccs.get('QD_AM')];
        Map<Id, Id> accountEmailsByCC = new Map<Id, Id>();
        for(Consumer_Complaint__c cc : accLst) {
            if(cc.Customer__c != null) {
                accountEmailsByCC.put(cc.Id, cc.Customer__r.OwnerId);
            }
        }

        List<GroupMember> ccQdAm        = [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Consumer_Complaints_QD_AM'];
        for(Consumer_Complaint__c cc : this.ccs.get('QD_AM')) {
            if(accountEmailsByCC.get(cc.Id) != null) {
                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(amInformed.Id, accountEmailsByCC.get(cc.Id), cc.Id);
                mail.setSaveAsActivity(false);
                //mail.setToAddresses(new String [] {'franz.mayenberger@cloudshiftgroup.com'});
                mails.add(mail);
            }
            for(GroupMember member : ccQdAm) {
                if(((String)member.UserOrGroupId).startsWith(userPrefix)) {
                    Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(amInformed.Id, member.UserOrGroupId, cc.Id);
                    mail.setSaveAsActivity(false);
                    //mail.setToAddresses(new String [] {'franz.mayenberger@cloudshiftgroup.com'});
                    mails.add(mail);
                }
            }
        }

        if(this.ccs.get('QM_Unk').size() > 0) {
            List<GroupMember> ccAdmin       = [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Consumer_Complaints_Admin'];

            for(Consumer_Complaint__c cc : this.ccs.get('QM_Unk')) {
                for(GroupMember member : ccAdmin) {
                    if(((String)member.UserOrGroupId).startsWith(userPrefix)) {
                        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(noQMComments.Id, member.UserOrGroupId, cc.Id);
                        mail.setSaveAsActivity(false);
                        //mail.setToAddresses(new String [] {'franz.mayenberger@cloudshiftgroup.com'});
                        mails.add(mail);
                    }
                }
            }
        }
        if(this.ccs.get('QM_Elt').size() > 0) {
            List<GroupMember> ccElton       = [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Consumer_Complaints_QMs_Elton'];

            for(Consumer_Complaint__c cc : this.ccs.get('QM_Elt')) {
                for(GroupMember member : ccElton) {
                    if(((String)member.UserOrGroupId).startsWith(userPrefix)) {
                        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(noQMComments.Id, member.UserOrGroupId, cc.Id);
                        mail.setSaveAsActivity(false);
                        //mail.setToAddresses(new String [] {'franz.mayenberger@cloudshiftgroup.com'});
                        mails.add(mail);
                    }
                }
            }
        }
        if(this.ccs.get('QM_Der').size() > 0) {
            List<GroupMember> ccDerrylin    = [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Consumer_Complaints_QMs_Derrylin'];

            for(Consumer_Complaint__c cc : this.ccs.get('QM_Der')) {
                for(GroupMember member : ccDerrylin) {
                    if(((String)member.UserOrGroupId).startsWith(userPrefix)) {
                        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(noQMComments.Id, member.UserOrGroupId, cc.Id);
                        mail.setSaveAsActivity(false);
                        //mail.setToAddresses(new String [] {'franz.mayenberger@cloudshiftgroup.com'});
                        mails.add(mail);
                    }
                }
            }
        }
        if(this.ccs.get('QM_Cor').size() > 0) {
            List<GroupMember> ccCorsico     = [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Consumer_Complaints_QMs_Italy'];

            for(Consumer_Complaint__c cc : this.ccs.get('QM_Cor')) {
                for(GroupMember member : ccCorsico) {
                    if(((String)member.UserOrGroupId).startsWith(userPrefix)) {
                        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(noQMComments.Id, member.UserOrGroupId, cc.Id);
                        mail.setSaveAsActivity(false);
                        //mail.setToAddresses(new String [] {'franz.mayenberger@cloudshiftgroup.com'});
                        mails.add(mail);
                    }
                }
            }
        }

        System.debug(mails);
        System.debug('mails: ' + mails.size());
        if(mails.size() > 0) Messaging.sendEmail(mails);
    }
}*/