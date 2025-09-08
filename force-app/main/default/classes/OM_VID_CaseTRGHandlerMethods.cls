/*
* @TestedBy: OM_VID_CaseTRGHandler_Test
*/
public class OM_VID_CaseTRGHandlerMethods {

    private static Id insatisfaccionRecordType = OM_Utils.RecordTypes.getRecordTypeByDevName('Case', 'Fifty_Calidad_Insatisfaccion');
    
    public static void caseBeforeActions(List<Case> newList, Map<Id, Case> oldMap) {
        for (Case currentCase : newList) {
            if (currentCase.RecordTypeId == insatisfaccionRecordType && currentCase.OM_VID_Planta__c != null) {              
                if (oldMap == null) {
                    currentCase.OM_SAC_Lista_de_distribucion__c = getOrgWideEmailAddressIdFromPlant(currentCase.OM_VID_Planta__c);
                } else {                  
                    Case oldCase = oldMap.get(currentCase.Id);
                    if (oldCase != null && oldCase.OM_VID_Planta__c != currentCase.OM_VID_Planta__c) {
                        currentCase.OM_SAC_Lista_de_distribucion__c = getOrgWideEmailAddressIdFromPlant(currentCase.OM_VID_Planta__c);
                    }
                }
            }
        }
	}
    
    public static void caseAfterActions(List<Case> newList, Map<Id, Case> oldMap) {
        List<Case> caseUpdateList = new List<Case>();
    
        for (Case insatisf : newList) {
            if (insatisf.RecordTypeId == insatisfaccionRecordType &&
                insatisf.OM_SAC_Categorizacion_Incidencia__c != null &&
                insatisf.OM_SAC_loteOAlbaran__c != null &&
                insatisf.OM_SAC_modeloYDenominacion__c != null &&
                insatisf.OM_SAC_Defecto__c != null) {
    
                if (oldMap == null) {
                    
                    String subject = 'Apertura NC_' + insatisf.OM_SAC_Categorizacion_Incidencia__c + '_' +
                                     insatisf.OM_VID_AccountNameAuto__c + '_' +
                                     insatisf.OM_SAC_loteOAlbaran__c + '_' +
                                     insatisf.OM_SAC_CodigoModelo__c + '_' +
                                     insatisf.OM_SAC_Defecto__c;
    
                    Case updCase = new Case(
                        Id = insatisf.Id,
                        Subject = subject.length() > 255 ? subject.substring(0, 255) : subject
                    );
                    caseUpdateList.add(updCase);
    
                } else {
                    
                    Case oldCase = oldMap.get(insatisf.Id);
    
                    if (oldCase != null && (
                        oldCase.OM_SAC_Categorizacion_Incidencia__c != insatisf.OM_SAC_Categorizacion_Incidencia__c ||
                        oldCase.OM_VID_AccountNameAuto__c != insatisf.OM_VID_AccountNameAuto__c ||
                        oldCase.OM_SAC_loteOAlbaran__c != insatisf.OM_SAC_loteOAlbaran__c ||
                        oldCase.OM_SAC_modeloYDenominacion__c != insatisf.OM_SAC_modeloYDenominacion__c ||
                        oldCase.OM_SAC_Defecto__c != insatisf.OM_SAC_Defecto__c
                    )) {
                        String subject = 'Apertura NC_' + insatisf.OM_SAC_Categorizacion_Incidencia__c + '_' +
                                         insatisf.OM_VID_AccountNameAuto__c + '_' +
                                         insatisf.OM_SAC_loteOAlbaran__c + '_' +
                                         insatisf.OM_SAC_CodigoModelo__c + '_' +
                                         insatisf.OM_SAC_Defecto__c;
    
                        Case updCase = new Case(
                            Id = insatisf.Id,
                            Subject = subject.length() > 255 ? subject.substring(0, 255) : subject
                        );
                        caseUpdateList.add(updCase);
                    }
                }
            }
        }
    
            if (!caseUpdateList.isEmpty()) {
                OM_Utils.shouldSkipTriggerGlobal = true;
                update caseUpdateList;
                OM_Utils.shouldSkipTriggerGlobal = false;
            } 
	}
    
    
    @TestVisible
    private static String getOrgWideEmailAddressIdFromPlant(String plant) {
            
        String listaDistribucion = '';
        switch on plant {
            when '1010'{
                listaDistribucion = 'Grp._Apertura_Incidencias_AV@vidrala.com';
            }when '1020'{
                listaDistribucion = 'Grp._Apertura_Incidencias_CR@vidrala.com';
            }when '1030'{
                listaDistribucion = 'grp._apertura_incidencias_cs@vidrala.com';
            }when '1040'{
                listaDistribucion = 'Grp._Apertura_Incidencias_GV@vidrala.com';
            }when '1090'{
                listaDistribucion = 'Grp._Apertura_Incidencias_SB@vidrala.com';
            }
    	}
        
        return listaDistribucion;
    }
}