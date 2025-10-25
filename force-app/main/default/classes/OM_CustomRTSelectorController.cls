/**
* @File Name : OM_CustomRTSelectorController.cls
* @Description :Controlador del LWC que replica la pantalla custom de seleccion de Record Type al crear registros mediante el boton de New en las Related List
* @Author :Mikel Genolla
* @Last Modified By :
* @Last Modified On : 
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 16, 2025 |   | Initial Version
**/

public class OM_CustomRTSelectorController {

    public class RecordTypeWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value; // RecordTypeId
        @AuraEnabled public String description;
    }

    @AuraEnabled(cacheable=true)
   public static List<RecordTypeWrapper> getRecordTypes(String objectApiName, String profileId) {
       List<RecordTypeWrapper> rtList = new List<RecordTypeWrapper>();
        
        SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        if (objType == null) {
            return rtList;
        }

        Set<Id> availableRecordTypeIds = new Set<Id>();
        List<Schema.RecordTypeInfo> rtInfoList = objType.getDescribe().getRecordTypeInfos();

        for (Schema.RecordTypeInfo rtInfo : rtInfoList) {
            if (rtInfo.isAvailable() && !rtInfo.isMaster()) {
                availableRecordTypeIds.add(rtInfo.getRecordTypeId());
            }
        }

        if (availableRecordTypeIds.isEmpty()) {
            return rtList;
        }

        for (RecordType rt : [SELECT Id, Name, Description FROM RecordType WHERE Id IN :availableRecordTypeIds ORDER BY Name]) {
            RecordTypeWrapper rtWrapper = new RecordTypeWrapper();
            rtWrapper.label = rt.Name;
            rtWrapper.value = rt.Id;
            rtWrapper.description = String.isNotBlank(rt.Description) ? rt.Description : 'No description available.';
            rtList.add(rtWrapper);
        }
        
        return rtList;
    }
   
    @AuraEnabled(cacheable=true)
    public static String getObjectLabel(String objectApiName) {
        try {
            SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
            if (objType != null) {
                return objType.getDescribe().getLabel();
            }
        } catch (Exception e) {
            return objectApiName;
        }
        return objectApiName;
    }
}