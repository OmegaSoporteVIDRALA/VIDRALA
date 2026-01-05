public class OM_BW_InsertActualSalesHistory {

    public class SFWS_Response {
        public boolean status;
        public String msg;
        public String accountId;
        public String sapCode;
        public String code;
        public List<String> salesforceErrors;
        public String successMessage;
    }

    @Future (callout=true)
    public static void insertActualSalesHistory(String jsonFilter){
        OM_BW_Wrapper.BWFilter filterWrapper = (OM_BW_Wrapper.BWFilter) JSON.deserialize(jsonFilter, OM_BW_Wrapper.BWFilter.class);
        actualSalesHistoryCalloutBW(filterWrapper);
    }

    public static void actualSalesHistoryCalloutBW(OM_BW_Wrapper.BWFilter filterWrapper){
        
        String infoProvider = 'ZMSDF_11';
        String query = 'ZMSDF_11_PYGACC_SF'; 
        Integer VAR_NAME = 1; 
        
        /*Parámetros de entrada posibles para este servicio y su orden:
         * 1. Moneda destino --> ZCURVAR2
         * 2. Mes.Año --> VAR_20240626203032: VAR_VALUE_LOW_EXT_1 (Fecha desde) y VAR_VALUE_HIGH_EXT_1 (Fecha hasta) 01.2024
         * 3. Organización de Ventas --> VAR_20241107114952 
         * 4. Grupo de Vendedores --> VAR_20241220095416
         **/
        
        OM_SapFunctionsStyle.CDSS cdss = new OM_SapFunctionsStyle.CDSS();
        List<OM_SapFunctionsStyle.W3query> itemList = new List<OM_SapFunctionsStyle.W3query>();
        
         OM_SapFunctionsStyle.W3query item1 = new OM_SapFunctionsStyle.W3query();
        item1.Name = 'VAR_NAME_'+VAR_NAME;
        item1.Value = 'VAR_20240626203032';
        itemList.add(item1);
        
        OM_SapFunctionsStyle.W3query item2 = new OM_SapFunctionsStyle.W3query();
        item2.Name = 'VAR_VALUE_LOW_EXT_'+VAR_NAME;
        item2.Value = filterWrapper.monthFrom+'.'+filterWrapper.yearFrom; 
        itemList.add(item2);

        OM_SapFunctionsStyle.W3query item3 = new OM_SapFunctionsStyle.W3query();
        item3.Name = 'VAR_VALUE_HIGH_EXT_'+VAR_NAME;
        item3.Value = filterWrapper.monthTo+'.'+filterWrapper.yearTo; 
        itemList.add(item3);
        VAR_NAME++;
        
        // --- ORGANIZACIÓN DE VENTAS ---
        if(filterWrapper.salesOrganization != null){
            OM_SapFunctionsStyle.W3query item4 = new OM_SapFunctionsStyle.W3query();
            item4.Name = 'VAR_NAME_'+VAR_NAME;
            item4.Value = 'VAR_20241107114952';
            itemList.add(item4);

            OM_SapFunctionsStyle.W3query item5 = new OM_SapFunctionsStyle.W3query();
            item5.Name = 'VAR_VALUE_EXT_'+VAR_NAME;
            item5.Value = filterWrapper.salesOrganization; 
            itemList.add(item5);
            VAR_NAME++;
        }
        
        // --- GRUPO DE VENDEDORES ---
        if(filterWrapper.salesGroup != null){
            OM_SapFunctionsStyle.W3query item6 = new OM_SapFunctionsStyle.W3query();
            item6.Name = 'VAR_NAME_'+VAR_NAME;
            item6.Value = 'VAR_20241220095416';
            itemList.add(item6);

            OM_SapFunctionsStyle.W3query item7 = new OM_SapFunctionsStyle.W3query();
            item7.Name = 'VAR_VALUE_EXT_'+VAR_NAME;
            item7.Value = filterWrapper.salesGroup; 
            itemList.add(item7);
            VAR_NAME++;
        }      
        
        OM_SapFunctionsStyle.Rrxw3tquery parameter = new OM_SapFunctionsStyle.Rrxw3tquery();    
        parameter.item = itemList;
        String requestString = parameter.toString();

        try{
            OM_SapFunctionsStyle.GetQueryViewDataResponse_element response = cdss.GetQueryViewData(infoProvider, parameter, query, null);
            if(response != null && response.axisData != null){
                processActualSalesHistoryCalloutResponse(response, requestString);
            }
        }catch(Exception e){
            createResponse(false, 'Error not known', null, '400', new List<String>{e.getMessage(), e.getStackTraceString()}, null, 'Bad request', requestString);
        }
    }

    public static void processActualSalesHistoryCalloutResponse(OM_SapFunctionsStyle.GetQueryViewDataResponse_element response, String requestString){
        List<Actual_Sales_History__c> temporaryList = new List<Actual_Sales_History__c>();
        List<String> salesforceErrors = new List<String>();
        Integer cellOrdinalCounter = 0; 

        for(OM_SapFunctionsStyle.RrwsSxAxisData axis : response.AxisData.item){ 
            if(axis.axis == '001'){ 
                Integer tupleCounter = 0;
                Actual_Sales_History__c actSH = new Actual_Sales_History__c();

                for(OM_SapFunctionsStyle.RrwsSxTuple item : axis.Set_x.item){
                    if(tupleCounter == Integer.valueOf(item.TupleOrdinal)){
                        
                        // Mapeo de Dimensiones
                        if(item.Chanm == '0CALMONTH'){ 
                            actSH.Year__c = item.Chavl.substring(0,4);
                            actSH.Month__c = OM_Utils.Strings.getMonthAbbreviation(Integer.valueOf(item.Chavl.substring(4,6)));
                        }else if(item.Chanm == '0SALESORG'){ 
                            actSH.Sales_Organization__c = item.ChavlExt;
                        }else if(item.Chanm == '0SOLD_TO'){ 
                            actSH.OM_AccountText__c = item.ChavlExt.toUpperCase();
                        }else if(item.Chanm == '0MATERIAL__ZISDMODEL' && !String.isBlank(item.ChavlExt) && item.ChavlExt != '#'){ 
                            actSH.OM_ProductCodeText__c = item.ChavlExt.toUpperCase();
                        }else if(item.Chanm == '0MATERIAL' && !String.isBlank(item.ChavlExt)){ 
                            String cleanMat = item.Chavl.replaceFirst('^0+', '');
                            if(cleanMat.length() == 5 || cleanMat.equals('GEN_VENTAS')){ 
                                actSH.OM_MaterialCodeText__c = item.ChavlExt.toUpperCase();
                                fillNumericData(actSH, response.cellData.item, cellOrdinalCounter);
                                temporaryList.add(actSH);
                                cellOrdinalCounter = cellOrdinalCounter + 20; 
                            }
                            actSH = new Actual_Sales_History__c();
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
        createResponse(true, null, null, '200', new List<String>(), 'Insert operations completed successfully.', null, requestString);
    }

    private static void validateAndLinkMasterData(List<Actual_Sales_History__c> records, List<String> errors) {
        Set<String> accCodes = new Set<String>();
        Set<String> prodCodes = new Set<String>();
        Set<String> matCodes = new Set<String>();

        for(Actual_Sales_History__c r : records) {
            if(r.OM_AccountText__c != null) accCodes.add(r.OM_AccountText__c);
            if(r.OM_ProductCodeText__c != null) prodCodes.add(r.OM_ProductCodeText__c);
            if(r.OM_MaterialCodeText__c != null) matCodes.add(r.OM_MaterialCodeText__c);
        }

        Map<String, Id> accMap = new Map<String, Id>();
        for(Account a : [SELECT Id, SAP_Account_Number__c FROM Account WHERE SAP_Account_Number__c IN :accCodes]) 
            accMap.put(a.SAP_Account_Number__c.toUpperCase(), a.Id);

        Map<String, Id> prodMap = new Map<String, Id>();
        for(Product2 p : [SELECT Id, OM_Product_Code_SIP__c FROM Product2 WHERE OM_Product_Code_SIP__c IN :prodCodes]) 
            prodMap.put(p.OM_Product_Code_SIP__c.toUpperCase(), p.Id);

        Map<String, Id> matMap = new Map<String, Id>();
        for(SAP_Material_Code__c m : [SELECT Id, Material_Code_Key__c FROM SAP_Material_Code__c WHERE Material_Code_Key__c IN :matCodes]) 
            matMap.put(m.Material_Code_Key__c.toUpperCase(), m.Id);

        List<String> missA = new List<String>();
        for(String s : accCodes) if(!accMap.containsKey(s)) missA.add(s);
        if(!missA.isEmpty()) errors.add('ACCOUNTS NOT FOUND: ' + String.join(missA, ', '));
        
        List<String> missP = new List<String>();
        for(String s : prodCodes) if(!prodMap.containsKey(s)) missP.add(s);
        if(!missP.isEmpty()) errors.add('PRODUCTS NOT FOUND: ' + String.join(missP, ', '));

        List<String> missM = new List<String>();
        for(String s : matCodes) if(!matMap.containsKey(s)) missM.add(s);
        if(!missM.isEmpty()) errors.add('MATERIALS NOT FOUND: ' + String.join(missM, ', '));

        if(errors.isEmpty()) {
            for(Actual_Sales_History__c r : records) {
                r.Account__c = accMap.get(r.OM_AccountText__c);
                r.OM_ModelRef__c = prodMap.get(r.OM_ProductCodeText__c);
                r.SAP_Material_Code__c = matMap.get(r.OM_MaterialCodeText__c);
            }
        }
    }

    private static void fillNumericData(Actual_Sales_History__c actSH, List<OM_SapFunctionsStyle.RrwsSCell> cells, Integer cellOrdinalCounter) {
        
        actSH.Revenue__c = parseDecimal(cells.get(cellOrdinalCounter).Value);
        actSH.RevenuePrev__c = parseDecimal(cells.get(cellOrdinalCounter + 1).Value);
        actSH.RevenueVar__c = parseDecimal(cells.get(cellOrdinalCounter + 2).Value);
        actSH.RevenueVarPercentage__c = parseDecimal(cells.get(cellOrdinalCounter + 3).Value);
        
        actSH.Tonnes__c = parseDecimal(cells.get(cellOrdinalCounter + 4).Value);
        actSH.TonnesPrev__c = parseDecimal(cells.get(cellOrdinalCounter + 5).Value);
        actSH.TonnesVar__c = parseDecimal(cells.get(cellOrdinalCounter + 6).Value);
        actSH.TonnesVarPercent__c = parseDecimal(cells.get(cellOrdinalCounter + 7).Value);
        
        actSH.Volume_000_s__c = parseDecimal(cells.get(cellOrdinalCounter + 8).Value);
        actSH.Volume000sPrev__c = parseDecimal(cells.get(cellOrdinalCounter + 9).Value);
        actSH.Volume000sVar__c = parseDecimal(cells.get(cellOrdinalCounter + 10).Value);
        actSH.Volume000sVarPercent__c = parseDecimal(cells.get(cellOrdinalCounter + 11).Value);
        
        //record.OM_VID_EuroTonne__c es una fórmula en Salesforce
        actSH.OM_VID_EuroTonnePrevious__c = parseDecimal(cells.get(cellOrdinalCounter + 13).Value);
        actSH.OM_VID_EuroTonneVar__c = parseDecimal(cells.get(cellOrdinalCounter + 14).Value);
        actSH.OM_VID_EuroTonneVarPercent__c = parseDecimal(cells.get(cellOrdinalCounter + 15).Value);
        
        actSH.Precio_FF__c = parseDecimal(cells.get(cellOrdinalCounter + 16).Value);
        actSH.PrecioFFPrev__c = parseDecimal(cells.get(cellOrdinalCounter + 17).Value);
        actSH.PrecioFFVar__c = parseDecimal(cells.get(cellOrdinalCounter + 18).Value);
        actSH.PrecioFFVarPercent__c = parseDecimal(cells.get(cellOrdinalCounter + 19).Value);
    }

    private static Decimal parseDecimal(String value) {
        return String.isBlank(value) ? 0 : Decimal.valueOf(value.trim().replace(',', '.')).setScale(2, RoundingMode.HALF_UP);
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
        OM_Utils.IntegrationMsg.addStatusAndRecord((status ? OM_Utils.IntegrationMsg.SUCCESS : OM_Utils.IntegrationMsg.ERROR), accountId, null, null );
        OM_Utils.IntegrationMsg.insertRecord();
    }

    public static String createJsonBWWrapper(String yF, String yT, String mF, String mT, String sO, String sG){
        return JSON.serialize(new OM_BW_Wrapper.BWFilter(yF, yT, mF, mT, sO, sG));
    }
}