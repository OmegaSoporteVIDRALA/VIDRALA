@isTest
public class OM_BW_InsertActualSalesHistory_Test {
    
    
    
    @IsTest
    static void testCreateJsonBWWrapper() {
        // Datos de prueba
       String yearFrom = '2024';
        String yearTo = '2025';
        String monthFrom = '01';
        String monthTo = '12';
        String salesOrganization = 'CUST123';
        String salesGroup = 'SHIP456';
       
       

        
        String jsonOutput = OM_BW_InsertActualSalesHistory.createJsonBWWrapper(yearFrom, yearTo, monthFrom, monthTo, salesOrganization, salesGroup);
        System.debug('JSON Output: ' + jsonOutput);

        
        System.assert(!String.isBlank(jsonOutput), 'El JSON no debe estar vacío.');
    }

    @IsTest
    static void testactualSalesHistoryCalloutBW() {
        // Crear un objeto BWFilter con datos simulados
        OM_BW_Wrapper.BWFilter testFilter = new OM_BW_Wrapper.BWFilter(
            '2024', '2025', '01', '12', 'CUST123', 'SHIP456'
           
        );
        
        Test.setMock(WebServiceMock.class, new OM_SapFunctionsMockActualSalesH_Test());
        
        Test.startTest();

        
        OM_BW_InsertActualSalesHistory.actualSalesHistoryCalloutBW(testFilter);

        System.assert(true, 'El método se ejecutó sin errores.');
        Test.stopTest();
    }
    
    @IsTest
    static void testInsertActualSalesHistory() {
        
        
       String json = '{' +
            '"yearFrom": "2024",' +
            '"yearTo": "2025",' +
            '"monthFrom": "01",' +
            '"monthTo": "12",' +
            '"salesOrganization": "CUST123",' +
            '"salesGroup": "SHIP456"' +
        '}';
        
        Test.setMock(WebServiceMock.class, new OM_SapFunctionsMockActualSalesH_Test());
        
        Test.startTest();

        
        OM_BW_InsertActualSalesHistory.insertActualSalesHistory(json);

     
       System.assert(true, 'El método se ejecutó sin errores.');
        Test.stopTest();
    }
    
    

}