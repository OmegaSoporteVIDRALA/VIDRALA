/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DailyComparativesComponentController.cls
   Description: Controller Class for the Daily Comparatives Visualforce Components
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Sep 2024     1.0     Globant             Added Comments and Code Refactoring
------------------------------------------------------------------------------------------------------------------------ */  
public class CustomRelatedListComponentController {

    /**
     * Retrieves related records based on the provided parameters.
     *
     * @param requestParams The request parameters containing recordId, lookupAPI,
     *                      relatedObjectAPI, fieldAPIs, whereCondition,
     *                      additionalRequest, and additionalAPI.
     * @return              An RLComponentWrapper object containing labels, values, and
     *                      object name of related records.
     */
    @AuraEnabled
    public static RLComponentWrapper getRelatedInfo(String params) {

        if (String.isBlank(params)) {

            return new RLComponentWrapper(null, null, null);
        }

        RequestParams requestParams = (RequestParams)JSON.deserialize(params, RequestParams.class);

        validateRequest(requestParams);

        String recordId = getRecordIdFromAdditionalRequest(requestParams);
        String queryStr = buildQuery(requestParams, recordId);

        return executeQuery(queryStr, requestParams.relatedObjectAPI, requestParams.fieldAPIs);
    }

    /**
     * Validates the provided request parameters.
     *
     * @param params The request parameters to validate.
     * @throws AuraHandledException if any required parameter is missing.
     */
    private static void validateRequest(RequestParams params) {

        if (String.isEmpty(params.recordId)) {
            throw new AuraHandledException('Invalid parameters: Missing record Id.');
        }
        if (String.isEmpty(params.relatedObjectAPI)) {
            throw new AuraHandledException('Invalid parameters: Missing related object API.');
        }
        if (String.isEmpty(params.lookupAPI)) {
            throw new AuraHandledException('Invalid parameters: Missing lookup API.');
        }
    }

    /**
     * Retrieves the record Id from an additional request if present.
     *
     * @param params The request parameters containing additionalRequest and additionalAPI.
     * @return The resolved record Id.
     */
    private static String getRecordIdFromAdditionalRequest(RequestParams params) {

        if (String.isNotEmpty(params.additionalRequest) && String.isNotEmpty(params.additionalAPI)) {
            String qry = String.escapeSingleQuotes(params.additionalRequest) + ' \'' + String.escapeSingleQuotes(params.recordId) + '\'';
            List<SObject> objectList = Database.query(qry);
            if (!objectList.isEmpty()) {
                return String.valueOf(objectList[0].get(params.additionalAPI));
            }
        }
        return params.recordId;
    }

    /**
     * Constructs the SOQL query string based on the provided parameters.
     *
     * @param params The request parameters used to build the query.
     * @param recordId The record Id to be used in the query.
     * @return The constructed SOQL query string.
     */
    private static String buildQuery(RequestParams params, String recordId) {

        String queryStr = 'SELECT Id';
        
        if (String.isNotEmpty(params.fieldAPIs)) {
            queryStr += ', ' + String.escapeSingleQuotes(params.fieldAPIs);
        }
        queryStr += ' FROM ' + String.escapeSingleQuotes(params.relatedObjectAPI);
        queryStr += ' WHERE ' + String.escapeSingleQuotes(params.lookupAPI) + ' = \'' + (String.isNotBlank(recordId) ? String.escapeSingleQuotes(recordId) : '')+ '\'';

        if (String.isNotEmpty(params.whereCondition)) {
            queryStr += ' AND ' + String.escapeSingleQuotes(params.whereCondition);
        }

        return queryStr;
    }

    /**
     * Executes the constructed SOQL query and populates the RLComponentWrapper.
     *
     * @param queryStr The SOQL query string to execute.
     * @param relatedObjectAPI The API name of the related object.
     * @param fieldAPIs The comma-separated field API names to retrieve.
     * @return An RLComponentWrapper object containing labels, values, and object name.
     */
    private static RLComponentWrapper executeQuery(String queryStr, String relatedObjectAPI, String fieldAPIs) {
        
        try {
            List<SObject> objectList = Database.query(queryStr);
            List<String> labelList = getFieldLabels(relatedObjectAPI, fieldAPIs);
            List<List<String>> objectData = populateObjectData(objectList, labelList, fieldAPIs);
            
            String objectName = Schema.getGlobalDescribe().get(relatedObjectAPI).getDescribe().getLabel();
            return new RLComponentWrapper(labelList, objectData, objectName);
        } catch (Exception ex) {
            throw new AuraHandledException('Error executing query: ' + ex.getMessage());
        }
    }

    /**
     * Retrieves field labels for the specified fields in the related object.
     *
     * @param relatedObjectAPI The API name of the related object.
     * @param fieldAPIs The comma-separated field API names.
     * @return A list of field labels corresponding to the field APIs.
     */
    private static List<String> getFieldLabels(String relatedObjectAPI, String fieldAPIs) {
        
        List<String> labels = new List<String>{'Link'};
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(relatedObjectAPI).getDescribe().fields.getMap();
        
        for (String fieldAPI : fieldAPIs.split(',')) {
            if (fieldMap.containsKey(fieldAPI)) {
                labels.add(fieldMap.get(fieldAPI).getDescribe().getLabel());
            }
        }

        return labels;
    }

    /**
     * Populates object data based on the retrieved SObjects.
     *
     * @param objectList The list of SObjects retrieved from the query.
     * @param labelList The list of field labels to populate values for.
     * @param fieldAPIs The comma-separated field API names.
     * @return A list of lists containing the field values for each object.
     */
    private static List<List<String>> populateObjectData(List<SObject> objectList, List<String> labelList, String fieldAPIs) {
        
        List<List<String>> objectData = new List<List<String>>();
        Map<String, String> apiMap = mapFieldAPIsToLabels(labelList, fieldAPIs);

        for (SObject obj : objectList) {
            List<String> values = new List<String>();
            for (String label : labelList) {
                if (label == 'Link') {
                    values.add(String.valueOf(obj.Id));
                } else if (apiMap.containsKey(label) && obj.get(apiMap.get(label)) != null) {
                    values.add(String.valueOf(obj.get(apiMap.get(label))));
                }
            }
            objectData.add(values);
        }

        return objectData;
    }

    /**
     * Maps field API names to their corresponding labels.
     *
     * @param labelList The list of field labels.
     * @param fieldAPIs The comma-separated field API names.
     * @return A map of field labels to their corresponding API names.
     */
    private static Map<String, String> mapFieldAPIsToLabels(List<String> labelList, String fieldAPIs) {
        
        Map<String, String> apiMap = new Map<String, String>();
        List<String> fieldAPIList = fieldAPIs.split(',');

        for (Integer i = 1; i < labelList.size(); i++) {
            apiMap.put(labelList[i], fieldAPIList[i - 1]);
        }

        return apiMap;
    }

    /**
     * Wrapper class for holding request parameters.
     */
    public class RequestParams {
        @AuraEnabled public String recordId;
        @AuraEnabled public String lookupAPI;
        @AuraEnabled public String relatedObjectAPI;
        @AuraEnabled public String fieldAPIs;
        @AuraEnabled public String whereCondition;
        @AuraEnabled public String additionalRequest;
        @AuraEnabled public String additionalAPI;
        public RequestParams() {}
    }

    /**
     * Wrapper class to hold related records information.
     */
    public class RLComponentWrapper {
        @AuraEnabled public List<String> labels { get; set; }
        @AuraEnabled public List<List<String>> values { get; set; }
        @AuraEnabled public String objectName { get; set; }

        /**
         * Constructor to initialize the RLComponentWrapper.
         *
         * @param labels List of field labels.
         * @param values List of field values for each record.
         * @param objectName Name of the related object.
         */
        public RLComponentWrapper(List<String> labels, List<List<String>> values, String objectName) {
            this.labels = labels;
            this.values = values;
            this.objectName = objectName;
        }
    }
}





/*public class CustomRelatedListComponentController {
    
    @AuraEnabled
    public static RLComponentWrapper getRelatedInfo(String recordId, String lookupAPI, String relatedObjectAPI, String fieldAPIs, String whereCondition, String additionalRequest, String additionalAPI) {
        String errorMessage;
        String queryStr;
        String objectName;
        RLComponentWrapper wr;
        System.debug('Parameters: recordId '+ recordId + '; lookupAPI '+ lookupAPI + '; relatedObjectAPI '+ relatedObjectAPI+'; fieldAPIs '+fieldAPIs+'; whereCondition '+whereCondition);
        List<SObject> objectList = new List<SObject>();
        if(additionalRequest != null && additionalAPI != null && objectList != null){
            String qry = additionalRequest + ' \'' + recordId + '\'';
            System.debug('Additional query '+ qry);
            objectList = Database.query(qry);
            if(objectList.size() > 0){
                recordId = String.valueOf(objectList.get(0).get(additionalAPI));
            }
            objectList = new List<SObject>();
        }
        List<String> labelList = new List<String>();
        Map<String, String> apiMap = new Map<String, String>();
        if(!String.isEmpty(recordId)){
            queryStr = 'SELECT Id';
            if(!String.isEmpty(fieldAPIs)){
                queryStr = queryStr + ', ' + fieldAPIs;
            }
            if(!String.isEmpty(relatedObjectAPI)){
                queryStr = queryStr + ' FROM ' + relatedObjectAPI;
                Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                Schema.SObjectType objSchema = schemaMap.get(relatedObjectAPI);
                objectName = objSchema.getDescribe().getLabel();
                Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();
                List<String> apiNames = fieldAPIs.split(',');
                labelList.add('Link');
                for(String fieldName : apiNames){
                    if(fieldMap.containsKey(fieldName)){
                        String fieldlabel = fieldMap.get(fieldName).getDescribe().getLabel();
                        labelList.add(fieldlabel);
                        apiMap.put(fieldlabel, fieldName);
                    }
                }
            } else {
                errorMessage = 'Invalid parameters specified for component: Missing related object API name.';
            }
            if(!String.isEmpty(lookupAPI)){
                queryStr = queryStr + ' WHERE ' + lookupAPI;
            } else {
                if(!String.isEmpty(errorMessage)){
                    errorMessage = errorMessage + ' Missing lookup API name for the main object.';
                } else {
                    errorMessage = 'Invalid parameters specified for component: Missing lookup API name for the main object.';
                }
            }
            queryStr = queryStr + ' = \'' + recordId + '\'';
            if(!String.isEmpty(whereCondition)){
                queryStr = queryStr + ' AND ' + whereCondition;
            }
        } else {
            errorMessage = 'Invalid parameters specified for component: Missing record Id.';
        }
        if(String.isEmpty(errorMessage)){
            try{
                System.debug('queryStr '+queryStr);
                objectList = Database.query(queryStr);
                System.debug('After query'+objectList);
                List<String> valueList;
                List<List<String>> objectData = new List<List<String>>();
                System.debug('objectList.size() '+objectList.size());
                if(objectList.size() > 0){
                    for(SObject obj : objectList){
                        valueList = new List<String>();
                        for(String label : labelList){
                            if(apiMap.containskey(label) && obj.get(apiMap.get(label)) != null){
                                System.debug('label '+ label + ' Value '+ String.valueOf(obj.get(apiMap.get(label))));
                                valueList.add(String.valueOf(obj.get(apiMap.get(label))));
                            }
                            if(label == 'Link'){
                                System.debug('label '+ label + ' Value '+ String.valueOf(obj.Id));
                                valueList.add(String.valueOf(obj.Id));
                            }
                        }
                        objectData.add(valueList);
                    }
                    System.debug('Populate wrapper');
                    wr = new RLComponentWrapper(labelList, objectData, objectName);
                }
            } catch (Exception ex){
                System.debug('SetError');
                errorMessage = 'Invalid parameters specified for component: ' + ex.getMessage();
            }
        }
        if(errorMessage != null){
            //throw new AuraHandledException(errorMessage);
        }
        return wr;
    }

    public class RLComponentWrapper {
        @AuraEnabled
        public List<String> labels {get; set;}
        @AuraEnabled
        public List<List<String>> values {get; set;}
        @AuraEnabled
        public String objectName {get; set;}

        public RLComponentWrapper(List<String> l, List<List<String>> v, String n){
            labels = l;
            values = v;
            objectName = n;
        }
    }
}*/