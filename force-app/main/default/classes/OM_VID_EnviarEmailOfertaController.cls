/**
* @description       :
* @author            : mmadridp@omegacrmconsulting.com
* @group             :
* @last modified on  : 16-04-2024
* @last modified by  : mmadridp@omegacrmconsulting.com
**/
public without sharing class OM_VID_EnviarEmailOfertaController {
    public static String errorMessage = '';

    @AuraEnabled
    public static String validateErrors(String quoteId){
        try{
            Quote qParam = [SELECT Id, Name, OpportunityId, OM_VID_Idioma__c, ContactId, Opportunity.Name, Opportunity.OM_VID_Idioma__c, Opportunity.OwnerId, Opportunity.Contact__c, Account.Name FROM Quote WHERE Id =: quoteId LIMIT 1];
            //Opportunity opp = [SELECT Id, Contact__c, Name, OM_VID_Idioma__c, OwnerId FROM Opportunity WHERE Id =: qParam.OpportunityId LIMIT 1];
            List<QuoteLineItem> qLineItemList = [SELECT Id, Product2Id, Product2.Name, Product2.Drawing__c FROM QuoteLineItem WHERE QuoteId = :quoteId];
            Set<Id> productIdSet = new Set<Id>();
            String templateName = getTemplateNameFormula(qParam.OM_VID_Idioma__c);

            List<ContentVersion> cvList = new List<ContentVersion>();
            cvList = validateContentVersion(qParam.Id, qParam.Account.Name);
            validateContact(qParam);
            validateLenguage(qParam);
            if(!qLineItemList.isEmpty()){
                for(QuoteLineItem item : qLineItemList){
                    productIdSet.add(item.Product2Id);
                }
                List<ContentVersion> validatedDrawings = new List<ContentVersion>();
                validatedDrawings = validateDrawings(productIdSet, qLineItemList);
                if(validatedDrawings.size() > 0) cvList.addAll(validatedDrawings);
            }else{
                errorMessage += 'No hay líneas de producto en la oferta; ';
            }
            
            System.debug('***está por aqui');


            /*if(!qLineItemList.isEmpty()){
                for(QuoteLineItem item : qLineItemList){
                    if(item.Product2.Drawing__c != null) drawingIdSet.add(item.Product2.Drawing__c);
                }
                cvList.addAll(validateDrawings(drawingIdSet, qLineItemList));
            }*/

            if(errorMessage == null || errorMessage == ''){
                errorMessage = OM_VID_EmailController.sendQuoteEmail(templateName, qParam, cvList);
                if(errorMessage == 'Ok'){
                    qParam.OM_VID_Oferta_Enviada__c = true;
                    qParam.OM_VID_Fecha_de_envio_oferta__c = System.now();

                    update qParam;
                }
            }

        }catch(QueryException ex){
            errorMessage += ex.getMessage();
        }catch(Exception e){
            errorMessage += e.getMessage();
        }

        System.debug('MMP error: ' + errorMessage);
        return errorMessage;
    }

    //validar que haya un contentVersion con el texto oferta cliente
    private static List<ContentVersion> validateContentVersion(String quoteId, String accountName){
        String title = '%'+accountName+'%';
        List<ContentVersion> cvList = new  List<ContentVersion>();
        Set<Id> setCvIds = new Set<Id>();
        List<ContentDocumentLink > cvLinkList = [SELECT Id, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.title, LinkedEntityId FROM ContentDocumentLink where linkedentityid = :quoteId AND ContentDocument.LatestPublishedVersion.title LIKE :title];

        if(cvLinkList.isEmpty()){
            errorMessage += OM_VID_Constants.errorContentVersion + '; ';
        }else{
            for(ContentDocumentLink link : cvLinkList){
                setCvIds.add(link.ContentDocument.LatestPublishedVersionId);
            }

            cvList = [SELECT Id FROM ContentVersion WHERE Id IN :setCvIds];
        }

        return cvList;
    }

    //validar que la Opp asociada a la Quote tenga el Contacto informado
    private static void validateContact(Quote qParam){
        if(qParam.Opportunity.Contact__c == null){
            errorMessage += 'La Oportunidad no tiene Contacto asociado; ';
        }
    }

    //validar que la Opp asociada a la Quote tenga el Idioma informado
    private static void validateLenguage(Quote qParam){
        if(qParam.Opportunity.OM_VID_Idioma__c == null || qParam.Opportunity.OM_VID_Idioma__c == ''){
            errorMessage += 'La Oportunidad no tiene Idioma seleccionado; ';
        }
    }


    //validar que todos los profuctos tengan un drawing correcto
    private static List<ContentVersion> validateDrawings(Set<Id> productIdSet, List<QuoteLineItem> qLineItemList){
        List<ContentVersion> cvList = new  List<ContentVersion>();
        List<Product2> drawingList = [SELECT Id, Name, Drawing__c FROM Product2 WHERE Id IN :productIdSet];
        Set<Id> drawingIdSet = new Set<Id>();
        Set<Id> contentVersionIdSet = new Set<Id>();
        Map<String, ContentDocumentLink> mapDrawingIdContentDocumentLink = new Map<String, ContentDocumentLink>();
        Map<String, Product2> mapProductIdDrawing = new Map<String, Product2>();

        if(!drawingList.isEmpty()){
            for(Product2 prod : drawingList){
                drawingIdSet.add(prod.Drawing__c);
            }
    
            List<ContentDocumentLink> documentLinkList = [SELECT id, LinkedEntityId, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink WHERE LinkedEntityId IN :drawingIdSet];
            
            if(!documentLinkList.isEmpty()){
                for(ContentDocumentLink link : documentLinkList){
                    mapDrawingIdContentDocumentLink.put(link.linkedEntityId, link);
                    contentVersionIdSet.add(link.ContentDocument.LatestPublishedVersionId);
                }

                cvList = [SELECT Id FROM ContentVersion WHERE ID IN :contentVersionIdSet];
        
                for(Product2 prod : drawingList){
                    if(mapDrawingIdContentDocumentLink.get(prod.Drawing__c) != null){
                        mapProductIdDrawing.put(prod.Id, prod);
                    }
                }
    
                for(QuoteLineItem qLine : qLineItemList){
                    System.debug('***entra para: '+qline);
                    System.debug('***entra para: '+qline.Product2Id);
                    if(mapProductIdDrawing.get(qLine.Product2Id) == null){
                        errorMessage += 'El producto ' + qLine.Product2.Name + ' no tiene planos adjuntos; ';
                    }
                }
            }else{
                errorMessage += 'Ninguno de los productos tiene planos adjuntos';
            }
            
        }else{
            errorMessage += 'Ninguno de los productos tiene planos adjuntos';
        }

        /*if(cvList.isEmpty()){
            System.debug('***está por aqui devuelve null ');
            return null;
        }*/

        System.debug('***está por aqui devuelve cvList: '+cvList);
        return cvList;
    }

    @TestVisible
    private static String getTemplateNameFormula(String lenguage){
        String templateName;
        switch on lenguage {
            when  'Español'{
                templateName = 'ES' + OM_VID_Constants.fiftyTemplateName;
            }when  'Francés'{
                templateName = 'FR' + OM_VID_Constants.fiftyTemplateName;
            }when  'Portugués'{
                templateName = 'PT' + OM_VID_Constants.fiftyTemplateName;
            }when else {
                templateName = 'EN' + OM_VID_Constants.fiftyTemplateName;
            }
        }

        return templateName;
    }
}