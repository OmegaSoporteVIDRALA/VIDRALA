@isTest
public class OM_VID_CaseTRGHandler_Test {
    @isTest static void testHandlerMethod_BeforeInsertMethods(){
        Test.StartTest();
        OM_VID_TestUtils.createCases(1);
        
        Case insatisfaccion = [SELECT ID, OM_SAC_Lista_de_distribucion__c FROM Case WHERE RecordTypeId =: OM_Utils.RecordTypes.getRecordTypeByDevName('Case', 'Fifty_Calidad_Insatisfaccion') limit 1];
        //Assert.areEqual(acc.Phone, '+34 523456789', 'Account phone number hasn\'t got the expected format');
        Assert.areNotEqual(insatisfaccion.OM_SAC_Lista_de_distribucion__c, '', 'La lista de distribución no puede estar vacía.');
        Test.StopTest();
    }
    
    @isTest static void testHandlerMethod_AfterInsertMethods(){
        Test.StartTest();
        OM_VID_TestUtils.createCases(1);
        
        Case insatisfaccion = [SELECT ID, Subject, OM_SAC_Categorizacion_Incidencia__c, OM_SAC_loteOAlbaran__c, OM_SAC_Defecto__c, OM_VID_AccountNameAuto__c, OM_SAC_CodigoModelo__c FROM Case WHERE RecordTypeId =: OM_Utils.RecordTypes.getRecordTypeByDevName('Case', 'Fifty_Calidad_Insatisfaccion') limit 1];
        //Assert.areEqual(acc.Phone, '+34 523456789', 'Account phone number hasn\'t got the expected format');
        Assert.areEqual(insatisfaccion.Subject, 'Apertura NC_'+insatisfaccion.OM_SAC_Categorizacion_Incidencia__c+'_'+insatisfaccion.OM_VID_AccountNameAuto__c+'_'+insatisfaccion.OM_SAC_loteOAlbaran__c+'_'+insatisfaccion.OM_SAC_CodigoModelo__c+'_'+insatisfaccion.OM_SAC_Defecto__c);
        Test.StopTest();
    }
    
	@isTest static void testHandlerMethod_AfterUpdateMethods(){
        
        OM_VID_TestUtils.createCases(1);
        
        Case insatisfaccion = [SELECT Id, Subject, OM_SAC_Categorizacion_Incidencia__c, OM_SAC_loteOAlbaran__c, OM_SAC_Defecto__c, OM_VID_AccountNameAuto__c, OM_SAC_CodigoModelo__c, OM_VID_Planta__c 
                               FROM Case 
                               WHERE RecordTypeId =: OM_Utils.RecordTypes.getRecordTypeByDevName('Case', 'Fifty_Calidad_Insatisfaccion') 
                               LIMIT 1];
        
        
        insatisfaccion.OM_SAC_Categorizacion_Incidencia__c = 'B';
        insatisfaccion.OM_SAC_loteOAlbaran__c = '4554321';
        insatisfaccion.OM_SAC_Defecto__c = 'update';
        insatisfaccion.OM_VID_Planta__c = '1090';
        
        Test.StartTest();
        update insatisfaccion;
        Test.StopTest();
        
        Case updatedCase = [SELECT Id, Subject, OM_SAC_Categorizacion_Incidencia__c, OM_SAC_loteOAlbaran__c, OM_SAC_Defecto__c, OM_VID_AccountNameAuto__c, OM_SAC_CodigoModelo__c, OM_VID_Planta__c, OM_SAC_Lista_de_distribucion__c 
                            FROM Case 
                            WHERE Id = :insatisfaccion.Id];
        
        String updatedSubject = 'Apertura NC_' + updatedCase.OM_SAC_Categorizacion_Incidencia__c + '_' +
                                 updatedCase.OM_VID_AccountNameAuto__c + '_' +
                                 updatedCase.OM_SAC_loteOAlbaran__c + '_' +
                                 updatedCase.OM_SAC_CodigoModelo__c + '_' +
                                 updatedCase.OM_SAC_Defecto__c;
                                 
        System.assertEquals(updatedSubject, updatedCase.Subject, 'El Subject no se ha actualizado correctamente.');
        
        String expectedListaDistribucion = OM_VID_CaseTRGHandlerMethods.getOrgWideEmailAddressIdFromPlant(updatedCase.OM_VID_Planta__c);
        
        System.assertEquals(expectedListaDistribucion, updatedCase.OM_SAC_Lista_de_distribucion__c, 'La lista de distribución no coincide con el email esperado.');
	}
}