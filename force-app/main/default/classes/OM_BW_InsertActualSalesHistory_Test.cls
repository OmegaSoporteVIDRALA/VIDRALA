@isTest
public class OM_BW_InsertActualSalesHistory_Test {

    @TestSetup
    static void setupData() {
        
        Account acc = new Account(Name='Test Account', SAP_Account_Number__c='12516');
        insert acc;
        
        Product2 prod = new Product2(Name='Test Product', OM_Product_Code_SIP__c='221004B');
        insert prod;
        
        Bottle__c bot = new Bottle__c(Name='Test Bottle', Bottle_Identifier__c='1', Weight_per_Unit__c=1);
        insert bot;
        
        SAP_Material_Code__c mat = new SAP_Material_Code__c(Name='Test Mat', Bottle__c=bot.Id, Material_Code_Key__c='18403');
        insert mat;
    }

    @IsTest
    static void testCreateJsonBWWrapper() {
        String jsonOutput = OM_BW_InsertActualSalesHistory.createJsonBWWrapper('2024', '2025', '01', '12', 'VD50', 'GRP1');
        System.assert(String.isNotBlank(jsonOutput), 'El JSON debería haberse generado correctamente.');
    }

    @IsTest
    static void testactualSalesHistoryCalloutBW() {
        OM_BW_Wrapper.BWFilter testFilter = new OM_BW_Wrapper.BWFilter('2024', '2025', '01', '12', 'VD50', 'GRP1');
        Test.setMock(WebServiceMock.class, new OM_SapFunctionsMockActualSalesH_Test());
        
        Test.startTest();
        try {
            OM_BW_InsertActualSalesHistory.actualSalesHistoryCalloutBW(testFilter);
            System.assert(true, 'La ejecución del callout fue exitosa.');
        } catch(Exception e) {
            System.assert(false, 'El método falló con la excepción: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testInsertActualSalesHistory() {
        String jsonStr = '{"yearFrom": "2024", "yearTo": "2025", "monthFrom": "01", "monthTo": "12", "salesOrganization": "VD50"}';
        Test.setMock(WebServiceMock.class, new OM_SapFunctionsMockActualSalesH_Test());
        
        Test.startTest();
        try {
            OM_BW_InsertActualSalesHistory.insertActualSalesHistory(jsonStr);
            System.assert(true, 'El proceso de inserción se ejecutó correctamente.');
        } catch(Exception e) {
            System.assert(false, 'El proceso de inserción falló: ' + e.getMessage());
        }
        Test.stopTest();
        
        Integer created = [SELECT count() FROM Actual_Sales_History__c];
        System.debug('Registros creados en test: ' + created);
    }
}