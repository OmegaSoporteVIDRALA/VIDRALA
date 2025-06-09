@isTest
public class OM_BW_AbonosDevolucionesCallout_Test {
    
@IsTest
    static void testCreateJsonBWWrapper() {
        // Datos de prueba
        String yearFrom = '2024';
        String yearTo = '2025';
        String monthFrom = '01';
        String monthTo = '12';
        String customerCode = 'CUST123';
        String shippingAddressCode = 'SHIP456';
        List<String> orderReason = new List<String>{'motivo1', 'motivo2'};
        String model = 'MOD789';
        String material = 'MAT101';
        String batch = 'BATCH202';

        // Ejecutar el método y obtener JSON
        String jsonOutput = OM_BW_AbonosDevolucionesCallout.createJsonBWWrapper(yearFrom, yearTo, monthFrom, monthTo, customerCode, shippingAddressCode, orderReason, model, material, batch);
        System.debug('JSON Output: ' + jsonOutput);

        // Validar que el JSON no está vacío y es un objeto válido
        System.assert(!String.isBlank(jsonOutput), 'El JSON no debe estar vacío.');
    }

    @IsTest
    static void testAbonosDevolucionesSACCalloutBW() {
        // Crear un objeto BWFilter con datos simulados
        OM_BW_Wrapper.BWFilter testFilter = new OM_BW_Wrapper.BWFilter(
            '2024', '2025', '01', '12', 'CUST123', 'SHIP456',
            new List<String>{'motivo1'}, 'MOD789', 'MAT101', 'BATCH202'
        );
        
        Test.setMock(WebServiceMock.class, new OM_SapFunctionsMockAbonosDev_Test());
        
        Test.startTest();

        // Ejecutar el método
        OM_BW_Wrapper.BWReport result = OM_BW_AbonosDevolucionesCallout.abonosDevolucionesSACCalloutBW(testFilter);

        // Validar que la respuesta no sea nula y tenga datos procesados
        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.rows.size() > 0, 'Debe haber datos procesados.');
        Test.stopTest();
    }
}