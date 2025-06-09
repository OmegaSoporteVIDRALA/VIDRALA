@RestResource(urlMapping='/insertCustomerPriceInSf')
global with sharing class OM_SAP_InsertCustomerPriceWS {

    // WRAPPER PARA LA RESPUESTA DEL WS DE SF
    public class SFWS_Response {
        public boolean status;
        public String msg;
        public String priceId;
        public String sapCode;
        public String code;
        public List<String> salesforceErrors;
        public String successMessage;
    }
    
    public static SFWS_Response createResponse(Boolean status, String msg, String priceId, String code, List<String> errors, String successMessage, String sapCode, String requestParam) {
        
        // Generate the response        
        SFWS_Response respWrapper = new SFWS_Response();
        respWrapper.status = status;
        respWrapper.msg = msg;
        respWrapper.priceId = priceId;
        respWrapper.sapCode = sapCode;
        respWrapper.code = code;
        respWrapper.salesforceErrors = errors;
        respWrapper.successMessage = successMessage;

        /*if(!String.isBlank(priceId) && priceId.startsWith('001')){
            // set the sync status -> yes I know it's a double update, but I don't find any other easy way to do
            //Utils.shouldSkipTriggerGlobal = true; // Ignore the triggers in this update to accelerate the execution
            try{
                //update new Account(Id = accountId, SyncStatus__c = (status ? 'Sync' : 'Failed'), SyncStamp__c = System.now());
            }catch(DmlException e){
                //status = false; // Set the failure in the integration record
                //respWrapper.salesforceErrors.add('Error setting the Sync Status in the Account/Product record: ' + priceId);
            }
            
            //Utils.shouldSkipTriggerGlobal = false;
        }*/

        // Write the integration Message
        OM_Utils.IntegrationMsg.createRESTIntegrationMsg(OM_Utils.IntegrationMsg.INBOUND, '/insertCustomerPriceInSf', 'POST');
        OM_Utils.IntegrationMsg.addBody(requestParam, JSON.serialize(respWrapper));
        OM_Utils.IntegrationMsg.addStatusAndRecord((status ? OM_Utils.IntegrationMsg.SUCCESS : OM_Utils.IntegrationMsg.ERROR), respWrapper.sapCode, null, sapCode);
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
        String successMessage = 'Insert operations completed successfully.';
        SFWS_Response responseObj;

        OM_SAP_Wrappers.CustomerPriceWrapper wrapperInstance;
        try {// Deserialization block
            wrapperInstance = (OM_SAP_Wrappers.CustomerPriceWrapper)JSON.deserialize(requestString, OM_SAP_Wrappers.CustomerPriceWrapper.class);
            System.debug('INBOUND PAYLOAD ' + JSON.serialize(wrapperInstance));
        } catch (Exception e) {
            salesforceErrors.add('Error during deserialization: ' + e.getMessage());
            RestContext.response.statusCode = 400; // Bad Request
            RestContext.response.addHeader('Content-Type', 'application/json');
            responseObj = createResponse(false, responseMessage, null, '400', salesforceErrors, null, 'Bad request', requestString);
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
            return;
        }
        
        List<Asset> accountProductsToUpsert = new List<Asset>(); // When reduce technical debt, change this into only 1 record

        if(wrapperInstance != null && !String.isBlank(wrapperInstance.priceCode)){
            
            /** Start building the asset record */
            Asset accProductUpsert = new Asset();
            accProductUpsert.OM_VID_AccountProductCode__c = wrapperInstance.priceCode; 
			accProductUpsert.Account = new Account(SAP_Account_Number__c = wrapperInstance.customerCode); 
            accProductUpsert.OM_VID_SAP_AccountReference__c = wrapperInstance.customerCode;
            accProductUpsert.Price_1000__c = wrapperInstance.Price;  
            accProductUpsert.Plant__c = wrapperInstance.plant; //PDTE CONVERTIR EL PICKLIST CON VALORES???
            accProductUpsert.Incoterms__c = wrapperInstance.incoterms;  
			if(!String.isBlank(wrapperInstance.productCode)) accProductUpsert.Product2 = new Product2(OM_Product_Code_SIP__c = wrapperInstance.productCode);  //VER SI USAMOS ESTE O EXTERNAL ID        
			if(!String.isBlank(wrapperInstance.materialCode)) accProductUpsert.OM_VID_Material__r = new SAP_Material_Code__c(Material_Code_Key__c = wrapperInstance.materialCode.replaceFirst('^0+', '')); //SE QUITAN LOS 13 PRIMEROS 0
            accProductUpsert.CurrencyIsoCode = wrapperInstance.currencyCode;  
            accProductUpsert.InstallDate = OM_Utils.parseSAPDate(wrapperInstance.installDate);
            accProductUpsert.Name = wrapperInstance.productCode+' - '+wrapperInstance.salesOrganization+' - '+wrapperInstance.installDate; //PONER EL PRODUCT CODE
            accProductUpsert.UsageEndDate = OM_Utils.parseSAPDate(wrapperInstance.usageEndDate.replace('9999', '3500'));
            accProductUpsert.OM_VID_SalesOrganization__c = wrapperInstance.salesOrganization;
            accountProductsToUpsert.add(accProductUpsert);
            // Upsert accountProducts
            // Upsert accounts
            Database.DMLOptions dml = new Database.DMLOptions(); 
        	dml.DuplicateRuleHeader.AllowSave = true;
            Schema.SObjectField sapCode = Asset.OM_VID_AccountProductCode__c;
            Database.UpsertResult[] accountProductUpsertResults = Database.upsert(accountProductsToUpsert, sapCode, false);
            Map<String, String> insertErrors = OM_Utils.DmlResults.getErrorsMap(accountProductUpsertResults, accountProductsToUpsert, 'OM_VID_AccountProductCode__c');

            if(!insertErrors.isEmpty()){ // manage the errors
                salesforceErrors.add('Exception trying to insert Account Product: ' + JSON.serialize(insertErrors));
            }
            /** End building the account record */

            // Determine response based on errors
            if (salesforceErrors.isEmpty()) {
                RestContext.response.statusCode = 200;
                responseObj = createResponse(true, responseMessage, !accountProductsToUpsert.isEmpty() ? accountProductsToUpsert.get(0).Id : null, '200', salesforceErrors, successMessage, wrapperInstance.priceCode, requestString);
                // RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
            } else {
                RestContext.response.statusCode = 500;
                responseObj = createResponse(false, responseMessage, !accountProductsToUpsert.isEmpty() ? accountProductsToUpsert.get(0).Id : null, '500', salesforceErrors, null, wrapperInstance.priceCode, requestString);
                
            }

            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
            RestContext.response.addHeader('Content-Type', 'application/json');

        }else{
            salesforceErrors.add('Error with data. Price code is empty or doesn\'t match the expected format ' + wrapperInstance.priceCode);
            RestContext.response.statusCode = 400; // Bad Request
            RestContext.response.addHeader('Content-Type', 'application/json');
            responseObj = createResponse(false, 'Wrong Data', null, '400', salesforceErrors, null, 'Bad request', requestString);
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
        }
    }
}