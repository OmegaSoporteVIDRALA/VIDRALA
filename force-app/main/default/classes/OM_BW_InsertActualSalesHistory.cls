public class OM_BW_InsertActualSalesHistory {
    
    // WRAPPER PARA LA RESPUESTA DEL WS DE SF
    public class SFWS_Response {
        public boolean status;
        public String msg;
        public String accountId;
        public String sapCode;
        public String code;
        public List<String> salesforceErrors;
        public String successMessage;
    }
    
    public static void createResponse(Boolean status, String msg, String accountId, String code, List<String> errors, String successMessage, String sapCode, String requestParam) {
        
        // Generate the response        
        SFWS_Response respWrapper = new SFWS_Response();
        respWrapper.status = status;
        respWrapper.msg = msg;
        respWrapper.accountId = accountId;
        respWrapper.sapCode = sapCode;
        respWrapper.code = code;
        respWrapper.salesforceErrors = errors;
        respWrapper.successMessage = successMessage;


        // Write the integration Message
        OM_Utils.IntegrationMsg.createRESTIntegrationMsg(OM_Utils.IntegrationMsg.INBOUND, '/actualSalesHistoryCalloutBW', 'INSERT');
        OM_Utils.IntegrationMsg.addBody(requestParam, JSON.serialize(respWrapper));
        OM_Utils.IntegrationMsg.addStatusAndRecord((status ? OM_Utils.IntegrationMsg.SUCCESS : OM_Utils.IntegrationMsg.ERROR), accountId, null, null );
        OM_Utils.IntegrationMsg.insertRecord();
        
    }
    
    public static String createJsonBWWrapper(String yearFrom, String yearTo, String monthFrom, String monthTo, 
                                             String salesOrganization, String salesGroup){
        
        
        OM_BW_Wrapper.BWFilter filterWrapper = new OM_BW_Wrapper.BWFilter(yearFrom, yearTo, monthFrom, monthTo, salesOrganization, salesGroup);
        
        return JSON.serialize(filterWrapper);
        
    }
        
    @Future (callout=true)
    public static void insertActualSalesHistory(String jsonBWFilter){
        
    	OM_BW_Wrapper.BWFilter filterWrapper = (OM_BW_Wrapper.BWFilter) JSON.deserialize(jsonBWFilter, OM_BW_Wrapper.BWFilter.class);
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
        OM_SapFunctionsStyle.W3query item = new OM_SapFunctionsStyle.W3query();
        item.Name = 'VAR_NAME_'+VAR_NAME;
        item.Value = 'VAR_20240626203032';
        itemList.add(item);
        
        OM_SapFunctionsStyle.W3query item2 = new OM_SapFunctionsStyle.W3query();
        item2.Name = 'VAR_VALUE_LOW_EXT_'+VAR_NAME;
        item2.Value = filterWrapper.monthFrom+'.'+filterWrapper.yearFrom; //P.e. 11.2024
        itemList.add(item2);
        OM_SapFunctionsStyle.W3query item3 = new OM_SapFunctionsStyle.W3query();
        item3.Name = 'VAR_VALUE_HIGH_EXT_'+VAR_NAME;
        item3.Value = filterWrapper.monthTo+'.'+filterWrapper.yearTo; //12.2024
        itemList.add(item3);
        VAR_NAME++;
        
        //Organización de ventas
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
        
        //Grupo de vendedores
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
        OM_SapFunctionsStyle.RrwsThxAxisData axis;
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
            createResponse(false, 'Error not known', null, '400', new list<String>{e.getMessage(), e.getStackTraceString()}, null, 'Bad request', requestString);
        }
    
    }
    
    public static void processActualSalesHistoryCalloutResponse(OM_SapFunctionsStyle.GetQueryViewDataResponse_element response, String requestString){
    
        List<Actual_Sales_History__c> actualSalesHistoryInsertList = new List<Actual_Sales_History__c>();
        String successMessage = 'Insert operations completed successfully.';
        String responseMessage = '';
        List<String> salesforceErrors = new List<String>();
    
        if(response != null){
            Integer cellOrdinalCounter = 0; 
            List<Map<String, String>> rawRows = new List<Map<String, String>>();
            Set<String> sapAccounts = new Set<String>();
            Set<String> productCodes = new Set<String>();
            Set<String> materialCodes = new Set<String>();
    
            for(OM_SapFunctionsStyle.RrwsSxAxisData axis : response.AxisData.item){  
                Integer tupleCounter = 0;
                Actual_Sales_History__c actSH = new Actual_Sales_History__c();
                if(axis.axis == '001'){
                    Boolean excludeLogic = false;
                    for(OM_SapFunctionsStyle.RrwsSxTuple item : axis.Set_x.item){
                        if(tupleCounter == Integer.ValueOf(item.TupleOrdinal)){
                            Map<String,String> row = new Map<String,String>();
    
                            if(item.Chanm == '0CALMONTH'){
                                actSH.Year__c = item.Chavl.substring(0,4);
                                actSH.Month__c = OM_Utils.Strings.getMonthAbbreviation(Integer.valueOf(item.Chavl.substring(4,6)));
                            } else if(item.Chanm == '0SALESORG'){
                                actSH.Sales_Organization__c = item.ChavlExt;
                            } else if(item.Chanm == '0CUST_SALES__ZCUS_SALE'){
                                // Grupo cliente
                            } else if(item.Chanm == '0SOLD_TO'){
                                row.put('ACCOUNT', item.ChavlExt.toUpperCase());
                                sapAccounts.add(item.ChavlExt.toUpperCase());
                                actSH.OM_AccountText__c = item.ChavlExt;
                            } else if(item.Chanm == '0MATERIAL__ZISDMODEL' && !String.isBlank(item.ChavlExt) && item.ChavlExt != '#'){
                                row.put('PRODUCT', item.ChavlExt.toUpperCase());
                                productCodes.add(item.ChavlExt.toUpperCase());
                                actSH.OM_ProductCodeText__c = item.ChavlExt;
                            } else if(item.Chanm == '0MATERIAL' && !String.isBlank(item.ChavlExt)){
                                if(item.Chavl.replaceFirst('^0+', '').length() == 5 || item.Chavl.replaceFirst('^0+', '').equals('GEN_VENTAS')){
                                    row.put('MATERIAL', item.ChavlExt.toUpperCase()); 
                                    materialCodes.add(item.ChavlExt.toUpperCase());
                                    actSH.OM_MaterialCodeText__c = item.ChavlExt;
                                } else {
                                    excludeLogic = true;
                                }
    
                                actSH.Revenue__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter).Value);
                                actSH.RevenuePrev__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 1).Value);
                                actSH.RevenueVar__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 2).Value);
                                actSH.RevenueVarPercentage__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 3).Value);
                                
                                actSH.Tonnes__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 4).Value);
                                actSH.TonnesPrev__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 5).Value);
                                actSH.TonnesVar__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 6).Value);
                                actSH.TonnesVarPercent__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 7).Value);
                                
                                actSH.Volume_000_s__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 8).Value);
                                actSH.Volume000sPrev__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 9).Value);
                                actSH.Volume000sVar__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 10).Value);
                                actSH.Volume000sVarPercent__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 11).Value);
                                
                                actSH.OM_VID_EuroTonnePrevious__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 13).Value);
                                actSH.OM_VID_EuroTonneVar__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 14).Value);
                                actSH.OM_VID_EuroTonneVarPercent__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 15).Value);
                                
                                actSH.Precio_FF__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 16).Value);
                                actSH.PrecioFFPrev__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 17).Value);
                                actSH.PrecioFFVar__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 18).Value);
                                actSH.PrecioFFVarPercent__c = parseDecimal(response.cellData.item.get(cellOrdinalCounter + 19).Value);
    
                                rawRows.add(row);
                                cellOrdinalCounter += 20;
                                tupleCounter++;
                                actSH = new Actual_Sales_History__c();
                                excludeLogic = false;
                            }
                        }
                    }
                }
            }
    
            Map<String, Account> accountMap = new Map<String, Account>();
            if(!sapAccounts.isEmpty()){
                for(Account a : [SELECT Id, SAP_Account_Number__c FROM Account WHERE SAP_Account_Number__c IN :sapAccounts]){
                    accountMap.put(a.SAP_Account_Number__c.toUpperCase(), a);
                }
            }
    
            Map<String, Product2> productMap = new Map<String, Product2>();
            if(!productCodes.isEmpty()){
                for(Product2 p : [SELECT Id, OM_Product_Code_SIP__c FROM Product2 WHERE OM_Product_Code_SIP__c IN :productCodes]){
                    productMap.put(p.OM_Product_Code_SIP__c.toUpperCase(), p);
                }
            }
    
            Map<String, SAP_Material_Code__c> materialMap = new Map<String, SAP_Material_Code__c>();
            if(!materialCodes.isEmpty()){
                for(SAP_Material_Code__c m : [SELECT Id, Material_Code_Key__c FROM SAP_Material_Code__c WHERE Material_Code_Key__c IN :materialCodes]){
                    materialMap.put(m.Material_Code_Key__c.toUpperCase(), m);
                }
            }
    
            for(Map<String,String> row : rawRows){
                if(!accountMap.containsKey(row.get('ACCOUNT'))){
                    salesforceErrors.add('Account not found: ' + row.get('ACCOUNT'));
                    break;
                }
                if(!productMap.containsKey(row.get('PRODUCT'))){
                    salesforceErrors.add('Product not found: ' + row.get('PRODUCT'));
                    break;
                }
                if(!materialMap.containsKey(row.get('MATERIAL'))){
                    salesforceErrors.add('Material not found: ' + row.get('MATERIAL'));
                    break;
                }
    
                Actual_Sales_History__c rec = new Actual_Sales_History__c();
                rec.Account__c = accountMap.get(row.get('ACCOUNT')).Id;
                rec.OM_ModelRef__c = productMap.get(row.get('PRODUCT')).Id;
                rec.SAP_Material_Code__c = materialMap.get(row.get('MATERIAL')).Id;
    
                rec.Revenue__c = parseDecimal(row.get('REV'));
                rec.Tonnes__c = parseDecimal(row.get('TON'));
                actualSalesHistoryInsertList.add(rec);
            }
    
             if(!salesforceErrors.isEmpty()){
                createResponse(false, 'Validation error', null, '400', salesforceErrors, null, null, requestString);
                return;
            }
    
            if(actualSalesHistoryInsertList.size() > 0){
                Database.insert(actualSalesHistoryInsertList, true);
                createResponse(true, responseMessage, null, '200', new List<String>(), successMessage, null, requestString);
            }
        }
    
    }
    
    private static Decimal parseDecimal(String value) {
        return String.isBlank(value) ? 0 : Decimal.valueOf(value).setScale(2, RoundingMode.HALF_UP);
    }
}