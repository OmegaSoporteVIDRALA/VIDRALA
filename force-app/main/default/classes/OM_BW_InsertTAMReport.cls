public class OM_BW_InsertTAMReport {

    // WRAPPER PARA LA RESPUESTA DEL WS DE SF
    public class SFWS_Response {
        public Boolean status;
        public String msg;
        public List<String> salesforceErrors;
        public String successMessage;
    }

    @future(callout=true)
    public static void insertTAM(String jsonFilter){ 
        OM_BW_Wrapper.BWFilter filterWrapper = (OM_BW_Wrapper.BWFilter) JSON.deserialize(jsonFilter, OM_BW_Wrapper.BWFilter.class);
        tamCalloutBW(filterWrapper);
    }

    public static void tamCalloutBW(OM_BW_Wrapper.BWFilter filterWrapper){
        String infoProvider = 'ZMSDF_11';
        String query = 'ZMSDF_11_PYGTAM_SF';
        Integer VAR_NAME = 1; 

        OM_SapFunctionsStyle.CDSS cdss = new OM_SapFunctionsStyle.CDSS();
        List<OM_SapFunctionsStyle.W3query> itemList = new List<OM_SapFunctionsStyle.W3query>();

        OM_SapFunctionsStyle.W3query item1 = new OM_SapFunctionsStyle.W3query();
        item1.Name = 'VAR_NAME_' + VAR_NAME;
        item1.Value = '0CALTAM';
        itemList.add(item1);

        OM_SapFunctionsStyle.W3query item2 = new OM_SapFunctionsStyle.W3query();
        item2.Name = 'VAR_VALUE_EXT_' + VAR_NAME;
        item2.Value = filterWrapper.monthFrom + '.' + filterWrapper.yearFrom;
        itemList.add(item2);
        VAR_NAME++;

        if (filterWrapper.salesGroup != null) {
            OM_SapFunctionsStyle.W3query item3 = new OM_SapFunctionsStyle.W3query();
            item3.Name = 'VAR_NAME_' + VAR_NAME;
            item3.Value = 'VAR_20241220095416';
            itemList.add(item3);

            OM_SapFunctionsStyle.W3query item4 = new OM_SapFunctionsStyle.W3query();
            item4.Name = 'VAR_VALUE_EXT_' + VAR_NAME;
            item4.Value = filterWrapper.salesGroup;
            itemList.add(item4);
            VAR_NAME++;
        }

        OM_SapFunctionsStyle.Rrxw3tquery parameter = new OM_SapFunctionsStyle.Rrxw3tquery();
        parameter.item = itemList;
        String requestString = parameter.toString();

        try {
            OM_SapFunctionsStyle.GetQueryViewDataResponse_element response = cdss.GetQueryViewData(infoProvider, parameter, query, null);
            if(response != null && response.axisData != null){
                processActualTAMCalloutResponse(response, requestString, filterWrapper);
            }
        } catch(Exception e) {
            createResponse(false, 'Error en callout TAM', null, '400', new List<String>{e.getMessage()}, null, null, requestString);
        }
    }

    public static void processActualTAMCalloutResponse(OM_SapFunctionsStyle.GetQueryViewDataResponse_element response, String requestString, OM_BW_Wrapper.BWFilter filterWrapper){
        List<OM_VID_TAM__c> temporaryList = new List<OM_VID_TAM__c>();
        List<String> salesforceErrors = new List<String>();
        Integer cellOrdinalCounter = 0; 

        // Preparamos el valor del mes una sola vez fuera del bucle para ahorrar CPU
        String salesforceMonth = getPicklistMonth(filterWrapper.monthFrom);

        for(OM_SapFunctionsStyle.RrwsSxAxisData axis : response.AxisData.item){
            if(axis.axis == '001'){ 
                Integer tupleCounter = 0;
                OM_VID_TAM__c tamRec = new OM_VID_TAM__c();

                for(OM_SapFunctionsStyle.RrwsSxTuple item : axis.Set_x.item){
                    if(tupleCounter == Integer.valueOf(item.TupleOrdinal)){
                        
                        // INYECCIÓN DE FECHA (Picklist compatible)
                        if(tamRec.Year__c == null) {
                            tamRec.Year__c = filterWrapper.yearFrom;
                            tamRec.Month__c = salesforceMonth;
                        }

                        if (item.Chanm == '0SOLD_TO') {
                            tamRec.OM_AccountText__c = item.Chavl.replaceFirst('^0+', '').toUpperCase();
                        } 
                        else if (item.Chanm == '0MATERIAL__ZISDMODEL') {
                            if(String.isNotBlank(item.ChavlExt) && item.ChavlExt != '#') {
                                tamRec.OM_ProductCodeText__c = item.ChavlExt.toUpperCase();
                            }

                            if(String.isNotBlank(tamRec.OM_AccountText__c)){
                                fillNumericData(tamRec, response.cellData.item, cellOrdinalCounter);
                                temporaryList.add(tamRec);
                                cellOrdinalCounter += 20; 
                            }
                            
                            tamRec = new OM_VID_TAM__c();
                            tupleCounter++;
                        }
                    }        
                }
            }
        }

        if(temporaryList.isEmpty()) return;

        validateAndLinkMasterData(temporaryList, salesforceErrors);

        if(!salesforceErrors.isEmpty()){
            createResponse(false, 'Master data validation error', null, '400', salesforceErrors, null, null, requestString);
            return;
        }

        Database.insert(temporaryList, true);
        createResponse(true, null, null, '200', new List<String>(), 'Insert TAM completado correctamente.', null, requestString);
    }

    private static String getPicklistMonth(String monthNum) {
        if(String.isBlank(monthNum)) return null;
        Integer m = Integer.valueOf(monthNum);
        Map<Integer, String> monthMap = new Map<Integer, String>{
            01 => 'Jan', 02 => 'Feb', 03 => 'Mar', 04 => 'Apr', 05 => 'May', 06 => 'Jun',
            07 => 'Jul', 08 => 'Aug', 09 => 'Sep', 10 => 'Oct', 11 => 'Nov', 12 => 'Dec'
        };
        return monthMap.get(m);
    }

    private static void validateAndLinkMasterData(List<OM_VID_TAM__c> records, List<String> errors) {
        Set<String> accCodes = new Set<String>();
        Set<String> modCodes = new Set<String>();

        for(OM_VID_TAM__c r : records) {
            if(r.OM_AccountText__c != null) accCodes.add(r.OM_AccountText__c);
            if(r.OM_ProductCodeText__c != null) modCodes.add(r.OM_ProductCodeText__c);
        }

        Map<String, Id> accMap = new Map<String, Id>();
        for(Account a : [SELECT Id, SAP_Account_Number__c FROM Account WHERE SAP_Account_Number__c IN :accCodes]) 
            accMap.put(a.SAP_Account_Number__c.toUpperCase(), a.Id);

        Map<String, Id> modMap = new Map<String, Id>();
        for(Product2 p : [SELECT Id, OM_Product_Code_SIP__c FROM Product2 WHERE OM_Product_Code_SIP__c IN :modCodes]) 
            modMap.put(p.OM_Product_Code_SIP__c.toUpperCase(), p.Id);

        List<String> missA = new List<String>();
        for(String s : accCodes) if(!accMap.containsKey(s)) missA.add(s);
        if(!missA.isEmpty()) errors.add('ACCOUNTS NOT FOUND: ' + String.join(missA, ', '));
        
        List<String> missM = new List<String>();
        for(String s : modCodes) if(!modMap.containsKey(s)) missM.add(s);
        if(!missM.isEmpty()) errors.add('MODELS NOT FOUND: ' + String.join(missM, ', '));

        if(errors.isEmpty()) {
            for(OM_VID_TAM__c r : records) {
                r.Account__c = accMap.get(r.OM_AccountText__c);
                r.OM_ModelRef__c = modMap.get(r.OM_ProductCodeText__c);
            }
        }
    }

    private static void fillNumericData(OM_VID_TAM__c record, List<OM_SapFunctionsStyle.RrwsSCell> cells, Integer index){     
        record.Revenue__c = parseDecimal(cells.get(index).Value);
        record.RevenuePrev__c = parseDecimal(cells.get(index + 1).Value);
        record.RevenueVar__c = parseDecimal(cells.get(index + 2).Value);
        record.RevenueVarPercentage__c = parseDecimal(cells.get(index + 3).Value);
        
        record.Tonnes__c = parseDecimal(cells.get(index + 4).Value);
        record.TonnesPrev__c = parseDecimal(cells.get(index + 5).Value);
        record.TonnesVar__c = parseDecimal(cells.get(index + 6).Value);
        record.TonnesVarPercent__c = parseDecimal(cells.get(index + 7).Value);
        
        record.Volume_000_s__c = parseDecimal(cells.get(index + 8).Value);
        record.Volume000sPrev__c = parseDecimal(cells.get(index + 9).Value);
        record.Volume000sVar__c = parseDecimal(cells.get(index + 10).Value);
        record.Volume000sVarPercent__c = parseDecimal(cells.get(index + 11).Value);
        
        record.Precio__c = parseDecimal(cells.get(index + 12).Value);
        record.OM_VID_EuroTonnePrevious__c = parseDecimal(cells.get(index + 13).Value);
        record.OM_VID_EuroTonneVar__c = parseDecimal(cells.get(index + 14).Value);
        record.OM_VID_EuroTonneVarPercent__c = parseDecimal(cells.get(index + 15).Value);
        
        record.Precio_FF__c = parseDecimal(cells.get(index + 16).Value);
        record.PrecioFFPrev__c = parseDecimal(cells.get(index + 17).Value);
        record.PrecioFFVar__c = parseDecimal(cells.get(index + 18).Value);
        record.PrecioFFVarPercent__c = parseDecimal(cells.get(index + 19).Value);
    }

    private static Decimal parseDecimal(String value) {
        return String.isBlank(value) ? 0 : Decimal.valueOf(value.trim().replace(',', '.')).setScale(2, RoundingMode.HALF_UP);
    }

    public static void createResponse(Boolean status, String msg, String accountId, String code, List<String> errors, String successMessage, String sapCode, String requestParam) {
        SFWS_Response respWrapper = new SFWS_Response();
        respWrapper.status = status;
        respWrapper.msg = msg;
        respWrapper.salesforceErrors = errors;
        respWrapper.successMessage = successMessage;
        OM_Utils.IntegrationMsg.createRESTIntegrationMsg(OM_Utils.IntegrationMsg.INBOUND, '/actualTAMCalloutBW', 'INSERT');
        OM_Utils.IntegrationMsg.addBody(requestParam, JSON.serialize(respWrapper));
        OM_Utils.IntegrationMsg.addStatusAndRecord((status ? OM_Utils.IntegrationMsg.SUCCESS : OM_Utils.IntegrationMsg.ERROR), accountId, null, null);
        OM_Utils.IntegrationMsg.insertRecord();
    }
    
    public static String createJsonBWWrapper(String yearFrom, String monthFrom, String salesGroup) {
        OM_BW_Wrapper.BWFilter filterWrapper = new OM_BW_Wrapper.BWFilter(yearFrom, monthFrom, salesGroup);
        return JSON.serialize(filterWrapper);
    }
}