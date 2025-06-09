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
        //List<String> excludeAccounts = new List<String> {'11787','34336','34314','34173','34025','33653','33559','33128','11326'};
        if(response != null){
             //Empieza en el 1, porque el Tuple 0 lo ignoramos al ser sólo datos de cabecera.
            Integer cellOrdinalCounter = 0; //Son los valores, se cogen de 4 en 4, cada vez que se cambie de registro se suma 4.
            for(OM_SapFunctionsStyle.RrwsSxAxisData axis : response.AxisData.item){	
                Integer tupleCounter = 0;
                Actual_Sales_History__c actSH = new Actual_Sales_History__c();
                if(axis.axis == '001'){ //Ignoramos el primero, son solo datos de cabecera
                    Boolean excludeLogic = false;
                    for(OM_SapFunctionsStyle.RrwsSxTuple item : axis.Set_x.item){
                        System.debug('este es el tupleOrdinal: '+Integer.ValueOf(item.TupleOrdinal));
                        System.debug('este es el tupleCounter: '+tupleCounter);
                        if(tupleCounter == Integer.ValueOf(item.TupleOrdinal) /*|| item.Caption != 'Resultado'*/){
                            //Continuamos rellenando datos del registro
                            System.debug('***esta es la variable: '+item.Chanm);
                            
                            if(item.Chanm == '0CALMONTH'){ //Se coge el año y mes
                                actSH.Year__c = item.Chavl.substring(0,4);
                                actSH.Month__c = OM_Utils.Strings.getMonthAbbreviation(Integer.valueOf(item.Chavl.substring(4,6)));
                                    
                            }else if(item.Chanm == '0SALESORG'){ //Se coge la organización de ventas
                                actSH.Sales_Organization__c = item.ChavlExt;
                            }else if(item.Chanm == '0CUST_SALES__ZCUS_SALE'){ //Se coge Grupo Cliente
                                //Mirar si crear el campo Grupo cliente en Actual Sales History.
                            }else if(item.Chanm == '0SOLD_TO'){ //Se coge Cliente
                                //if(excludeAccounts.contains(item.ChavlExt)) excludeLogic = true; //ESTO SE VA A TENER QUE QUITAR
                                Account accountReference = new Account(SAP_Account_Number__c =  item.ChavlExt);
                                //Account accountReference = new Account(SAP_Account_Number__c = '11268');
                                actSH.Account__r = accountReference;
                                actSH.OM_AccountText__c = item.ChavlExt;
                            }else if(item.Chanm == '0MATERIAL__ZISDMODEL' && !String.isBlank(item.ChavlExt) && item.ChavlExt != '#'){ //Se coge Modelo
                                Product2 modelReference = new Product2(OM_Product_Code_SIP__c = item.ChavlExt);
                                //Product2 modelReference = new Product2(OM_Product_Code_SIP__c = '1001476O');
                                actSH.OM_ProductCodeText__c = item.ChavlExt;
                                actSH.OM_ModelRef__r = modelReference;
                                
                                //actSH.OM_ModelRef__r = modelReference;
                            }else if(item.Chanm == '0MATERIAL' && !String.isBlank(item.ChavlExt)){ //Se coge Material
                                if(item.Chavl.replaceFirst('^0+', '').length() == 5 || item.Chavl.replaceFirst('^0+', '').equals('GEN_VENTAS')){ //Solo se incluyen materiales de 5 dígitos o que se llamen GEN_VENTAS
                                    SAP_Material_Code__c materialReference = new SAP_Material_Code__c(Material_Code_Key__c = item.ChavlExt);
                                    actSH.SAP_Material_Code__r = materialReference;
                                    actSH.OM_MaterialCodeText__c = item.ChavlExt;
                                    excludeLogic = false;
                                }else{
                                    excludeLogic = true;
                                }

                                if(!String.isBlank(response.cellData.item.get(cellOrdinalCounter).Value)){
                                    actSH.Revenue__c = Decimal.ValueOf(response.cellData.item.get(cellOrdinalCounter).Value).setScale(2, RoundingMode.HALF_UP); //El primer valor siempre es Revenue__c
                                }else{
                                    actSH.Revenue__c = 0;
                                }
                                
                                if(!String.isBlank(response.cellData.item.get(cellOrdinalCounter+1).Value)){
                                    actSH.Tonnes__c = Decimal.ValueOf(response.cellData.item.get(cellOrdinalCounter+1).Value).setScale(2, RoundingMode.HALF_UP); //El segundo valor siempre es Tonnes__c
                                }else{
                                    actSH.Tonnes__c = 0;
                                }
                                
                                if(!String.isBlank(response.cellData.item.get(cellOrdinalCounter+2).Value)){
                                   actSH.Volume_000_s__c = Decimal.ValueOf(response.cellData.item.get(cellOrdinalCounter+2).Value).setScale(2, RoundingMode.HALF_UP); //El tercer valor siempre es Volume_000_s__c 
                                }else{
                                    actSH.Volume_000_s__c = 0;
                                }
                                
                                if(!String.isBlank(response.cellData.item.get(cellOrdinalCounter+3).Value)){
                                    actSH.Precio_FF__c = Decimal.ValueOf(response.cellData.item.get(cellOrdinalCounter+3).Value).setScale(2, RoundingMode.HALF_UP);//El cuarto valor siempre es Precio Francofábrica
                                }else{
                                    actSH.Precio_FF__c = 0;
                                }
                                
        						System.debug('***asigna actSH: '+actSH);
                                if(!excludeLogic) actualSalesHistoryInsertList.add(actSH);
                            //}
                            
                                cellOrdinalCounter = cellOrdinalCounter+4; 
                                actSH = new Actual_Sales_History__c();
                                excludeLogic = false;
                                tupleCounter++;
                            }
                        }        
                	}
                }
            }
            
            if(actualSalesHistoryInsertList.size() > 0){
                System.debug('***actualSalesHistoryInsertList : '+actualSalesHistoryInsertList);
                System.debug('***actualSalesHistoryInsertList.size : '+actualSalesHistoryInsertList.size());
                Database.SaveResult[] actualSalesHistoryInsertResults = Database.insert(actualSalesHistoryInsertList, true);
                Map<String, String> insertErrors = OM_Utils.DmlResults.getErrorsMap(actualSalesHistoryInsertResults, actualSalesHistoryInsertList, 'OM_AccountText__c');
			
                if(!insertErrors.isEmpty()){ // manage the errors
                    salesforceErrors.add('Exception trying to upsert Account: ' + JSON.serialize(insertErrors));
                }else{ // If no errors for accounts, we can continue with the junction records
                    /** Start building the account SalesArea Junction record */
                    
                    /** End building the account SalesArea Junction record */
                    
                }
                System.debug('***salesforceErrors: '+salesforceErrors);
                
                 // Determine response based on errors
                if (salesforceErrors.isEmpty()) {
                    createResponse(true, responseMessage, null, '200', salesforceErrors, successMessage, null, requestString);
                    // RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
                } else {
                    createResponse(false, responseMessage, null, '200', salesforceErrors, null, null, requestString);
                    
                }
            }
        }
    }
}