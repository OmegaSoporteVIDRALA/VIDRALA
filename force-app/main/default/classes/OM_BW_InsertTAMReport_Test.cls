@isTest
public class OM_BW_InsertTAMReport_Test {

    @TestSetup
    static void setupData() {
        // Datos maestros: Cuenta (12516) y Modelo (1093242M)
        insert new Account(Name='Test Account TAM', SAP_Account_Number__c='12516');
        insert new Product2(Name='Test Model TAM', OM_Product_Code_SIP__c='1093242M');
    }

    @IsTest
    static void testCreateJsonBWWrapper() {
        String jsonOutput = OM_BW_InsertTAMReport.createJsonBWWrapper('2025', '01', 'GRP1');
        System.assert(String.isNotBlank(jsonOutput), 'El JSON debería generarse.');
    }

    @IsTest
    static void testTamCalloutBW() {
        // Test del orquestador
        OM_BW_Wrapper.BWFilter testFilter = new OM_BW_Wrapper.BWFilter('2025', '01', 'GRP1');
        Test.setMock(WebServiceMock.class, new OM_SapFunctionsMockTAM_Test());
        
        Test.startTest();
        try {
            OM_BW_InsertTAMReport.tamCalloutBW(testFilter);
            System.assert(true);
        } catch(Exception e) {
            System.assert(false, 'Falló tamCalloutBW: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testInsertTAM() {
        // Test del método @future con validación de datos
        String jsonStr = '{"yearFrom": "2025", "monthFrom": "01", "salesGroup": "GRP1"}';
        Test.setMock(WebServiceMock.class, new OM_SapFunctionsMockTAM_Test());
        
        Test.startTest();
        OM_BW_InsertTAMReport.insertTAM(jsonStr);
        Test.stopTest();
        
        // VERIFICACIONES FINALES
        List<OM_VID_TAM__c> results = [SELECT Year__c, Month__c, Account__c, OM_ModelRef__c, Revenue__c FROM OM_VID_TAM__c];
        
        System.assertEquals(1, results.size(), 'Debería haberse creado un registro.');
        System.assertEquals('2025', results[0].Year__c);
        System.assertEquals('Jan', results[0].Month__c, 'El mes 01 debería haberse convertido a Jan.');
        System.assertNotEquals(null, results[0].Account__c, 'La cuenta debería estar vinculada.');
        System.assertNotEquals(null, results[0].OM_ModelRef__c, 'El modelo debería estar vinculado.');
        System.assertEquals(100.00, results[0].Revenue__c);
    }
}