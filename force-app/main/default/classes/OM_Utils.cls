/*
* @TestedBy: OM_Utils_UT
*/
public without sharing class OM_Utils {
    
    // Varibles to use during execution
    public static Boolean shouldSkipTriggerGlobal = false;  // To Skip All Triggers
    
    // Singleton Pattern
    public static User CurrentUserRecord { get {if (CurrentUserRecord == null || CurrentUserRecord.Id != UserInfo.getUserId()) CurrentUserRecord = [SELECT Id, Name, Profile.Name, UserRole.Name, ProfileId FROM User WHERE Id = :UserInfo.getUserId()]; return CurrentUserRecord;} private set; }
    public static Organization Org { get {if (Org == null) Org = [SELECT Id, IsSandbox FROM Organization]; return Org;} private set; }
	public static String SandboxName {
        get {
            if (SandboxName == null) {
                if (!Org.IsSandbox) {
                    SandboxName = '';
                } else if (Test.isRunningTest()) {
                    SandboxName = 'UNITTESTING';
                } else {
                    System.debug(Url.getOrgDomainUrl().toExternalForm());
                    System.debug(Site.getSiteType());
                    switch on (Site.getSiteType()) {
                        when 'ChatterNetworkPicasso' {
                            SandboxName = Url.getOrgDomainUrl().toExternalForm().substringBetween('https://', '-onecrm--');
                        }
                        when else {
                            SandboxName = Url.getOrgDomainUrl().toExternalForm().substringBetween('https://encirc360--', '.');
                        }
                    }
                    String alternativeForManaged = Url.getOrgDomainUrl().toExternalForm().substringBetween('https://onecrm--', '--');
                    if (alternativeForManaged != null && alternativeForManaged.length() < SandboxName.length())
                        SandboxName = alternativeForManaged;
                    SandboxName = SandboxName.toUpperCase();
                }
            }
            //sandboxName = 'DEV';
            //System.debug(SandboxName);
            return SandboxName;
        }
        private set;
    }

    
    // Classes for utilities
    public static Profiles Profiles { get {if (Profiles == null) Profiles = new Profiles(); return Profiles;} private set; }
    public static RecordTypes RecordTypes { get {if (RecordTypes == null) RecordTypes = new RecordTypes(); return RecordTypes;} private set; }
    public static Strings Strings { get {if (Strings == null) Strings = new Strings(); return Strings;} private set; }
    public static IntegrationMsg IntegrationMsg { get {if (IntegrationMsg == null) IntegrationMsg = new IntegrationMsg(); return IntegrationMsg;} private set; }
    public static DmlResults DmlResults { get {if (DmlResults == null) DmlResults = new DmlResults(); return DmlResults;} private set; }
    
    
    public class Profiles {
        public Profile getProfileIdFromName(String paramValue) {
            return getProfileIdFromName(new Set<String>{paramValue}).values()[0];
        }
        
        public Map<Id, Profile> getProfileIdFromName(Set<String> paramValue) {
            Map<Id, Profile> queryResult = new Map<Id, Profile>([SELECT Id, Name FROM Profile WHERE Name IN :paramValue]);
            
            if(queryResult.isEmpty()){throw new VidralaException('Utils.Profiles - No profile found');}
            System.debug('getProfileIdFromName: ' + JSON.serialize(queryResult));
            return queryResult;
        }
        
        public Map<String, Group> getGroupsByName(){
            Map<String, Group> output = new Map<String, Group>();
            for(Group groupElement : [SELECT Id, Name FROM Group WHERE Type = 'Regular']){
                output.put(groupElement.Name, groupElement);
            }
            System.debug('getGroupsByName: ' + JSON.serialize(output));
            return output;
        }
        
        public Boolean isCurrentUserAdmin(){
			return OM_Utils.CurrentUserRecord.Profile.Name == 'System Administrator';
		}
		
    }

    public class RecordTypes{
        public Id getRecordTypeByDevName(String objectApiName, String rtDevName){
            System.debug('Utils.getRecordTypeByDevName Trying to return: ' + objectApiName + '.' + rtDevName);
        
            Id output = Schema.getGlobalDescribe().get(objectApiName)?.getDescribe().getRecordTypeInfosByDeveloperName()?.get(rtDevName)?.getRecordTypeId();

            if(output != null){ 
                return output; // If we find it with Dev Name, return
            }else{
                // If not, check if by name
                output = Schema.getGlobalDescribe().get(objectApiName)?.getDescribe().getRecordTypeInfosByName()?.get(rtDevName)?.getRecordTypeId();
                if(output != null){
                    return output; // If we find it with Name, return
                }else{
                    throw new VidralaException('No record type found: Object: ' + objectApiName + ' - RecordType Name: ' + rtDevName);
                }
            } 
            
            // return output;
        }
    }
    
    public class Strings {
        public String abbreviate(String paramInput, Integer paramLength) {
            if (paramInput.length() <= paramLength) {
                return paramInput;
            } else {
                return paramInput.left(paramLength - 1) + '…';
            }
        }
        
        // Método para convertir el número de un mes a su nombre abreviado
    	public String getMonthAbbreviation(Integer monthNumber) {
    
            // Array de nombres de meses abreviados --> Se corresponde con el campo Month__c de Actual_Sales_History__c
            List<String> monthNames = new List<String>{
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
            };
    
            // Retornar el mes correspondiente (el índice es monthNumber - 1 porque el array comienza en 0)
            return monthNames[monthNumber - 1]; 
    	}
           
    }
        
        

    public class IntegrationMsg{
        public final String OUTBOUND = 'Outbound', INBOUND = 'Inbound', SUCCESS = 'Success', ERROR = 'Error';
        public IntegrationMessage__c intMsg;

        public void createRESTIntegrationMsg(String paramDirection, String paramEndpoint, String paramMethod){
            this.intMsg = new IntegrationMessage__c();
            this.intMsg.Direction__c = paramDirection;
            this.intMsg.Endpoint__c = '[' + paramMethod + '] - ' + paramEndpoint;
        }
        
        public void createSOAPIntegrationMsg(String paramDirection, String paramEndpoint, String paramMethod){
            this.intMsg = new IntegrationMessage__c();
            this.intMsg.Direction__c = paramDirection;
            this.intMsg.Endpoint__c = paramEndpoint + '.' + paramMethod;
        }

        public void addBody(String paramRequest, String paramResponse){
            this.intMsg.RequestMsg__c = paramRequest;//JSON.serialize(paramRequest);
            this.intMsg.ResponseMsg__c = paramResponse;//JSON.serialize(paramResponse);
        }
        
        public void addBody(String paramRequest){
            this.intMsg.RequestMsg__c = paramRequest;//JSON.serialize(paramRequest);
        }

        public void addResponse(String paramResponse){
            this.intMsg.ResponseMsg__c = paramResponse;//JSON.serialize(paramResponse);
        }

        public void addStatusAndRecord(String paramStatus, String paramSfRecord, String objectName, String sapCode){
            this.intMsg.Status__c = paramStatus;
            this.intMsg.SalesforceRecord__c = paramSfRecord;
            
            System.debug('Integration Msg: ' + JSON.serialize(this));
            
            if(objectName == null && !String.isBlank(paramSfRecord) && (paramSfRecord.length() == 15 || paramSfRecord.length() == 18)){
                switch on ((Id) paramSfRecord).getSObjectType().getDescribe().getName().toUpperCase() {
                    when 'ACCOUNT' {this.intMsg.AccountRef__c = paramSfRecord;}	
                    when 'PRODUCT2' {this.intMsg.ProductRef__c = paramSfRecord;}
                }
            }else if(objectName != null){
                switch on objectName {
                    when 'ACCOUNT' { this.intMsg.AccountRef__r = new Account(SAP_Account_Number__c = paramSfRecord);}
                }
            }
            
            if(sapCode != null) this.intMsg.SAP_Code__c = sapCode;
        }

        public void insertRecord(){
            try{
                insert this.intMsg;
            }catch(DmlException e){
                System.debug('Error during insertion of an Integration Message: ' + e.getMessage() + '\n' + e.getStackTraceString());
            }
            
        }
    }
    
    public class DmlResults{
        // To Do - Merge all methods into only 1

        public Map<String, String> getErrorsMap(Database.DeleteResult[] results, List<SObject> recordsToDML, String identificationField) {
            Map<String, String> saveResults = new Map<String, String>();
            Integer /* recordsOK = 0, */ recordsKO = 0;
            String fieldToIdentifyRecord = !String.isBlank(identificationField) ? identificationField : (recordsToDML[0].getSObjectType().getDescribe().getName() != 'Case' ? 'Name' : 'CaseNumber');
    
            for (Integer index = 0; index < results.size(); index++) {
                String recordId = String.valueOf(recordsToDML.get(index).get(fieldToIdentifyRecord));
                String DML_Result = 'Success';
                if (!results[index].isSuccess()) {
                    DML_Result = 'Error : ' + results[index].getErrors()[0].getFields() + ' - ' + results[index].getErrors()[0].getMessage(); // Usually there're only 1 error per record
                    saveResults.put(recordId, DML_Result);
                    recordsKO++;
                }/*  else {
                    DML_Result = 'Success';
                    recordsOK++;
                }  */
                System.debug('>> Record: ' + recordId + ' - ' + DML_Result);
            }
    
            System.debug('>>>> ' + 'records DeleteResult With Errors: ' + saveResults.size());
            // System.debug('>>>> results OK: ' + recordsOK + ' // KO: ' + recordsKO);
            // System.debug('>>>> errorString ' + recordsKO + ': \n' + errorString);
    
            return saveResults;
        }
        
        public String getErrorsMap(Database.UpsertResult result, SObject recordToDML, String identificationField){
            Map<String, String> aux = getErrorsMap(new List<Database.UpsertResult>{result}, new List<SObject>{recordToDML}, identificationField);
            return aux.isEmpty() ? '' : aux.values()[0]; 
        }

        public Map<String, String> getErrorsMap(Database.UpsertResult[] results, List<SObject> recordsToDML, String identificationField) {
            Map<String, String> saveResults = new Map<String, String>();
            Integer /* recordsOK = 0,  */recordsKO = 0;
            String fieldToIdentifyRecord = !String.isBlank(identificationField) ? identificationField : (recordsToDML[0].getSObjectType().getDescribe().getName() != 'Case' ? 'Name' : 'CaseNumber');
    
            for (Integer index = 0; index < results.size(); index++) {
                String recordId = String.valueOf(recordsToDML.get(index).get(fieldToIdentifyRecord));
                String DML_Result = 'Success';
                if (!results[index].isSuccess()) {
                    DML_Result = 'Error : ' + results[index].getErrors()[0].getFields() + ' - ' + results[index].getErrors()[0].getMessage(); // Usually there're only 1 error per record
                    saveResults.put(recordId, DML_Result);
                    recordsKO++;
                } /* else {
                    DML_Result = 'Success';
                    recordsOK++;
                } */ 
                System.debug('>> Record: ' + recordId + ' - ' + DML_Result);
            }
    
            System.debug('>>>> records UpsertResult With Errors: ' + saveResults.size());
            // System.debug('>>>> results OK: ' + recordsOK + ' // KO: ' + recordsKO);
            // System.debug('>>>> errorString ' + recordsKO + ': \n' + errorString);
    
            return saveResults;
        }
        
        public Map<String, String> getErrorsMap(Database.SaveResult[] results, List<SObject> recordsToDML, String identificationField) {
            System.debug('recordsToDML.get(0): '+recordsToDML.get(0));
            Map<String, String> saveResults = new Map<String, String>();
            Integer /* recordsOK = 0, */ recordsKO = 0;
            String fieldToIdentifyRecord = !String.isBlank(identificationField) ? identificationField : (recordsToDML[0].getSObjectType().getDescribe().getName() != 'Case' ? 'Name' : 'CaseNumber');
    
            for (Integer index = 0; index < results.size(); index++) {
                String recordId = String.valueOf(recordsToDML.get(index).get(fieldToIdentifyRecord));
                String DML_Result = 'Success';
                if (!results[index].isSuccess()) {
                    DML_Result = 'Error : ' + results[index].getErrors()[0].getFields() + ' - ' + results[index].getErrors()[0].getMessage(); // Usually there're only 1 error per record
                    saveResults.put(recordId, DML_Result);
                    recordsKO++;
                } /* else {
                    DML_Result = 'Success';
                    recordsOK++;
                }  */
                System.debug('>> Record: ' + recordId + ' - ' + DML_Result);
            }
    
            System.debug('>>>> records SaveResult With Errors: ' + saveResults.size());
            // System.debug('>>>> results OK: ' + recordsOK + ' // KO: ' + recordsKO);
            // System.debug('>>>> errorString ' + recordsKO + ': \n' + errorString);
    
            return saveResults;
        }
    }
    
    public class FieldTranslations{
        // Mapa con clave compuesta: Objeto|Campo|Valor|Idioma
        public Map<String, String> translationMap;
        
        public void getTranslationMap(){
            this.translationMap = new Map<String, String>();
            for (OM_VID_FieldTranslations__mdt t : [
                SELECT OM_VID_Object__c, OM_VID_FieldName__c, OM_VID_ValueAPIName__c, OM_VID_Language__c, OM_VID_Translation__c
                FROM OM_VID_FieldTranslations__mdt
            ]) {
                String key = generateKey(t.OM_VID_Object__c, t.OM_VID_FieldName__c, t.OM_VID_ValueAPIName__c, t.OM_VID_Language__c);
                this.translationMap.put(key, t.OM_VID_Translation__c);
            }
        }
    
    
        private String generateKey(String objectName, String fieldName, String value, String language) {
             List<String> parts = new List<String>{
                objectName != null ? objectName.toLowerCase() : '',
                fieldName != null ? fieldName.toLowerCase() : '',
                value != null ? value.toLowerCase() : '',
                language != null ? language.toLowerCase() : ''
            };
            return String.join(parts, '|');
        }
    
        //Obtener la traducción para un valor específico
        public String getTranslation(String objectName, String fieldName, String value, String language) {
            String key = generateKey(objectName, fieldName, value, language);
            return this.translationMap.containsKey(key) ? translationMap.get(key) : value; // fallback: devuelve el valor original
        }
    
        //Obtener todas las traducciones para un campo
        public Map<String, String> getTranslationsForField(String objectName, String fieldName, String language) {
            Map<String, String> result = new Map<String, String>();
            for (String key : translationMap.keySet()) {
                List<String> parts = key.split('\\|');
                if (parts.size() == 4 
                    && parts[0] == objectName.toLowerCase() 
                    && parts[1] == fieldName.toLowerCase()
                    && parts[3] == language.toLowerCase()) {
                        result.put(parts[2], translationMap.get(key));
                }
            }
            return result;
        }

    }
    
    public static Date parseSAPDate(String dateString) {
        if (dateString == null || dateString.length() != 8) {
            return null; // Manejo de error si el formato es incorrecto
        }
        
        String formattedDate = dateString.substring(0, 4) + '-' + 
            dateString.substring(4, 6) + '-' + 
            dateString.substring(6, 8);
        
        return Date.valueOf(formattedDate);
    }  

    
    // Exception classes
    public class VidralaException extends Exception {}
}