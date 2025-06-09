@isTest
public class OM_SAP_InsertCustomerPriceWS_Test {
    
 @isTest
static void testHandlePostRequestSuccess() {
    
     Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customers').getRecordTypeId();
    
   
     Account acc = new Account(
           Name = 'Test Account',
           SAP_Account_Number__c = '300055',
           RecordTypeId = customerRecordTypeId,
           OM_VID_SalesOrganizations__c = 'VD10' 
       );
     insert acc;

    Product2 prod = new Product2(Name = 'Test Product', OM_Product_Code_SIP__c = '2524101T');
    insert prod;

    RestRequest req = new RestRequest();
    req.httpMethod = 'POST';
    req.requestBody = Blob.valueOf('{"priceCode":"0001374742",'
                                     + '"price":250.00,'
                                     + '"customerCode":"300055",'
                                     + '"currencyCode":"EUR",'
                                     + '"productCode":"2524101T",'
                                     + '"installDate":"20250101",'
                                     + '"usageEndDate":"20251231",'
                                     + '"salesOrganization":"VD10"}');
    RestResponse res = new RestResponse();
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    OM_SAP_InsertCustomerPriceWS.handlePostRequest();
    Test.stopTest();
    
    List<Asset> assets = [SELECT Id, Name, OM_VID_AccountProductCode__c, Price_1000__c 
                          FROM Asset WHERE OM_VID_AccountProductCode__c = '0001374742'];
    System.assert(!assets.isEmpty(), 'No se creó ningún Asset con el código proporcionado');
    Asset createdAsset = assets[0];
    System.assertEquals('0001374742', createdAsset.OM_VID_AccountProductCode__c, 'El código del producto no coincide');
	}


    @isTest
    static void testHandlePostRequestError() {
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"priceCode":""}');
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
    
        Test.startTest();
        OM_SAP_InsertCustomerPriceWS.handlePostRequest();
        Test.stopTest();
    
        System.assertEquals(400, RestContext.response.statusCode, 'El código de respuesta debería ser 400 para solicitud errónea');
        OM_SAP_InsertCustomerPriceWS.SFWS_Response response = (OM_SAP_InsertCustomerPriceWS.SFWS_Response) 
            JSON.deserialize(RestContext.response.responseBody.toString(), OM_SAP_InsertCustomerPriceWS.SFWS_Response.class);
        System.assertEquals(false, response.status, 'El estado de la respuesta debería ser falso');
    
        System.assert(!response.salesforceErrors.isEmpty(), 'La lista de errores no debería estar vacía');
        
	}
}