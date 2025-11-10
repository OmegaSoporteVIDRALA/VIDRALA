@RestResource(urlMapping='/insertCustomerPriceInSf')
global with sharing class OM_SAP_InsertCustomerPriceWS {
    
    private static final String CLASS_NAME = OM_SAP_InsertCustomerPriceWS.class.getName();
    private static final String STATUS_BAD_REQUEST = '400';
    private static final String STATUS_SERVER_ERROR = '500';
    private static final String STATUS_SUCCESS = '200';
    private static final String MSG_BAD_REQUEST = 'Bad request';
    private static final String MSG_SUCCESS = 'Insert operations completed successfully.';
    private static final String URLMAPPING = '/insertCustomerPriceInSf';
    private static final String HTTP_POST = 'POST';
    
    public class SFWS_Response {
        public Boolean status;
        public String msg;
        public String priceId;
        public String sapCode;
        public String code;
        public List<String> salesforceErrors;
        public String successMessage;
    }
    
    
    @HttpPost
    global static void handlePostRequest() {
        String requestString = RestContext.request.requestBody.toString();
        try {
            processRequest(requestString);
        } catch (Exception e) {
            respondWithError('Error not known', STATUS_BAD_REQUEST, new List<String>{e.getMessage(), e.getStackTraceString()}, MSG_BAD_REQUEST, requestString);
        }
    }
    
    private static void processRequest(String requestString) {
        List<String> errors = new List<String>();
        OM_SAP_Wrappers.CustomerOrderWrapper wrapper;
        
        try {
            wrapper = (OM_SAP_Wrappers.CustomerOrderWrapper) JSON.deserialize(requestString, OM_SAP_Wrappers.CustomerOrderWrapper.class);
        } catch (Exception e) {
            errors.add('Error during deserialization: ' + e.getMessage());
            respondWithError('Deserialization failed', STATUS_BAD_REQUEST, errors, MSG_BAD_REQUEST, requestString);
            return;
        }
        
        if (wrapper?.order == null || wrapper.order.isEmpty()) {
            errors.add('Order list is empty or null');
            respondWithError('Invalid payload', STATUS_BAD_REQUEST, errors, MSG_BAD_REQUEST, requestString);
            return;
        }
        
        List<Asset> assetsToUpsert = buildAssets(wrapper.order, errors);
        
        if (!errors.isEmpty()) {
            respondWithError('Validation errors', STATUS_BAD_REQUEST, errors, MSG_BAD_REQUEST, requestString);
            return;
        }
        
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.DuplicateRuleHeader.AllowSave = true;
        
        Database.UpsertResult[] results = Database.upsert(assetsToUpsert, Asset.OM_VID_AccountProductCode__c, false);
        Map<String, String> insertErrors = OM_Utils.DmlResults.getErrorsMap(results, assetsToUpsert, 'OM_VID_AccountProductCode__c');
        
        if (!insertErrors.isEmpty()) {
            errors.add('Insert errors: ' + JSON.serialize(insertErrors));
        }
        
        SFWS_Response response = createResponse(
            errors.isEmpty(),
            errors.isEmpty() ? '' : 'Insert failed',
            !assetsToUpsert.isEmpty() ? assetsToUpsert[0].Id : null,
            errors.isEmpty() ? STATUS_SUCCESS : STATUS_SERVER_ERROR,
            errors,
            errors.isEmpty() ? MSG_SUCCESS : null,
            !assetsToUpsert.isEmpty() ? assetsToUpsert[0].OM_VID_AccountProductCode__c : null,
            requestString
        );
        
        RestContext.response.statusCode = errors.isEmpty() ? 200 : 500;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
    }
    
    private static List<Asset> buildAssets(List<OM_SAP_Wrappers.CustomerPriceWrapper> orders, List<String> errors) {
        List<Asset> assets = new List<Asset>();
        for (OM_SAP_Wrappers.CustomerPriceWrapper item : orders) {
            if (String.isBlank(item.priceCode)) {
                errors.add('Missing priceCode for item: ' + JSON.serialize(item));
                continue;
            }
            Asset asset = new Asset();
            asset.OM_VID_AccountProductCode__c = item.priceCode;
            asset.Account = new Account(SAP_Account_Number__c = item.customerCode);
            asset.OM_VID_SAP_AccountReference__c = item.customerCode;
            asset.Price_1000__c = item.Price;
            asset.Plant__c = item.plant;
            asset.Incoterms__c = item.incoterms;
            if (!String.isBlank(item.productCode)) {
                asset.Product2 = new Product2(OM_Product_Code_SIP__c = item.productCode);
            }
            if (!String.isBlank(item.materialCode)) {
                asset.OM_VID_Material__r = new SAP_Material_Code__c(Material_Code_Key__c = item.materialCode.replaceFirst('^0+', ''));
            }
            asset.CurrencyIsoCode = item.currencyCode;
            asset.InstallDate = OM_Utils.parseSAPDate(item.installDate);
            asset.Name = item.productCode + ' - ' + item.salesOrganization + ' - ' + item.installDate;
            asset.UsageEndDate = OM_Utils.parseSAPDate(item.usageEndDate.replace('9999', '3500'));
            asset.OM_VID_SalesOrganization__c = item.salesOrganization;
            assets.add(asset);
        }
        return assets;
    }
    
    private static void respondWithError(String msg, String code, List<String> errors, String successMsg, String requestString) {
        SFWS_Response response = createResponse(false, msg, null, code, errors, null, successMsg, requestString);
        RestContext.response.statusCode = Integer.valueOf(code);
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
    }
    
    private static SFWS_Response createResponse(Boolean status, String msg, String priceId, String code, List<String> errors, String successMessage, String sapCode, String requestParam) {    
        SFWS_Response respWrapper = new SFWS_Response();
        respWrapper.status = status;
        respWrapper.msg = msg;
        respWrapper.priceId = priceId;
        respWrapper.sapCode = sapCode;
        respWrapper.code = code;
        respWrapper.salesforceErrors = errors;
        respWrapper.successMessage = successMessage;
        
        OM_Utils.IntegrationMsg.createRESTIntegrationMsg(OM_Utils.IntegrationMsg.INBOUND, URLMAPPING, HTTP_POST);
        OM_Utils.IntegrationMsg.addBody(requestParam, JSON.serialize(respWrapper));
        OM_Utils.IntegrationMsg.addStatusAndRecord((status ? OM_Utils.IntegrationMsg.SUCCESS : OM_Utils.IntegrationMsg.ERROR), respWrapper.sapCode, null, sapCode);
        OM_Utils.IntegrationMsg.insertRecord();
        
        return respWrapper;
    }
    
    /*global static void processRequest(String requestString) {
        List<String> salesforceErrors = new List<String>();
        String responseMessage = '';
        String successMessage = 'Insert operations completed successfully.';
        SFWS_Response responseObj;
        
        OM_SAP_Wrappers.CustomerOrderWrapper wrapperInstance;
        try {// Deserialization block
            wrapperInstance = (OM_SAP_Wrappers.CustomerOrderWrapper)JSON.deserialize(requestString, OM_SAP_Wrappers.CustomerOrderWrapper.class);
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
        if(wrapperInstance?.order != null || wrapperInstance?.order.isEmpty()){
            for(OM_SAP_Wrappers.CustomerPriceWrapper iter : wrapperInstance.order){
                if(!String.isBlank(iter.priceCode)){
                    Asset accProductUpsert = new Asset();
                    accProductUpsert.OM_VID_AccountProductCode__c = iter.priceCode; 
                    accProductUpsert.Account = new Account(SAP_Account_Number__c = iter.customerCode); 
                    accProductUpsert.OM_VID_SAP_AccountReference__c = iter.customerCode;
                    accProductUpsert.Price_1000__c = iter.Price;  
                    accProductUpsert.Plant__c = iter.plant; //PDTE CONVERTIR EL PICKLIST CON VALORES???
                    accProductUpsert.Incoterms__c = iter.incoterms;  
                    if(!String.isBlank(iter.productCode)) accProductUpsert.Product2 = new Product2(OM_Product_Code_SIP__c = iter.productCode);  //VER SI USAMOS ESTE O EXTERNAL ID        
                    if(!String.isBlank(iter.materialCode)) accProductUpsert.OM_VID_Material__r = new SAP_Material_Code__c(Material_Code_Key__c = iter.materialCode.replaceFirst('^0+', '')); //SE QUITAN LOS 13 PRIMEROS 0
                    accProductUpsert.CurrencyIsoCode = iter.currencyCode;  
                    accProductUpsert.InstallDate = OM_Utils.parseSAPDate(iter.installDate);
                    accProductUpsert.Name = iter.productCode+' - '+iter.salesOrganization+' - '+iter.installDate; //PONER EL PRODUCT CODE
                    accProductUpsert.UsageEndDate = OM_Utils.parseSAPDate(iter.usageEndDate.replace('9999', '3500'));
                    accProductUpsert.OM_VID_SalesOrganization__c = iter.salesOrganization;
                    accountProductsToUpsert.add(accProductUpsert);
                }else{
                    salesforceErrors.add('Error with data. Price code is empty or doesn\'t match the expected format ' + iter.priceCode);
                    RestContext.response.statusCode = 400; // Bad Request
                    RestContext.response.addHeader('Content-Type', 'application/json');
                    responseObj = createResponse(false, 'Wrong Data', null, '400', salesforceErrors, null, 'Bad request', requestString);
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
                }
            }
            
            Database.DMLOptions dml = new Database.DMLOptions(); 
            dml.DuplicateRuleHeader.AllowSave = true;
            Schema.SObjectField sapCode = Asset.OM_VID_AccountProductCode__c;
            Database.UpsertResult[] accountProductUpsertResults = Database.upsert(accountProductsToUpsert, sapCode, false);
            Map<String, String> insertErrors = OM_Utils.DmlResults.getErrorsMap(accountProductUpsertResults, accountProductsToUpsert, 'OM_VID_AccountProductCode__c');
            
            if(!insertErrors.isEmpty()){ // manage the errors
                salesforceErrors.add('Exception trying to insert Account Product: ' + JSON.serialize(insertErrors));
            }
            
            if (salesforceErrors.isEmpty()) {
                RestContext.response.statusCode = 200;
                responseObj = createResponse(true, responseMessage, !accountProductsToUpsert.isEmpty() ? accountProductsToUpsert.get(0).Id : null, '200', salesforceErrors, successMessage, accountProductsToUpsert.get(0).OM_VID_AccountProductCode__c, requestString);
            } else {
                RestContext.response.statusCode = 500;
                responseObj = createResponse(false, responseMessage, !accountProductsToUpsert.isEmpty() ? accountProductsToUpsert.get(0).Id : null, '500', salesforceErrors, null, accountProductsToUpsert.get(0).OM_VID_AccountProductCode__c, requestString);
            }
            
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
            RestContext.response.addHeader('Content-Type', 'application/json');
        }
    }*/
}