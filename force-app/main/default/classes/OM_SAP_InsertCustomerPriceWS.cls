@RestResource(urlMapping='/insertCustomerPriceInSf')
global with sharing class OM_SAP_InsertCustomerPriceWS {

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
            respondWithError('Unexpected error', STATUS_BAD_REQUEST,
                new List<String>{e.getMessage(), e.getStackTraceString()},
                MSG_BAD_REQUEST, requestString);
        }
    }

    public static void processRequest(String requestString) {
        List<String> errors = new List<String>();
        Object wrapper;

        // Deserialización dinámica
        try {
            if (requestString.contains('[')) {
                wrapper = (OM_SAP_Wrappers.CustomerOrderWrapper)
                    JSON.deserialize(requestString, OM_SAP_Wrappers.CustomerOrderWrapper.class);
            } else {
                wrapper = (OM_SAP_Wrappers.CustomerOrderWrapperUnique)
                    JSON.deserialize(requestString, OM_SAP_Wrappers.CustomerOrderWrapperUnique.class);
            }
        } catch (Exception e) {
            errors.add('Error during deserialization: ' + e.getMessage());
            respondWithError('Deserialization failed', STATUS_BAD_REQUEST, errors, MSG_BAD_REQUEST, requestString);
            return;
        }

        // Validación de contenido
        if (!isValidWrapper(wrapper)) {
            errors.add('Order is empty or null');
            respondWithError('Invalid payload', STATUS_BAD_REQUEST, errors, MSG_BAD_REQUEST, requestString);
            return;
        }

        // Construcción de Assets
        List<Asset> assetsToUpsert = buildAssetsFromWrapper(wrapper, errors);

        if (!errors.isEmpty()) {
            respondWithError('Validation errors', STATUS_BAD_REQUEST, errors, MSG_BAD_REQUEST, requestString);
            return;
        }

        // Upsert en Salesforce
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.DuplicateRuleHeader.AllowSave = true;
        Database.UpsertResult[] results = Database.upsert(assetsToUpsert, Asset.OM_VID_AccountProductCode__c, false);

        Map<String, String> insertErrors = OM_Utils.DmlResults.getErrorsMap(results, assetsToUpsert, 'OM_VID_AccountProductCode__c');
        if (!insertErrors.isEmpty()) {
            errors.add('Insert errors: ' + JSON.serialize(insertErrors));
        }

        // Respuesta final
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

        RestContext.response.statusCode = (errors == null || errors.isEmpty()) ? 200 : 500;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
    }

    // Método auxiliar para validar wrapper
    private static Boolean isValidWrapper(Object wrapper) {
        if (wrapper instanceof OM_SAP_Wrappers.CustomerOrderWrapper) {
            return ((OM_SAP_Wrappers.CustomerOrderWrapper)wrapper).Order != null &&
                   !((OM_SAP_Wrappers.CustomerOrderWrapper)wrapper).Order.isEmpty();
        } else if (wrapper instanceof OM_SAP_Wrappers.CustomerOrderWrapperUnique) {
            return ((OM_SAP_Wrappers.CustomerOrderWrapperUnique)wrapper).Order != null;
        }
        return false;
    }

    // Método auxiliar para construir Assets
    private static List<Asset> buildAssetsFromWrapper(Object wrapper, List<String> errors) {
        if (wrapper instanceof OM_SAP_Wrappers.CustomerOrderWrapper) {
            return buildAssets(((OM_SAP_Wrappers.CustomerOrderWrapper)wrapper).Order, errors);
        } else {
            return buildAssets(((OM_SAP_Wrappers.CustomerOrderWrapperUnique)wrapper).Order, errors);
        }
    }

    private static List<Asset> buildAssets(List<OM_SAP_Wrappers.CustomerPriceWrapper> orders, List<String> errors) {
        List<Asset> assets = new List<Asset>();
        for (OM_SAP_Wrappers.CustomerPriceWrapper item : orders) {
            assets.add(mapToAsset(item, errors));
        }
        return assets;
    }

    private static List<Asset> buildAssets(OM_SAP_Wrappers.CustomerPriceWrapper order, List<String> errors) {
        List<Asset> assets = new List<Asset>();
        assets.add(mapToAsset(order, errors));
        return assets;
    }

    // Método para mapear un wrapper a Asset
    private static Asset mapToAsset(OM_SAP_Wrappers.CustomerPriceWrapper item, List<String> errors) {
        if (String.isBlank(item.priceCode)) {
            errors.add('Missing priceCode for item: ' + JSON.serialize(item));
        }
        Asset asset = new Asset();
        asset.OM_VID_AccountProductCode__c = item.priceCode;
        asset.Account = new Account(SAP_Account_Number__c = item.customerCode);
        asset.OM_VID_SAP_AccountReference__c = item.customerCode;
        asset.Price_1000__c = item.price;
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
        return asset;
    }

    private static void respondWithError(String msg, String code, List<String> errors, String successMsg, String requestString) {
        SFWS_Response response = createResponse(false, msg, null, code, errors, null, successMsg, requestString);
        RestContext.response.statusCode = Integer.valueOf(code);
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
    }

    private static SFWS_Response createResponse(Boolean status, String msg, String priceId, String code,
                                                List<String> errors, String successMessage, String sapCode, String requestParam) {
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
        OM_Utils.IntegrationMsg.addStatusAndRecord((status ? OM_Utils.IntegrationMsg.SUCCESS : OM_Utils.IntegrationMsg.ERROR),
                                                   respWrapper.sapCode, null, sapCode);
        OM_Utils.IntegrationMsg.insertRecord();
        return respWrapper;
    }
}