@IsTest
public class OM_BW_StocksCallout_Test {
    
    @IsTest
    static void testCreateJsonBWWrapper() {
        // Datos de prueba
        String year = '2024';
        String month = '01';
        String model = 'MOD789';
        

        // Ejecutar el método y obtener JSON
        String jsonOutput = OM_BW_StocksCallout.createJsonBWWrapper(year, month, model);
        System.debug('JSON Output: ' + jsonOutput);

        // Validar que el JSON no está vacío y es un objeto válido
        System.assert(!String.isBlank(jsonOutput), 'El JSON no debe estar vacío.');
    }

    @IsTest
    static void testAbonosDevolucionesSACCalloutBW() {
        // Crear un objeto BWFilter con datos simulados
        OM_BW_Wrapper.BWFilter testFilter = new OM_BW_Wrapper.BWFilter(
            '2024', '2025','MOD789'
        );
        
        Test.setMock(WebServiceMock.class, new OM_SapFunctionsMock_Test());
        
        Test.startTest();

        // Ejecutar el método
        OM_BW_Wrapper.BWReport result = OM_BW_StocksCallout.stocksCalloutBW(testFilter);

        // Validar que la respuesta no sea nula y tenga datos procesados
        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.rows.size() > 0, 'Debe haber datos procesados.');
        Test.stopTest();
    }

}