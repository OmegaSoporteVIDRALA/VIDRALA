public class OM_BW_AbonosDevolucionesCallout {

    public static String createJsonBWWrapper(String yearFrom, String yearTo, String monthFrom, String monthTo, String customerCode, 
    String shippingAddressCode, List<String> orderReason, String model, String material, String batch){
        
        
        OM_BW_Wrapper.BWFilter filterWrapper = new OM_BW_Wrapper.BWFilter(yearFrom, yearTo, monthFrom, monthTo, customerCode, 
        shippingAddressCode, orderReason, model, material, batch);
        
        return JSON.serialize(filterWrapper);
        
    }
    
    public static OM_BW_Wrapper.BWReport abonosDevolucionesSACCalloutBW(OM_BW_Wrapper.BWFilter filterWrapper){
        
        OM_BW_Wrapper.BWReport bwReport = new OM_BW_Wrapper.BWReport();
        String infoProvider = 'ZMSDF_04';
	    String query = 'ZMSDF_04_SW_SF'; //VENTAS - Pasar a CustomMetadata
        Integer VAR_NAME = 1; //Contador variables
        
        /*Parámetros de entrada posibles para este servicio y su orden:
         * 1. Mes.Año --> VAR_20240626203032: VAR_VALUE_LOW_EXT_1 (Fecha desde) y VAR_VALUE_HIGH_EXT_1 (Fecha hasta) 01.2024
         * 2. Cliente SD --> VAR_20241111115217: Código SAP Cliente
         * 3. Destinatario de mercancía --> VAR_20241111115841: Código SAP Destinatario
         * 4. Lote --> VAR_20241111135720: Lote
         * 5. Moneda Destino --> ZCURVAR2
         * 6. Modelo --> VAR_20240627081033
         * 7. Material --> VAR_20241212092640
         * 8. Motivo de Pedido --> VAR_20250220142923: Posibles valores? --
         **/
        
        OM_SapFunctionsStyle.CDSS cdss = new OM_SapFunctionsStyle.CDSS();
        
        List<OM_SapFunctionsStyle.W3query> itemList = new List<OM_SapFunctionsStyle.W3query>();
        OM_SapFunctionsStyle.Rrxw3tquery parameter = new OM_SapFunctionsStyle.Rrxw3tquery();    
		
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
        
        
        //Cliente SD
        if(filterWrapper.customerCode != null){
            OM_SapFunctionsStyle.W3query item4 = new OM_SapFunctionsStyle.W3query();
            item4.Name = 'VAR_NAME_'+VAR_NAME;
            item4.Value = 'VAR_20241111115217';
            itemList.add(item4);
            OM_SapFunctionsStyle.W3query item5 = new OM_SapFunctionsStyle.W3query();
            item5.Name = 'VAR_VALUE_EXT_'+VAR_NAME;
            item5.Value = filterWrapper.customerCode; 
            itemList.add(item5);
            VAR_NAME++;
            
        }
        
        //Modelo
        /*if(filterWrapper.moneda != null){
            OM_SapFunctionsStyle.W3query item16 = new OM_SapFunctionsStyle.W3query();
            item16.Name = 'VAR_NAME_'+VAR_NAME;
            item16.Value = 'ZCURVAR2';
            itemList.add(item16);
            OM_SapFunctionsStyle.W3query item17 = new OM_SapFunctionsStyle.W3query();
            item17.Name = 'VAR_VALUE_EXT_'+VAR_NAME;
            item17.Value = filterWrapper.model; 
            itemList.add(item17);
            VAR_NAME++;     
        }*/
        
        //Modelo
        if(filterWrapper.model != null){
            OM_SapFunctionsStyle.W3query item10 = new OM_SapFunctionsStyle.W3query();
            item10.Name = 'VAR_NAME_'+VAR_NAME;
            item10.Value = 'VAR_20240627081033';
            itemList.add(item10);
            OM_SapFunctionsStyle.W3query item11 = new OM_SapFunctionsStyle.W3query();
            item11.Name = 'VAR_VALUE_EXT_'+VAR_NAME;
            item11.Value = filterWrapper.model; 
            itemList.add(item11);
            VAR_NAME++;     
        }
        
        //Material
        if(filterWrapper.material != null && filterWrapper.material != ''){
            OM_SapFunctionsStyle.W3query item12 = new OM_SapFunctionsStyle.W3query();
            item12.Name = 'VAR_NAME_'+VAR_NAME;
            item12.Value = 'VAR_20241212092640';
            itemList.add(item12);
            OM_SapFunctionsStyle.W3query item13 = new OM_SapFunctionsStyle.W3query();
            item13.Name = 'VAR_VALUE_EXT_'+VAR_NAME;
            item13.Value = filterWrapper.material; 
            itemList.add(item13);
            VAR_NAME++;     
        }
        
        //Motivo de Pedido
        if(filterWrapper.orderReason != null){
            OM_SapFunctionsStyle.W3query item14;
            OM_SapFunctionsStyle.W3query item15;
            for(String orderReason : filterWrapper.orderReason){
                if(orderReason != 'vacio'){
                    item14 = new OM_SapFunctionsStyle.W3query();
                    item14.Name = 'VAR_NAME_'+VAR_NAME;
                    item14.Value = 'VAR_20250220142923';
                    itemList.add(item14);
                    
                    item15 = new OM_SapFunctionsStyle.W3query();
                    item15.Name = 'VAR_VALUE_EXT_'+VAR_NAME;
                    item15.Value = orderReason; 
                    itemList.add(item15);
                    VAR_NAME++;
                }
                
            }        
        }
        
        //Lote
        if(filterWrapper.batch != null && filterWrapper.batch != ''){
            OM_SapFunctionsStyle.W3query item8 = new OM_SapFunctionsStyle.W3query();
            item8.Name = 'VAR_NAME_'+VAR_NAME;
            item8.Value = 'VAR_20250320105440';
            itemList.add(item8);
            OM_SapFunctionsStyle.W3query item9 = new OM_SapFunctionsStyle.W3query();
            item9.Name = 'VAR_VALUE_EXT_'+VAR_NAME;
            item9.Value = filterWrapper.batch; 
            itemList.add(item9);
            VAR_NAME++;     
        }
        
        //Destinatario de mercancía
        if(filterWrapper.shippingAddressCode != null){
            OM_SapFunctionsStyle.W3query item6 = new OM_SapFunctionsStyle.W3query();
            item6.Name = 'VAR_NAME_'+VAR_NAME;
            item6.Value = 'VAR_20250320104234';
            itemList.add(item6);
            OM_SapFunctionsStyle.W3query item7 = new OM_SapFunctionsStyle.W3query();
            item7.Name = 'VAR_VALUE_EXT_'+VAR_NAME;
            item7.Value = filterWrapper.shippingAddressCode;
            itemList.add(item7);
            VAR_NAME++;     
        }
        
        
        
        
        parameter.item = itemList;
        System.debug('***parameter: '+parameter);
        OM_SapFunctionsStyle.RrwsThxAxisData axis;
        
        try{
            OM_SapFunctionsStyle.GetQueryViewDataResponse_element response = cdss.GetQueryViewData(infoProvider, parameter, query, null);
            System.debug('***response: '+response);
            if(response != null && response.axisData != null){
                System.debug('Entra por la response');
                bwReport = processAbonosDevolucionesCalloutResponse(response);
            }
        }catch(Exception e){
            System.debug('Exception Entra por aqui: '+e.getMessage());
            throw new AuraHandledException('Error al obtener los datos de Abonos Devoluciones: '+e.getMessage());            
        } 

        return bwReport;
        
    }

    public static OM_BW_Wrapper.BWReport processAbonosDevolucionesCalloutResponse(OM_SapFunctionsStyle.GetQueryViewDataResponse_element response){
        
        
        String successMessage = 'Callout completed successfully.';
        String responseMessage = '';
        List<String> salesforceErrors = new List<String>();
        OM_BW_Wrapper.BWReport bwReport = new OM_BW_Wrapper.BWReport();
        List<OM_BW_Wrapper.BWStocksRow> listStockRows = new List<OM_BW_Wrapper.BWStocksRow>();
        
        if(response != null){
             //Empieza en el 1, porque el Tuple 0 lo ignoramos al ser sólo datos de cabecera.
            Integer cellOrdinalCounter = 0; //Son los valores, se cogen de numRatios en numRatios, cada vez que se cambie de registro se suma numRatios.
            for(OM_SapFunctionsStyle.RrwsSxAxisData axis : response.AxisData.item){	
                Integer tupleCounter = 0;
                OM_BW_Wrapper.BWStocksRow row = new OM_BW_Wrapper.BWStocksRow();
                if(axis.axis == '000'){ //Contiene las cabeceras
                    for(OM_SapFunctionsStyle.RrwsSxTuple headerItem : axis.Set_x.item){
                        System.debug('***esta es la variable tupleCounter: '+ tupleCounter);
                        System.debug('***esta es la variable headerItem.TupleOrdinal: '+ Integer.ValueOf(headerItem.TupleOrdinal)); 
                        if(tupleCounter == Integer.ValueOf(headerItem.TupleOrdinal)){
                            System.debug('***esta es la variable Toneadas: '+ headerItem.Chavl); 
                            if(headerItem.Chavl == '00O2THN2VOW0B1FNWTROUGBJX'){ //Se corresponde con el header Toneladas
                        	    bwReport.ratiosNumber++;
                        	}else if(headerItem.Chavl == '00O2THN2VOW0B1FNWTROUGHVH'){ //Se corresponde con el header Unidades
                        		bwReport.ratiosNumber++;                                
                            }else if(headerItem.Chavl == '00O2THN2VOW0B1FNWTROUHWFX'){ //Se corresponde con el header Importe Venta
								bwReport.ratiosNumber++;                                
                            }
                         }   
                        tupleCounter++;
                    }
                    
                }else if(axis.axis == '001'){ //Ignoramos el primero, son solo datos de cabecera
                    Boolean skipRow = false;
                    tupleCounter = 0; //Se resetea el contador cada nuevo axis
                    for(OM_SapFunctionsStyle.RrwsSxTuple item : axis.Set_x.item){
                        System.debug('este es el tupleOrdinal: '+Integer.ValueOf(item.TupleOrdinal));
                        System.debug('este es el tupleCounter: '+tupleCounter);
                        if(tupleCounter == Integer.ValueOf(item.TupleOrdinal) /*|| item.Caption != 'Resultado'*/){
                            //Continuamos rellenando datos del registro
                            System.debug('***esta es la variable: '+item.Chanm);
                            
                            if(item.Chanm == '0CALMONTH'){ //Se coge Mes.Año
                                row.fecha = item.Caption;                                    
                            }else if(item.Chanm == '0SALESORG'){ //Se coge Org. ventas
                                row.ventas = item.ChavlExt + ' - '+ item.Caption;
                            }else if(item.Chanm == '0CUST_SALES__ZCUS_SALE'){ //Se coge Grupo Cliente
                                row.cliente = item.Caption; 
                            }else if(item.Chanm == '0SOLD_TO'){ //Se coge Solicitante
                                row.solicitante = item.Caption; 
                            }else if(item.Chanm == '0SHIP_TO'){ //Se coge Destinatario mcía.
                                row.destinatario = item.Caption;
                            }else if(item.Chanm == '0BILL_NUM'){ //Se coge Factura
                                row.factura = item.ChavlExt;
                            }else if(item.Chanm == '0ORD_REASON'){ //Se coge Motivo de pedido
                                row.motivo = item.ChavlExt + ' - '+ item.Caption;
                            }else if(item.Chanm == '0BATCH'){ //Se coge Lote
                                row.lote = item.ChavlExt;
                            }else if(item.Chanm == '0MATERIAL'){ //Se coge Material
                                if(item.Chavl.replaceFirst('^0+', '').length() == 5 || item.Chavl.replaceFirst('^0+', '').equals('GEN_VENTAS')){ //Solo se incluyen materiales de 5 dígitos o que se llamen GEN_VENTAS
                                    row.material = item.Chavl.replaceFirst('^0+', '') + ' - '+ item.Caption;
                                    skipRow = false;
                                }else{
                                    skipRow = true;
                                }
                                //row.material = item.Caption;
                            }else if(item.Chanm == '0MATERIAL__ZISDMODEL'){ //Se coge Modelo
                                row.modelo = item.ChavlExt + ' - '+ item.Caption;
                            }else if(item.Chanm == '0REFER_DOC__ZALBARAN'){ //Se coge Albaran
                                row.albaran = item.ChavlExt;
                                
                                //Añadimos a la lista el anterior e inicializamos nuevo registro. También nos recorremos numRatios valores de la estructura CellData para asignárselo al registro que añadimos a la lista, serán los valores de las celdas.        
                                for(Integer contadorRatios = 0; contadorRatios < bwReport.ratiosNumber; contadorRatios++){
                                    if(!String.isBlank(response.cellData.item.get(cellOrdinalCounter+contadorRatios).FormattedValue)){
                                        row.dataValues.add(response.cellData.item.get(cellOrdinalCounter+contadorRatios).FormattedValue);
                                    }else{
                                        row.dataValues.add('0');
                                    }
                                    
                                }
                                System.debug('***estamos en la row: '+row);                            
                                if(!skipRow){
                                    System.debug('***asigna row: '+row);
                                    bwReport.rows.add(row);
                                }
                                
                                cellOrdinalCounter = cellOrdinalCounter+bwReport.ratiosNumber; 
                                
                                row = new OM_BW_Wrapper.BWStocksRow();
                                tupleCounter++;
                            }
                        }                                  
                	}
                }
            }
        }
        
        return bwReport;
    }

}