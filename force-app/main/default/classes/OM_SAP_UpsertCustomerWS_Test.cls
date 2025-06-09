@isTest
public class OM_SAP_UpsertCustomerWS_Test {
    
   @testSetup
    static void makeData() {
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customers').getRecordTypeId();
    
   
     Account acc = new Account(
           Name = 'Test Account',
           SAP_Account_Number__c = '300055',
           RecordTypeId = customerRecordTypeId,
           OM_VID_SalesOrganizations__c = 'VD10' 
       );
     insert acc;

    }
     @isTest
    static void testHandlePostRequestSuccess() {
        // Simula una solicitud HTTP con el cuerpo de la solicitud
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"customerCode":"300076","customerName":"Empresa Ejemplo S.A.","parentCustomer":"0000300055","address":{"street":"18 RUE BOILEAU - CS 70012","postalCode":"33070","city":"BORDEAUX CEDEX","state":"33","country":"FR","coordX":0.000000000000,"coordY":0.000000000000},"vatNumber":"FR86775583248","nif":"","phone":"0557624300","industry":"10","customerClass":"Z1","recordType":"Z016","creditSegment":[{"territoryCode":"Z001","creditLimit":0,"creditStatus":"Z02","creditBlock":false}],"salesOrganizations":[{"organizationCode":"VD50","market":"FR","claseABC":"","financials":{"currencyCode":"EUR","agreedTerms":"ZD","paymentMethod":"AM00"},"customerTeam":{"salesAdmin":"2001719","salesOffice":"2001719"}},{"organizationCode":"VD10","claseABC":"","financials":{"currencyCode":"EUR","agreedTerms":"ZD","paymentMethod":"AM00"},"customerTeam":{}}]}');

        RestResponse res = new RestResponse();

        // Configura el contexto REST
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        OM_SAP_UpsertCustomerWS.handlePostRequest();
        Test.stopTest();

        // Recupera la cuenta creada para validar
        Account createdAccount = [SELECT Id, Name, SAP_Account_Number__c FROM Account WHERE SAP_Account_Number__c = '300076'];
        System.assertEquals('Empresa Ejemplo S.A.', createdAccount.Name, 'El nombre de la cuenta no coincide');
        System.assertEquals('300076', createdAccount.SAP_Account_Number__c, 'El código SAP no coincide');

        // Valida la respuesta HTTP
        System.assertEquals(200, RestContext.response.statusCode, 'Código de respuesta incorrecto');
        OM_SAP_UpsertCustomerWS.SFWS_Response response = (OM_SAP_UpsertCustomerWS.SFWS_Response) JSON.deserialize(RestContext.response.responseBody.toString(), OM_SAP_UpsertCustomerWS.SFWS_Response.class);
        System.assertEquals(true, response.status, 'El estado de la respuesta no es exitoso');
        System.assertNotEquals(null, response.accountId, 'El ID de la cuenta no debe ser nulo');
    }
    
    @isTest
    static void testHandlePostRequestError() {
        // Simula una solicitud HTTP con datos incompletos
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"customerCode": ""}'); // Cuerpo con datos incompletos

        RestResponse res = new RestResponse();

        // Configura el contexto REST
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        OM_SAP_UpsertCustomerWS.handlePostRequest();
        Test.stopTest();

        // Valida el código de respuesta HTTP
        System.assertEquals(400, RestContext.response.statusCode, 'Código de respuesta incorrecto para solicitud errónea');
        OM_SAP_UpsertCustomerWS.SFWS_Response response = (OM_SAP_UpsertCustomerWS.SFWS_Response) JSON.deserialize(RestContext.response.responseBody.toString(), OM_SAP_UpsertCustomerWS.SFWS_Response.class);
        System.assertEquals(false, response.status, 'El estado de la respuesta debería ser falso');
        System.assertNotEquals(null, response.salesforceErrors, 'Debe haber errores en la respuesta');
    }

    @isTest
    static void testHandlePostRequestError2() {
        // Simula una solicitud HTTP sin datos
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(''); // Cuerpo sin datos

        RestResponse res = new RestResponse();

        // Configura el contexto REST
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        OM_SAP_UpsertCustomerWS.handlePostRequest();
        Test.stopTest();

        // Valida el código de respuesta HTTP
        System.assertEquals(400, RestContext.response.statusCode, 'Código de respuesta incorrecto para solicitud errónea');
        OM_SAP_UpsertCustomerWS.SFWS_Response response = (OM_SAP_UpsertCustomerWS.SFWS_Response) JSON.deserialize(RestContext.response.responseBody.toString(), OM_SAP_UpsertCustomerWS.SFWS_Response.class);
        System.assertEquals(false, response.status, 'El estado de la respuesta debería ser falso');
        System.assertNotEquals(null, response.salesforceErrors, 'Debe haber errores en la respuesta');
    }
}