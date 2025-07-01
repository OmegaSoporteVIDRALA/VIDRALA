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
        
        Case insatisfaccion = [SELECT ID, Subject, OM_SAC_Categorizacion_Incidencia__c, OM_SAC_loteOAlbaran__c, OM_SAC_hipotesisDelAt__c, OM_VID_AccountNameAuto__c, OM_SAC_CodigoModelo__c FROM Case WHERE RecordTypeId =: OM_Utils.RecordTypes.getRecordTypeByDevName('Case', 'Fifty_Calidad_Insatisfaccion') limit 1];
        //Assert.areEqual(acc.Phone, '+34 523456789', 'Account phone number hasn\'t got the expected format');
        Assert.areEqual(insatisfaccion.Subject, 'Apertura NC_'+insatisfaccion.OM_SAC_Categorizacion_Incidencia__c+'_'+insatisfaccion.OM_VID_AccountNameAuto__c+'_'+insatisfaccion.OM_SAC_loteOAlbaran__c+'_'+insatisfaccion.OM_SAC_CodigoModelo__c+'_'+insatisfaccion.OM_SAC_hipotesisDelAt__c);
        Test.StopTest();
    }

}