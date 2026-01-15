/*
* @TestedBy: OM_VID_CaseTRGHandler_Test
*/
public class OM_VID_CaseTRGHandlerMethods {

    private static Id insatisfaccionRecordType = OM_Utils.RecordTypes.getRecordTypeByDevName('Case', 'Fifty_Calidad_Insatisfaccion');
    private static final String EMAIL_DELIMITER = ';';
    
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
        
         Set<Id> accountIds = new Set<Id>();
            for (Case c : newList) {
                if (c.AccountId != null) {
                    accountIds.add(c.AccountId);
                }
            }
    
            Map<Id, Account> accountsMap = new Map<Id, Account>(
                [SELECT Id, ParentId FROM Account WHERE Id IN :accountIds]
            );
    
            for (Case c : newList) {
                Case oldCase = (oldMap != null ? oldMap.get(c.Id) : null);
    
                if (oldMap == null) {
                    if (c.AccountId != null && accountsMap.containsKey(c.AccountId)) {
                        Id parentId = accountsMap.get(c.AccountId).ParentId;
                        if (parentId != null) {
                            c.OM_SAC_Grupo_Cliente__c = parentId;
                        }
                    }
                }
                
                else {
                    Boolean accountChanged = (c.AccountId != oldCase.AccountId);
    
                    if (accountChanged) {
                        if (c.AccountId != null && accountsMap.containsKey(c.AccountId)) {
                            Id parentId = accountsMap.get(c.AccountId).ParentId;
                            if (parentId != null) {
                                c.OM_SAC_Grupo_Cliente__c = parentId;
                            } else {
                                c.OM_SAC_Grupo_Cliente__c = null;
                            }
                        } else {
                            c.OM_SAC_Grupo_Cliente__c = null;
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
        if (String.isBlank(plant) || String.isEmpty(plant)) {
            return null;
        }
        Map<String, String> mapPlantEmail = getMapPlantsEmail();
        if (mapPlantEmail == null || mapPlantEmail.isEmpty()) {
            return null;
        }
        return mapPlantEmail.containsKey(plant)? mapPlantEmail.get(plant) : null;
    }
    
    private static Map<String, String> getMapPlantsEmail() {
        Map<String, Set<String>> mapPlantSetEmails = new Map<String, Set<String>>();
        Map<String, String> mapPlantStringEmails = new Map<String, String>();
        List<OM_SAC_oweaByPlant__mdt> rows = OM_SAC_oweaByPlant__mdt.getAll().values();
        if (rows == null || rows.isEmpty()) {
            return mapPlantStringEmails;
        }
        for (OM_SAC_oweaByPlant__mdt rec : rows) {
            String plant = rec != null ? rec.OM_SAC_plant__c : null;
            String email = rec != null ? rec.OM_SAC_email__c : null;
            if (String.isBlank(plant) || String.isBlank(email)) {
                continue;
            }
            if (!mapPlantSetEmails.containsKey(plant)) {
                mapPlantSetEmails.put(plant, new Set<String>());
            }
            mapPlantSetEmails.get(plant).add(email);
        }
        for (String plantKey : mapPlantSetEmails.keySet()) {
            List<String> emails = new List<String>();
            for (String e : mapPlantSetEmails.get(plantKey)) {
                if (!String.isBlank(e)) {
                    emails.add(e);
                }
            }
            emails.sort();
            mapPlantStringEmails.put(plantKey, String.join(emails, EMAIL_DELIMITER));
        }
        return mapPlantStringEmails;
    }
}