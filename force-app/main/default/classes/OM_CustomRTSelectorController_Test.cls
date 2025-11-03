@IsTest
public class OM_CustomRTSelectorController_Test {

    @IsTest
    static void testGetRecordTypes() {
        String objectApiName = 'Account';

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;

        Test.startTest();
        List<OM_CustomRTSelectorController.RecordTypeWrapper> result =
            OM_CustomRTSelectorController.getRecordTypes(objectApiName, profileId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debería ser nulo.');
        System.assert(result.size() > 0, 'Debería devolver al menos un record type disponible.');
        System.assertNotEquals('', result[0].label, 'El label no debería estar vacío.');
        System.assertNotEquals('', result[0].value, 'El Id del record type no debería estar vacío.');
        System.assertNotEquals('', result[0].description, 'La descripción no debería estar vacía.');
    }

    @IsTest
    static void testGetRecordTypes_InvalidObject() {
       Test.startTest();
        List<OM_CustomRTSelectorController.RecordTypeWrapper> result =
            OM_CustomRTSelectorController.getRecordTypes('Objeto_Inventado__c', UserInfo.getProfileId());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Debe devolver una lista vacía si el objeto no existe.');
    }

    @IsTest
    static void testGetObjectLabel() {
        Test.startTest();
        String label = OM_CustomRTSelectorController.getObjectLabel('Case');
       

        System.assertEquals('Insatisfacción', label, 'Debe devolver el label del objeto Case.');

        
        String fallback = OM_CustomRTSelectorController.getObjectLabel('Objeto_Falso__c');
        Test.stopTest();

        System.assertEquals('Objeto_Falso__c', fallback, 'Debe devolver el API name si el objeto no existe.');
    }
}