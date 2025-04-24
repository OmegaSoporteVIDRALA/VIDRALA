/**
* @description       :
* @author            : mmadridp@omegacrmconsulting.com
* @group             :
* @last modified on  : 16-04-2024
* @last modified by  : mmadridp@omegacrmconsulting.com
**/
public with sharing class OM_VID_EmailController {

    /**
     * @author: Manuel Madrid
     * @param: String templateName --> nombre del email template que se va a enviar
     * @param: Quote qParam --> Quote con toda la info necesaria para enviar el email.
     * @param: String cvList --> Lista de los content Version que se van a adjuntar al mail 
     * @description: envía un email a partir de los parámetros relacionados
     * @returns String con un mensaje de error o un Ok
     * @since 08/07/20201
     */ 
    public static String sendQuoteEmail(String templateName, Quote qParam, List<ContentVersion> cvList){
        String errorMessage = '';
        String orgWideAddress = getOrgWideAddressFormula(qParam.OM_VID_Idioma__c);
        
        EmailTemplate et = [SELECT Id, HtmlValue, Body, Subject FROM EmailTemplate WHERE DeveloperName = :templateName];
        
        
        OrgWideEmailAddress owea = [Select id, DisplayName, Address from OrgWideEmailAddress WHERE Address =: orgWideAddress LIMIT 1];

        List<String> ccAddressesList = new List<String>();
        ccAddressesList.add(qParam.Opportunity.OwnerId);
        //String finalBody = et.HtmlValue.remove(']]>');

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setSubject(et.Subject);
        //message.setHtmlBody(et.HtmlValue);
        message.setPlainTextBody(et.Body);
        message.setTargetObjectId(qParam.Opportunity.Contact__c);
        message.setTreatTargetObjectAsRecipient(true);
        message.setTreatBodiesAsTemplate(true);
        message.setCcAddresses(ccAddressesList);
        message.setUseSignature(false);
        message.setBccSender(false);
        message.setSaveAsActivity(true);
        message.setWhatId(qParam.Id);
        message.setOrgWideEmailAddressId(owea.Id);
        System.debug('***esta es la template: '+et.id);
        message.setTemplateID(et.Id);

        if(cvList != null && !cvList.isEmpty()){
            List<String> cvDocIdList = new List<String>();
    
            for(ContentVersion cv : cvList){
                cvDocIdList.add(cv.Id);
            }
    
            if(!cvDocIdList.isEmpty()){
                message.setEntityAttachments(cvDocIdList);
            }
        }

        try{
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};

            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

            for(Messaging.SendEmailError error : results[0].getErrors()){
                errorMessage += error.getMessage();
            }
        
            if (results[0].success){
                errorMessage = 'Ok';
            }

        }catch(Exception ex){
            errorMessage = ex.getMessage();
        }
        
        return errorMessage;
    }
    
    public static String getOrgWideAddressFormula(String lenguage){
        String orgWideAddress;
        switch on lenguage {
            when  'Español'{
                orgWideAddress = 'comercial@vidrala.com';
            }when  'Francés'{
                orgWideAddress = 'commercial@vidrala.com';
            }when  'Portugués'{
                orgWideAddress = 'vendas@vidrala.com';
            }when else {
                orgWideAddress = 'comercial@vidrala.com';
            }
        }

        return orgWideAddress;
    }

}