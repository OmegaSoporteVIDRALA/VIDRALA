public class OM_BW_InsertActualSalesHistory {

    // WRAPPER PARA LA RESPUESTA DEL WS DE SF
    public class SFWS_Response {
        public Boolean status;
        public String msg;
        public String accountId;
        public String sapCode;
        public String code;
        public List<String> salesforceErrors;
        public String successMessage;
    }

    public static void createResponse(Boolean status, String msg, String accountId, String code, List<String> errors, String successMessage, String sapCode, String requestParam) {
        SFWS_Response respWrapper = new SFWS_Response();
        respWrapper.status = status;
        respWrapper.msg = msg;
        respWrapper.accountId = accountId;
        respWrapper.sapCode = sapCode;
        respWrapper.code = code;
        respWrapper.salesforceErrors = errors;
        respWrapper.successMessage = successMessage;

        OM_Utils.IntegrationMsg.createRESTIntegrationMsg(OM_Utils.IntegrationMsg.INBOUND, '/actualSalesHistoryCalloutBW', 'INSERT');
        OM_Utils.IntegrationMsg.addBody(requestParam, JSON.serialize(respWrapper));
        OM_Utils.IntegrationMsg.addStatusAndRecord((status ? OM_Utils.IntegrationMsg.SUCCESS : OM_Utils.IntegrationMsg.ERROR), accountId, null, null);
        OM_Utils.IntegrationMsg.insertRecord();
    }

    public static String createJsonBWWrapper(String yearFrom, String yearTo, String monthFrom, String monthTo, String salesOrganization, String salesGroup){
        OM_BW_Wrapper.BWFilter filterWrapper = new OM_BW_Wrapper.BWFilter(yearFrom, yearTo, monthFrom, monthTo, salesOrganization, salesGroup);
        return JSON.serialize(filterWrapper);
    }

    @Future (callout=true)
    public static void insertActualSalesHistory(String jsonBWFilter){
        OM_BW_Wrapper.BWFilter filterWrapper = (OM_BW_Wrapper.BWFilter) JSON.deserialize(jsonBWFilter, OM_BW_Wrapper.BWFilter.class);
        actualSalesHistoryCalloutBW(filterWrapper);
    }

    public static void actualSalesHistoryCalloutBW(OM_BW_Wrapper.BWFilter filterWrapper){
        OM_SapFunctionsStyle.CDSS cdss = new OM_SapFunctionsStyle.CDSS();
        OM_SapFunctionsStyle.Rrxw3tquery parameter = buildQueryParameters(filterWrapper);
        String requestString = parameter.toString();

        try{
            OM_SapFunctionsStyle.GetQueryViewDataResponse_element response = cdss.GetQueryViewData('ZMSDF_11', parameter, 'ZMSDF_11_PYGACC_SF', null);
            if(response != null && response.axisData != null){
                processActualSalesHistoryCalloutResponse(response, requestString);
            }
        }catch(Exception e){
            createResponse(false, 'Error not known', null, '400', new List<String>{e.getMessage(), e.getStackTraceString()}, null, 'Bad request', requestString);
        }
    }

    private static OM_SapFunctionsStyle.Rrxw3tquery buildQueryParameters(OM_BW_Wrapper.BWFilter filterWrapper){
        List<OM_SapFunctionsStyle.W3query> items = new List<OM_SapFunctionsStyle.W3query>();
        Integer counter = 1;

        items.add(new OM_SapFunctionsStyle.W3query('VAR_NAME_' + counter, 'VAR_20240626203032'));
        items.add(new OM_SapFunctionsStyle.W3query('VAR_VALUE_LOW_EXT_' + counter, filterWrapper.monthFrom + '.' + filterWrapper.yearFrom));
        items.add(new OM_SapFunctionsStyle.W3query('VAR_VALUE_HIGH_EXT_' + counter, filterWrapper.monthTo + '.' + filterWrapper.yearTo));
        counter++;

        if(filterWrapper.salesOrganization != null){
            items.add(new OM_SapFunctionsStyle.W3query('VAR_NAME_' + counter, 'VAR_20241107114952'));
            items.add(new OM_SapFunctionsStyle.W3query('VAR_VALUE_EXT_' + counter, filterWrapper.salesOrganization));
            counter++;
        }

        if(filterWrapper.salesGroup != null){
            items.add(new OM_SapFunctionsStyle.W3query('VAR_NAME_' + counter, 'VAR_20241220095416'));
            items.add(new OM_SapFunctionsStyle.W3query('VAR_VALUE_EXT_' + counter, filterWrapper.salesGroup));
        }

        OM_SapFunctionsStyle.Rrxw3tquery param = new OM_SapFunctionsStyle.Rrxw3tquery();
        param.item = items;
        return param;
    }

    public static void processActualSalesHistoryCalloutResponse(OM_SapFunctionsStyle.GetQueryViewDataResponse_element response, String requestString){
        
        Map<String,Object> parsed = parseAxisData(response);

        Map<String,Object> validation = validateMasterData(
            (Set<String>)parsed.get('accounts'),
            (Set<String>)parsed.get('products'),
            (Set<String>)parsed.get('materials')
        );

        List<String> errors = (List<String>)validation.get('errors');
        if(!errors.isEmpty()){
            createResponse(false, 'Validation error', null, '400', errors, null, null, requestString);
            return;
        }

        List<Actual_Sales_History__c> records = buildRecords(
            (List<Map<String,String>>)parsed.get('rawRows'),
            (Map<String,Account>)validation.get('accounts'),
            (Map<String,Product2>)validation.get('products'),
            (Map<String,SAP_Material_Code__c>)validation.get('materials'),
            response
        );

        if(!records.isEmpty()){
            Database.insert(records, true);
            createResponse(true, '', null, '200', new List<String>(), 'Insert operations completed successfully.', null, requestString);
        }
    }

    private static Map<String,Object> parseAxisData(OM_SapFunctionsStyle.GetQueryViewDataResponse_element response){
        List<Map<String,String>> rawRows = new List<Map<String,String>>();
        Set<String> sapAccounts = new Set<String>();
        Set<String> productCodes = new Set<String>();
        Set<String> materialCodes = new Set<String>();

        Integer cellOrdinalCounter = 0;

        for(OM_SapFunctionsStyle.RrwsSxAxisData axis : response.AxisData.item){
            if(axis.axis == '001'){
                Integer tupleCounter = 0;
                for(OM_SapFunctionsStyle.RrwsSxTuple item : axis.Set_x.item){
                    if(tupleCounter == Integer.valueOf(item.TupleOrdinal)){
                        Map<String,String> row = new Map<String,String>();
                        if(item.Chanm == '0SOLD_TO'){
                            row.put('ACCOUNT', item.ChavlExt.toUpperCase());
                            sapAccounts.add(item.ChavlExt.toUpperCase());
                        } else if(item.Chanm == '0MATERIAL__ZISDMODEL'){
                            row.put('PRODUCT', item.ChavlExt.toUpperCase());
                            productCodes.add(item.ChavlExt.toUpperCase());
                        } else if(item.Chanm == '0MATERIAL'){
                            row.put('MATERIAL', item.ChavlExt.toUpperCase());
                            materialCodes.add(item.ChavlExt.toUpperCase());
                        }
                        if(!row.isEmpty()) rawRows.add(row);
                        tupleCounter++;
                    }
                }
            }
        }

        return new Map<String,Object>{
            'rawRows' => rawRows,
            'accounts' => sapAccounts,
            'products' => productCodes,
            'materials' => materialCodes
        };
    }

    private static Map<String,Object> validateMasterData(Set<String> sapAccounts, Set<String> productCodes, Set<String> materialCodes){
        Map<String,Account> accountMap = new Map<String,Account>();
        Map<String,Product2> productMap = new Map<String,Product2>();
        Map<String,SAP_Material_Code__c> materialMap = new Map<String,SAP_Material_Code__c>();
        List<String> errors = new List<String>();

        if(!sapAccounts.isEmpty()){
            for(Account a : [SELECT Id, SAP_Account_Number__c FROM Account WHERE SAP_Account_Number__c IN :sapAccounts]){
                accountMap.put(a.SAP_Account_Number__c.toUpperCase(), a);
            }
            for(String s : sapAccounts) if(!accountMap.containsKey(s)) errors.add('ACCOUNT NOT FOUND: ' + s);
        }

        if(!productCodes.isEmpty()){
            for(Product2 p : [SELECT Id, OM_Product_Code_SIP__c FROM Product2 WHERE OM_Product_Code_SIP__c IN :productCodes]){
                productMap.put(p.OM_Product_Code_SIP__c.toUpperCase(), p);
            }
            for(String s : productCodes) if(!productMap.containsKey(s)) errors.add('PRODUCT NOT FOUND: ' + s);
        }

        if(!materialCodes.isEmpty()){
            for(SAP_Material_Code__c m : [SELECT Id, Material_Code_Key__c FROM SAP_Material_Code__c WHERE Material_Code_Key__c IN :materialCodes]){
                materialMap.put(m.Material_Code_Key__c.toUpperCase(), m);
            }
            for(String s : materialCodes) if(!materialMap.containsKey(s)) errors.add('MATERIAL NOT FOUND: ' + s);
        }

        return new Map<String,Object>{
            'accounts' => accountMap,
            'products' => productMap,
            'materials' => materialMap,
            'errors' => errors
        };
    }

    @TestVisible
    private static List<Actual_Sales_History__c> buildRecords(List<Map<String,String>> rawRows, Map<String,Account> accountMap, Map<String,Product2> productMap, Map<String,SAP_Material_Code__c> materialMap, OM_SapFunctionsStyle.GetQueryViewDataResponse_element response){
        List<Actual_Sales_History__c> records = new List<Actual_Sales_History__c>();
        Integer cellOrdinalCounter = 0;
    
        for(Map<String,String> row : rawRows){
            Actual_Sales_History__c rec = new Actual_Sales_History__c();
    
            rec.Account__c = accountMap.get(row.get('ACCOUNT')).Id;
            rec.OM_ModelRef__c = productMap.get(row.get('PRODUCT')).Id;
            rec.SAP_Material_Code__c = materialMap.get(row.get('MATERIAL')).Id;
    
            rec.Revenue__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter).Value);
            rec.RevenuePrev__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 1).Value);
            rec.RevenueVar__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 2).Value);
            rec.RevenueVarPercentage__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 3).Value);
    
            rec.Tonnes__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 4).Value);
            rec.TonnesPrev__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 5).Value);
            rec.TonnesVar__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 6).Value);
            rec.TonnesVarPercent__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 7).Value);
    
            rec.Volume_000_s__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 8).Value);
            rec.Volume000sPrev__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 9).Value);
            rec.Volume000sVar__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 10).Value);
            rec.Volume000sVarPercent__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 11).Value);
    
            rec.OM_VID_EuroTonnePrevious__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 13).Value);
            rec.OM_VID_EuroTonneVar__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 14).Value);
            rec.OM_VID_EuroTonneVarPercent__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 15).Value);
    
            rec.Precio_FF__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 16).Value);
            rec.PrecioFFPrev__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 17).Value);
            rec.PrecioFFVar__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 18).Value);
            rec.PrecioFFVarPercent__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 19).Value);
    
            cellOrdinalCounter += 20;
            records.add(rec);
        }
    
        return records;
    }

	private static Decimal parseDecimal(String value){
        if(String.isBlank(value)) return 0;
        try{
            return Decimal.valueOf(value).setScale(2, RoundingMode.HALF_UP);
        }catch(Exception e){
            System.debug('ERROR al parsear a Decimal: ' + value + ' - ' + e.getMessage());
            return 0;
        }
    }
}