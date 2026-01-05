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
        String query = 'ZMSDF_11_PYGACC_SF'; //ActualSalesHistory - Pasar a CustomMetadata
        Integer VAR_NAME = 1; //Contador variables
        
        /*Parámetros de entrada posibles para este servicio y su orden:
         * 1. Moneda destino --> ZCURVAR2
         * 2. Mes.Año --> VAR_20240626203032: VAR_VALUE_LOW_EXT_1 (Fecha desde) y VAR_VALUE_HIGH_EXT_1 (Fecha hasta) 01.2024
         * 3. Organización de Ventas --> VAR_20241107114952 
         * 4. Grupo de Vendedores --> VAR_20241220095416
         **/
        
        OM_SapFunctionsStyle.CDSS cdss = new OM_SapFunctionsStyle.CDSS();
        List<OM_SapFunctionsStyle.W3query> itemList = new List<OM_SapFunctionsStyle.W3query>();
        
        //FECHAS
        itemList.add(new OM_SapFunctionsStyle.W3query('VAR_NAME_'+VAR_NAME, 'VAR_20240626203032'));
        itemList.add(new OM_SapFunctionsStyle.W3query('VAR_VALUE_LOW_EXT_'+VAR_NAME, filterWrapper.monthFrom+'.'+filterWrapper.yearFrom)); //P.e. 11.2024
        itemList.add(new OM_SapFunctionsStyle.W3query('VAR_VALUE_HIGH_EXT_'+VAR_NAME, filterWrapper.monthTo+'.'+filterWrapper.yearTo)); //12.2024
        VAR_NAME++;
        
        //Organización de ventas
        if(filterWrapper.salesOrganization != null){
            itemList.add(new OM_SapFunctionsStyle.W3query('VAR_NAME_'+VAR_NAME, 'VAR_20241107114952'));
            itemList.add(new OM_SapFunctionsStyle.W3query('VAR_VALUE_EXT_'+VAR_NAME, filterWrapper.salesOrganization)); 
            VAR_NAME++;
        }
        
        //Grupo de vendedores
        if(filterWrapper.salesGroup != null){
            itemList.add(new OM_SapFunctionsStyle.W3query('VAR_NAME_'+VAR_NAME, 'VAR_20241220095416'));
            itemList.add(new OM_SapFunctionsStyle.W3query('VAR_VALUE_EXT_'+VAR_NAME, filterWrapper.salesGroup)); 
            VAR_NAME++;
        }      
        
        OM_SapFunctionsStyle.Rrxw3tquery parameter = new OM_SapFunctionsStyle.Rrxw3tquery();    
        parameter.item = itemList;
        String requestString = parameter.toString();

        try{
            OM_SapFunctionsStyle.GetQueryViewDataResponse_element response = cdss.GetQueryViewData(infoProvider, parameter, query, null);
            System.debug('***response: '+response);
            if(response != null && response.axisData != null){
                System.debug('Entra por la response');
                processActualSalesHistoryCalloutResponse(response, requestString);
            }
        }catch(Exception e){
            System.debug('Exception Entra por aqui: '+e.getMessage());
            createResponse(false, 'Error not known', null, '400', new List<String>{e.getMessage(), e.getStackTraceString()}, null, 'Bad request', requestString);
        }
    }
    public static void processActualSalesHistoryCalloutResponse(OM_SapFunctionsStyle.GetQueryViewDataResponse_element response, String requestString) {
        List<Actual_Sales_History__c> temporaryList = new List<Actual_Sales_History__c>();
        List<String> salesforceErrors = new List<String>();
        Integer cellOrdinalCounter = 0;

        for(OM_SapFunctionsStyle.RrwsSxAxisData axis : response.AxisData.item) {
            if(axis.axis != '001') continue;
            Actual_Sales_History__c actSH = new Actual_Sales_History__c();
            Integer tupleCounter = 0;

            for(OM_SapFunctionsStyle.RrwsSxTuple item : axis.Set_x.item) {
                if(tupleCounter != Integer.valueOf(item.TupleOrdinal)) continue;

                if(item.Chanm == '0CALMONTH') {
                    actSH.Year__c = item.Chavl.substring(0,4);
                    actSH.Month__c = OM_Utils.Strings.getMonthAbbreviation(Integer.valueOf(item.Chavl.substring(4,6)));
                } else if(item.Chanm == '0SALESORG') {
                    actSH.Sales_Organization__c = item.ChavlExt;
                } else if(item.Chanm == '0SOLD_TO') {
                    actSH.OM_AccountText__c = item.ChavlExt.toUpperCase();
                } else if(item.Chanm == '0MATERIAL__ZISDMODEL' && String.isNotBlank(item.ChavlExt) && item.ChavlExt != '#') {
                    actSH.OM_ProductCodeText__c = item.ChavlExt.toUpperCase();
                } else if(item.Chanm == '0MATERIAL' && String.isNotBlank(item.ChavlExt)) {
                    String cleanMat = item.Chavl.replaceFirst('^0+', '');
                    if(cleanMat.length() == 5 || cleanMat.equals('GEN_VENTAS')) {
                        actSH.OM_MaterialCodeText__c = item.ChavlExt.toUpperCase();
                        processCellData(actSH, response.cellData.item, cellOrdinalCounter);
                        temporaryList.add(actSH);
                        cellOrdinalCounter += 20;
                    }
                    actSH = new Actual_Sales_History__c();
                    tupleCounter++;
                }
            }
        }

        if(temporaryList.isEmpty()) return;

        validateData(temporaryList, salesforceErrors);

        if(!salesforceErrors.isEmpty()){
            createResponse(false, 'Master data validation error', null, '400', salesforceErrors, null, null, requestString);
            return;
        }

        Database.insert(temporaryList, true);
        createResponse(true, null, null, '200', new List<String>(), 'Inserted ' + temporaryList.size() + ' records', null, requestString);
    }

    private static void validateData(List<Actual_Sales_History__c> records, List<String> errors) {
        Set<String> accCodes = new Set<String>();
        Set<String> prodCodes = new Set<String>();
        Set<String> matCodes = new Set<String>();

        for(Actual_Sales_History__c r : records) {
            accCodes.add(r.OM_AccountText__c);
            prodCodes.add(r.OM_ProductCodeText__c);
            matCodes.add(r.OM_MaterialCodeText__c);
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

    private static void processCellData(Actual_Sales_History__c rec, List<OM_SapFunctionsStyle.RrwsSCell> cells, Integer idx) {
        rec.Revenue__c = parseDecimal(cells.get(idx).Value);
        rec.RevenuePrev__c = parseDecimal(cells.get(idx + 1).Value);
        rec.RevenueVar__c = parseDecimal(cells.get(idx + 2).Value);
        rec.RevenueVarPercentage__c = parseDecimal(cells.get(idx + 3).Value);
        
        rec.Tonnes__c = parseDecimal(cells.get(idx + 4).Value);
        rec.TonnesPrev__c = parseDecimal(cells.get(idx + 5).Value);
        rec.TonnesVar__c = parseDecimal(cells.get(idx + 6).Value);
        rec.TonnesVarPercent__c = parseDecimal(cells.get(idx + 7).Value);
        
        rec.Volume_000_s__c = parseDecimal(cells.get(idx + 8).Value);
        rec.Volume000sPrev__c  = parseDecimal(cells.get(idx + 9).Value);
        rec.Volume000sVar__c = parseDecimal(cells.get(idx + 10).Value);
        rec.Volume000sVarPercent__c = parseDecimal(cells.get(idx + 11).Value);
        
        //record.OM_VID_EuroTonne__c es una fórmula en Salesforce
        rec.OM_VID_EuroTonnePrevious__c = parseDecimal(cells.get(idx + 13).Value);
        rec.OM_VID_EuroTonneVar__c = parseDecimal(cells.get(idx + 14).Value);
        rec.OM_VID_EuroTonneVarPercent__c = parseDecimal(cells.get(idx + 15).Value);
        
        rec.Precio_FF__c = parseDecimal(cells.get(idx + 16).Value);
        rec.PrecioFFPrev__c = parseDecimal(cells.get(idx + 17).Value);
        rec.PrecioFFVar__c = parseDecimal(cells.get(idx + 18).Value);
        rec.PrecioFFVarPercent__c = parseDecimal(cells.get(idx + 19).Value);
    }

    private static Decimal parseDecimal(String v) {
        return String.isBlank(v) ? 0 : Decimal.valueOf(v.trim().replace(',', '.')).setScale(2, RoundingMode.HALF_UP);
    }

    public static void createResponse(Boolean status, String msg, String accId, String code, List<String> errs, String success, String sap, String req) {
        SFWS_Response resp = new SFWS_Response();
        resp.status = status; resp.msg = msg; resp.accountId = accId; resp.sapCode = sap; resp.code = code;
        resp.salesforceErrors = errs; resp.successMessage = success;
        OM_Utils.IntegrationMsg.createRESTIntegrationMsg(OM_Utils.IntegrationMsg.INBOUND, '/actualSalesHistoryCalloutBW', 'INSERT');
        OM_Utils.IntegrationMsg.addBody(req, JSON.serialize(resp));
        OM_Utils.IntegrationMsg.addStatusAndRecord((status ? OM_Utils.IntegrationMsg.SUCCESS : OM_Utils.IntegrationMsg.ERROR), accId, null, null );
        OM_Utils.IntegrationMsg.insertRecord();
    }

    public static String createJsonBWWrapper(String yF, String yT, String mF, String mT, String sO, String sG){
        return JSON.serialize(new OM_BW_Wrapper.BWFilter(yF, yT, mF, mT, sO, sG));
    }
}