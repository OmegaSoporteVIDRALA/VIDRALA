@RestResource(urlMapping='/upsertCustomerInSf')
global with sharing class OM_SAP_UpsertCustomerWS {
    
    // WRAPPER PARA LA RESPUESTA DEL WS DE SF
    public class SFWS_Response {
        public boolean status;
        public String msg;
        public String accountId;
        public String sapCode;
        public String code;
        public List<String> salesforceErrors;
        public String successMessage;
    }
    
    public static SFWS_Response createResponse(Boolean status, String msg, String accountId, String code, List<String> errors, String successMessage, String sapCode, String requestParam) {
        
        // Generate the response        
        SFWS_Response respWrapper = new SFWS_Response();
        respWrapper.status = status;
        respWrapper.msg = msg;
        respWrapper.accountId = accountId;
        respWrapper.sapCode = sapCode;
        respWrapper.code = code;
        respWrapper.salesforceErrors = errors;
        respWrapper.successMessage = successMessage;

        if(!String.isBlank(accountId) && accountId.startsWith('001')){
            // set the sync status -> yes I know it's a double update, but I don't find any other easy way to do
            OM_Utils.shouldSkipTriggerGlobal = true; // Ignore the triggers in this update to accelerate the execution
            try{
                update new Account(Id = accountId, OM_VID_SyncStatus__c = (status ? 'Sync' : 'Failed'), OM_VID_SyncStamp__c = System.now()); 
            }catch(DmlException e){
                status = false; // Set the failure in the integration record
                respWrapper.salesforceErrors.add('Error setting the Sync Status in the Account record: ' + accountId);
            }
            
            OM_Utils.shouldSkipTriggerGlobal = false;
        }

        // Write the integration Message
        OM_Utils.IntegrationMsg.createRESTIntegrationMsg(OM_Utils.IntegrationMsg.INBOUND, '/upsertCustomerInSf', 'POST');
        OM_Utils.IntegrationMsg.addBody(requestParam, JSON.serialize(respWrapper));
        OM_Utils.IntegrationMsg.addStatusAndRecord((status ? OM_Utils.IntegrationMsg.SUCCESS : OM_Utils.IntegrationMsg.ERROR), accountId, null, sapCode );
        OM_Utils.IntegrationMsg.insertRecord();
        
        return respWrapper;
    }
    
    @HttpPost
    global static void handlePostRequest(){
        // Method to return to SAP always the same kind of response 
        // This will catch any kind of error 
        
        RestRequest req = RestContext.request;
        String requestString = req.requestBody.toString();
        try{
            processRequest(requestString);
        }catch(Exception e){
            RestContext.response.addHeader('Content-Type', 'application/json');
            SFWS_Response responseObj = createResponse(false, 'Error not known', null, '400', new list<String>{e.getMessage(), e.getStackTraceString()}, null, 'Bad request', requestString);
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
            return;
        }
    }
    
    global static void processRequest(String requestString) {
        List<String> salesforceErrors = new List<String>();
        String responseMessage = '';
        String successMessage = 'Upserts operations completed successfully.';
        SFWS_Response responseObj;
        List<String> validRecordTypes = new List<String>{'Z010','Z011','Z018','Z016'};
        List<String> customersToExclude = new List<String>{'300126', '300830', '300130','300660','300827','300038','301021','300829','15987','17380','20380','21366',
            '21470','23927','24974','25628','28505','28561','32083','33034','16592'};

        OM_SAP_Wrappers.CustomerWrapper wrapperInstance;
        try {// Deserialization block
            wrapperInstance = (OM_SAP_Wrappers.CustomerWrapper)JSON.deserialize(requestString, OM_SAP_Wrappers.CustomerWrapper.class);
            System.debug('INBOUND PAYLOAD ' + JSON.serialize(wrapperInstance));
        } catch (Exception e) {
            salesforceErrors.add('Error during deserialization: ' + e.getMessage());
            RestContext.response.statusCode = 400; // Bad Request
            RestContext.response.addHeader('Content-Type', 'application/json');
            responseObj = createResponse(false, responseMessage, null, '400', salesforceErrors, null, 'Bad request', requestString);
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
            return;
        }
        
        List<Account> accountsToUpsert = new List<Account>(); // When reduce technical debt, change this into only 1 record
        
        if(wrapperInstance != null && !String.isBlank(wrapperInstance.customerCode)){
            if((!String.isBlank(wrapperInstance.recordType) && validRecordTypes.contains(wrapperInstance.recordType)) && (wrapperInstance.recordType.equalsIgnoreCase('Z018') ||
              (!customersToExclude.contains(wrapperInstance.customerCode) && !customersToExclude.contains(wrapperInstance.parentCustomer)))){
                  System.debug('***wrapperInstance.customerClass: '+!String.isBlank(wrapperInstance.customerClass));
                  System.debug('***wrapperInstance.customerClass: '+wrapperInstance.customerClass.equalsIgnoreCase('Z4'));
                  System.debug('***wrapperInstance.customerClass: '+wrapperInstance.customerClass);
                  
   
                    /** Start building the account record */
                    Account accountUpsert = new Account();
                    accountUpsert.SAP_Account_Number__c = wrapperInstance.customerCode;
                    accountUpsert.Name = wrapperInstance.customerName;
                    if(!String.isBlank(wrapperInstance.blocked)) accountUpsert.OM_VID_Blocked__c = true; //Si viene un valor es que está bloqueado.
                    if(!String.isBlank(wrapperInstance.parentCustomer) && !wrapperInstance.parentCustomer.replaceFirst('^0+', '').equals(wrapperInstance.customerCode)){
                        accountUpsert.Parent = new Account(SAP_Account_Number__c = wrapperInstance.parentCustomer.replaceFirst('^0+', ''));
                    } 
                    
                    // Address information
                    if (wrapperInstance.address != null) {
                        String billingStreetAux = 
                            (wrapperInstance.address.street  != null ? wrapperInstance.address.street +  '\n' : '');
                        accountUpsert.BillingStreet = OM_Utils.Strings.abbreviate(billingStreetAux, Schema.Account.BillingStreet.getDescribe().getLength());
                        accountUpsert.BillingPostalCode = wrapperInstance.address.postalCode;
                        accountUpsert.BillingCountry = wrapperInstance.address.country;
                        accountUpsert.BillingState = wrapperInstance.address.state;
                        accountUpsert.BillingCity = wrapperInstance.address.city;
                        accountUpsert.BillingLongitude = wrapperInstance.address.coordX;
                        accountUpsert.BillingLatitude = wrapperInstance.address.coordY;
                        
                    }
                    
                    accountUpsert.CIF__c = wrapperInstance.vatNumber;
                    if(!wrapperInstance.nif.equalsIgnoreCase('/') && !wrapperInstance.nif.equalsIgnoreCase('"/\"')) accountUpsert.OM_VID_NIF__c = wrapperInstance.nif; 
                    if(wrapperInstance.phone != null) {
                        accountUpsert.Phone = wrapperInstance.phone; 
                    }
                    
                    if(wrapperInstance.industry != null && !wrapperInstance.industry.equalsIgnoreCase('/')){
                        accountUpsert.OM_VID_Industry__c = wrapperInstance.industry; //METER EN SALES ORGANIZATION
                    }
                    
                     
                    if(wrapperInstance.recordType != null){
                        switch on wrapperInstance.recordType {
                            when 'Z010', 'Z011' {
                                accountUpsert.RecordTypeId = OM_Utils.RecordTypes.getRecordTypeByDevName('Account', 'Customers');
                                //if(!String.isBlank(wrapperInstance.parentCustomer)) accountUpsert.Parent = new Account(SAP_Account_Number__c = wrapperInstance.parentCustomer.replaceFirst('^0+', ''));
                                if(!String.isBlank(wrapperInstance.customerClass) && !wrapperInstance.customerClass.equalsIgnoreCase('Z4')){
                                    accountUpsert.OM_VID_CustomerClass__c = wrapperInstance.customerClass;
                                }else{
                                    salesforceErrors.add('Error with data. Customer class "Z4" is not allowed on Customers: '+ wrapperInstance.customerClass);
                                    RestContext.response.statusCode = 400; // Bad Request
                                    RestContext.response.addHeader('Content-Type', 'application/json');
                                    responseObj = createResponse(false, 'Wrong Data', null, '400', salesforceErrors, null, wrapperInstance.customerCode, requestString);
                                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
                                      
                                }
                            }
                            when 'Z018' {
                                accountUpsert.RecordTypeId = OM_Utils.RecordTypes.getRecordTypeByDevName('Account', 'OM_VID_Destinatario');
                                //if(!String.isBlank(wrapperInstance.parentCustomer)) accountUpsert.Parent = new Account(SAP_Account_Number__c = wrapperInstance.parentCustomer.replaceFirst('^0+', ''));
                            }
                            when 'Z016' {
                                accountUpsert.RecordTypeId = OM_Utils.RecordTypes.getRecordTypeByDevName('Account', 'OM_VID_Grupo');
                            }
                        } 
                        //ZO10, Z011 --> CLIENTE , Z018 --> Destinatario de mercancías, Z016 --> Grupo //Record type distributor lo vamos a meter en cliente (Mirar como afecta)
                    }
                    
                    if(wrapperInstance.creditSegment != null){ 
                        //De momento solo vamos a tratar los creditSegment del array que tengan TerritoryCode = Z001 (Vidrala). Más adelante se cogerán todos y se fragmentarán en los nuevos objetos del modelo de datos
                        for(OM_SAP_Wrappers.CreditSegment crSeg : wrapperInstance.creditSegment){
                            if(crSeg.territoryCode.equalsIgnoreCase('Z001')){
                                if(crSeg.creditLimit != null && crSeg.creditLimit != 0) accountUpsert.Account_Credit_Limit__c = crSeg.creditLimit;//PDTE CAMBIO
                                accountUpsert.OM_VID_ClaseRiesgo__c = crSeg.creditStatus; //Clase de riesgo nuevo campo - mapearlo con el campo de la estructura creditStatus
                                accountUpsert.Credit_Block__c = crSeg.creditBlock;
                            }
                        }
                    }
                    
                    if(wrapperInstance.salesOrganizations != null){ 
                        String salesOrganizations = '';
                        //De momento solo vamos a tratar los valores del elemento de Sales Organization que tenga VD10. Con el nuevo modelado de datos trataremos todos
                        for(OM_SAP_Wrappers.SalesOrganization salesOrg : wrapperInstance.salesOrganizations){
                            if(String.isBlank(salesOrganizations)) salesOrganizations = salesOrg.organizationCode;
                               else salesOrganizations = salesOrganizations + ';'+salesOrg.organizationCode;
                            if(salesOrg.organizationCode.equalsIgnoreCase('VD10')){
                                if(salesOrg.claseABC.equals('99') || salesOrg.claseABC.equals('98')) accountUpsert.ClienteVIP__c = salesOrg.claseABC;
                                if(!String.isBlank(salesOrg.market)){
                                    switch on salesOrg.market {
                                        when 'ES', 'PT', 'FR' {
                                            accountUpsert.Market__c = salesOrg.market;
                                        }
                                        when else {
                                            accountUpsert.Market__c = 'NM';
                                        }
                                    } 
                                }
                                if(salesOrg.financials != null){
                                    accountUpsert.CurrencyIsoCode = salesOrg.financials.currencyCode;
                                    accountUpsert.OM_VID_AgreedTerms__c = salesOrg.financials.agreedTerms; 
                                    accountUpsert.OM_VID_PaymentMethods__c = salesOrg.financials.paymentMethod;
                                }
                                System.debug('***salesOrg.CustomerTeam: '+salesOrg.CustomerTeam);
                                if(salesOrg.customerTeam != null){
                                    if(salesOrg.customerTeam.salesAdmin != null && !String.isBlank(salesOrg.customerTeam.salesAdmin)) accountUpsert.Sales_Admin_Lookup__r = new User(SAP_UserNumber__c = salesOrg.customerTeam.salesAdmin);
                                    if(salesOrg.customerTeam.customerManager != null && !String.isBlank(salesOrg.customerTeam.customerManager)){
                                        accountUpsert.Account_Manager__r = new User(SAP_UserNumber__c = salesOrg.customerTeam.customerManager);
                                        accountUpsert.Owner = new User(SAP_UserNumber__c = salesOrg.customerTeam.customerManager);
                                    }
                                    
                                    if(salesOrg.customerTeam.customerService != null && !String.isBlank(salesOrg.customerTeam.customerService)) accountUpsert.Customer_Service__r = new User(SAP_UserNumber__c = salesOrg.customerTeam.customerService);
                                    if(salesOrg.customerTeam.salesOffice != null && !String.isBlank(salesOrg.customerTeam.salesOffice)) accountUpsert.Sales_Office__r = new User(SAP_UserNumber__c = salesOrg.customerTeam.salesOffice);
                                }                    
                            }
                        }
                        
                        if(!String.isBlank(salesOrganizations)) accountUpsert.OM_VID_SalesOrganizations__c = salesOrganizations; 
                    }
        
                    accountsToUpsert.add(accountUpsert);
                    // Upsert accounts
                    Database.DMLOptions dml = new Database.DMLOptions(); 
                    dml.DuplicateRuleHeader.AllowSave = true;
                    Schema.SObjectField sapCode = Account.SAP_Account_Number__c;
                    Database.UpsertResult[] accountUpsertResults = Database.upsert(accountsToUpsert, sapCode, false); //Database.upsert(accountsToUpsert, f, false); 
                    Map<String, String> upsertErrors = OM_Utils.DmlResults.getErrorsMap(accountUpsertResults, accountsToUpsert, 'SAP_Account_Number__c');
        
                    if(!upsertErrors.isEmpty()){ // manage the errors
                        salesforceErrors.add('Exception trying to upsert Account: ' + JSON.serialize(upsertErrors));
                    }else{ // If no errors for accounts, we can continue with the junction records
                        /** Start building the account SalesArea Junction record */
                        
                        /** End building the account SalesArea Junction record */
                        
                    }
                    /** End building the account record */
        
                    // Determine response based on errors
                    if (salesforceErrors.isEmpty()) {
                        RestContext.response.statusCode = 200;
                        responseObj = createResponse(true, responseMessage, !accountsToUpsert.isEmpty() ? accountsToUpsert.get(0).Id : null, '200', salesforceErrors, successMessage, wrapperInstance.customerCode, requestString);
                        // RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
                    } else {
                        RestContext.response.statusCode = 500;
                        responseObj = createResponse(false, responseMessage, !accountsToUpsert.isEmpty() ? accountsToUpsert.get(0).Id : null, '500', salesforceErrors, null, wrapperInstance.customerCode, requestString);
                        
                    }
        
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
                    RestContext.response.addHeader('Content-Type', 'application/json');
                  
                  
            }else{
                salesforceErrors.add('Error with data. RecordType is empty or doesn\'t match the record type value list (Z010, Z011, Z016, Z018), or the customer belongs to the customer exclusion list: ' + wrapperInstance.recordType + ' - '+wrapperInstance.customerCode);
                RestContext.response.statusCode = 400; // Bad Request
                RestContext.response.addHeader('Content-Type', 'application/json');
                responseObj = createResponse(false, 'Wrong Data', null, '400', salesforceErrors, null, wrapperInstance.customerCode, requestString);
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
            }

        }else{
            salesforceErrors.add('Error with data. Customer code is empty or doesn\'t match the expected format ' + wrapperInstance.customerCode);
            RestContext.response.statusCode = 400; // Bad Request
            RestContext.response.addHeader('Content-Type', 'application/json');
            responseObj = createResponse(false, 'Wrong Data', null, '400', salesforceErrors, null, 'Bad request', requestString);
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
        }
    }

}