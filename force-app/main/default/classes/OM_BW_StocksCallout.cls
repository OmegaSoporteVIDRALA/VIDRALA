public class OM_BW_StocksCallout {
    
    public static String createJsonBWWrapper(String year, String month, String model, String batch){
        
        
        OM_BW_Wrapper.BWFilter filterWrapper = new OM_BW_Wrapper.BWFilter(year, month, model, batch);
        
        return JSON.serialize(filterWrapper);
        
    }
    
    public static OM_BW_Wrapper.BWReport stocksCalloutBW(OM_BW_Wrapper.BWFilter filterWrapper){
        
        OM_BW_Wrapper.BWReport bwReport = new OM_BW_Wrapper.BWReport();
        String infoProvider = 'ZMWMS_03';
	    String query = 'ZQZMWMS_03_0004_SW_SL'; //STOCKS
        OM_SapFunctionsStyle.CDSS cdss = new OM_SapFunctionsStyle.CDSS();
        Integer VAR_NAME = 1; //Contador variables
        
        /*Parámetros de entrada posibles para este servicio y su orden:
         * 1. Mes.Año --> VAR_20240626203032: VAR_VALUE_LOW_EXT_1 (Fecha desde) y VAR_VALUE_HIGH_EXT_1 (Fecha hasta) 01.2024. En este caso sólo se mostrará el rango de un mes, por lo que si se 
         * indica Octubre, tanto el low como el high serán octubre.
         * 2. Modelo --> VAR_20240627081033. 
         * 3. Lote --> VAR_20250619094432
         **/
        
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
        item3.Value = filterWrapper.monthTo+'.'+filterWrapper.yearTo; //11.2024 - EN ESTE CASO ES IGUAL QUE YEARFROM Y MONTHFROM
        itemList.add(item3);
        VAR_NAME++;
        
        //Modelo
        if(filterWrapper.model != null){
            OM_SapFunctionsStyle.W3query item4 = new OM_SapFunctionsStyle.W3query();
            item4.Name = 'VAR_NAME_'+VAR_NAME;
            item4.Value = 'VAR_20240627081033';
            itemList.add(item4);
            OM_SapFunctionsStyle.W3query item5 = new OM_SapFunctionsStyle.W3query();
            item5.Name = 'VAR_VALUE_EXT_'+VAR_NAME;
            item5.Value = filterWrapper.model; 
            itemList.add(item5);
            VAR_NAME++;
            
        }  
        
        //Lote
        if(filterWrapper.batch != null){
            OM_SapFunctionsStyle.W3query item6 = new OM_SapFunctionsStyle.W3query();
            item6.Name = 'VAR_NAME_'+VAR_NAME;
            item6.Value = 'VARA_20250619094432';
            itemList.add(item6);
            OM_SapFunctionsStyle.W3query item7 = new OM_SapFunctionsStyle.W3query();
            item7.Name = 'VAR_VALUE_EXT_'+VAR_NAME;
            item7.Value = filterWrapper.batch; 
            itemList.add(item7);
            VAR_NAME++;  
        } 
    
           
        parameter.item = itemList;
        OM_SapFunctionsStyle.RrwsThxAxisData axis;
        
        
        try{
            OM_SapFunctionsStyle.GetQueryViewDataResponse_element response = cdss.GetQueryViewData(infoProvider, parameter, query, null);
            System.debug('***response.AxisData: '+response.AxisData);
            System.debug('***response.AxisInfo: '+response.AxisInfo);
            System.debug('***response.CellData: '+response.CellData);
            System.debug('***response.TextSymbols: '+response.TextSymbols);
            System.debug('***response: '+response);
            
            if(response != null && response.axisData != null){
                System.debug('Entra por la response');
                bwReport = processStocksCalloutResponse(response);
            }
        }catch(Exception e){
            System.debug('Exception Entra por aqui: '+e.getMessage());
            System.debug('Exception Entra por aqui: '+e);
            throw new AuraHandledException('Error al obtener los datos de Stock: '+e.getMessage());            
        } 
        
        return bwReport;
    }
    
    public static OM_BW_Wrapper.BWReport processStocksCalloutResponse(OM_SapFunctionsStyle.GetQueryViewDataResponse_element response){
        
        
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
                        if(tupleCounter == Integer.ValueOf(headerItem.TupleOrdinal)){
                            if(headerItem.Chavl == '00O2THN2VOW0AIRRQMLL2IZY4'){ //Se corresponde con el header Ctd. stock total BOT
                        		bwReport.numStockBOT++;
                                bwReport.ratiosNumber++;
                        	}else if(headerItem.Chavl == '00O2THN2VOW0AIRRQMLL2JCL8'){ //Se corresponde con el header Ctd. stock total PAL
                        		bwReport.numStockPAL++;   
								bwReport.ratiosNumber++;                                
                            }else if(headerItem.Chanm == 'ZIWMEXIS'){ //Metemos la subheader en la lista
                                bwReport.stockSubHeaders.add(headerItem.Caption);
                                tupleCounter++;
                            }
                        }                 
                    }
                    
                }else if(axis.axis == '001'){ //Ignoramos el primero, son solo datos de cabecera
                    //Inicializamos la List<Double> de totales del report con un tamaño igual al numero de ratios
                    for(Integer i = 0; i< bwReport.ratiosNumber; i++){
                        bwReport.totalValues.add(0.0);
                    }
                    tupleCounter = 0; //Se resetea el contador cada nuevo axis
                    Boolean skipRow = false;
                    for(OM_SapFunctionsStyle.RrwsSxTuple item : axis.Set_x.item){
                        System.debug('este es el tupleOrdinal: '+Integer.ValueOf(item.TupleOrdinal));
                        System.debug('este es el tupleCounter: '+tupleCounter);
                        if(tupleCounter == Integer.ValueOf(item.TupleOrdinal) /*|| item.Caption != 'Resultado'*/){
                            //Continuamos rellenando datos del registro
                            System.debug('***esta es la variable: '+item.Chanm);
                            
                            if(item.Chanm == '0PLANT'){ //Se coge código y descripción del centro
                                row.centro = item.ChavlExt + ' - '+ item.Caption;                                    
                            }else if(item.Chanm == '0STOR_LOC'){ //Se coge el almacén
                                row.almacen = item.Caption;
                            }else if(item.Chanm == '0MATERIAL'){ //Se coge Material
                                if(item.Chavl.replaceFirst('^0+', '').length() == 5 || item.Chavl.replaceFirst('^0+', '').equals('GEN_VENTAS')){ //Solo se incluyen materiales de 5 dígitos o que se llamen GEN_VENTAS
                                    row.material = item.ChavlExt + ' - '+ item.Caption;
                                    skipRow = false;
                                }else{
                                    skipRow = true;
                                }
                                 
                                
                            }else if(item.Chanm == '0MATERIAL__ZISDMODEL'){ //Se coge Modelo
                                row.modelo = item.ChavlExt + ' - '+ item.Caption; 
                            }else if(item.Chanm == '0MATERIAL__ZIWMSC002'){ //Se coge Color
                                row.color = item.caption;
                                //Añadimos a la lista el anterior e inicializamos nuevo registro. También nos recorremos numRatios valores de la estructura CellData para asignárselo al registro que añadimos a la lista, serán los valores de las celdas.        
                                for(Integer contadorRatios = 0; contadorRatios < bwReport.ratiosNumber; contadorRatios++){
                                    if(!String.isBlank(response.cellData.item.get(cellOrdinalCounter+contadorRatios).FormattedValue)){
                                        row.dataValues.add(response.cellData.item.get(cellOrdinalCounter+contadorRatios).FormattedValue);
                                        if(!skipRow) bwReport.totalValues.set(contadorRatios, bwReport.totalValues.get(contadorRatios) + Double.ValueOf(response.cellData.item.get(cellOrdinalCounter+contadorRatios).Value) );
                                    }else{
                                        row.dataValues.add('0');
                                    }
                                    
                                }
                                System.debug('***skipRow: '+skipRow);
                                if(!skipRow){
                                    System.debug('***asigna row: '+row);
                                    bwReport.rows.add(row);
                                }
                                
                                //cellOrdinalCounter = cellOrdinalCounter+6; 
                                cellOrdinalCounter = cellOrdinalCounter+bwReport.ratiosNumber; 
                                
                                row = new OM_BW_Wrapper.BWStocksRow();
                                /*if(item.Chanm == '0PLANT'){ //Se coge el centro
                                    row.centro = item.ChavlExt + ' - '+ item.Caption;   
                                }*/
                                tupleCounter++;
                            }
                        }/*else{                          
                            

                            
                        }   */      
                	}
                }
            }
        }
        
        return bwReport;
    }
}