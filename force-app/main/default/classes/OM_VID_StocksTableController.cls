public with sharing class OM_VID_StocksTableController {
    
    public class TableWrapper{
        
        @AuraEnabled public List<Map<String, Object>> tableData {get;set;}
        @AuraEnabled public Integer ratiosNumber {get;set;}
        @AuraEnabled public Integer numStockBOT {get;set;}
        @AuraEnabled public Integer numStockPAL {get;set;}
        @AuraEnabled public List<String> stockSubHeaders {get;set;}
        @AuraEnabled public List<String> totalValues {get;set;}

        public TableWrapper(){
            this.tableData = new List<Map<String, Object>>();
            this.stockSubHeaders = new List<String>();
            this.totalValues = new List<String>();
        }
    }
    
    @AuraEnabled(cacheable=true)
	public static Product2 getProductCode(String productId) {
    // Realiza la consulta SOQL para obtener el Product2 por ID
    Product2 product = [SELECT Id, OM_Product_Code_SIP__c FROM Product2 WHERE Id = :productId LIMIT 1];
    return product;
}

    @AuraEnabled(cacheable=true)
    public static void makeBWStocksCallout(String year, String month, String model, String batch){

        OM_BW_Wrapper.BWFilter bwFilter = new OM_BW_Wrapper.BWFilter(year, month, model, batch);
        List<OM_BW_Wrapper.BWStocksRow> listStockRows = new List<OM_BW_Wrapper.BWStocksRow>();
        try {
            OM_BW_StocksCallout.stocksCalloutBW(bwFilter);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static TableWrapper getTableData(String year, String month, String model, String batch/*, OM_SapFunctionsStyle.GetQueryViewDataResponse_element response*/) {

        OM_BW_Wrapper.BWFilter bwFilter = new OM_BW_Wrapper.BWFilter(year, month, model, batch );
        
        OM_BW_Wrapper.BWReport bwReport = new OM_BW_Wrapper.BWReport();
        bwReport = OM_BW_StocksCallout.stocksCalloutBW(bwFilter);
        TableWrapper tableWrapper = new TableWrapper();
        if(bwReport != null && bwReport.rows.size() > 0){
            System.debug('**esto es ratiosNumber: '+bwReport.ratiosNumber);
            System.debug('**esto es numStockBOT : '+bwReport.numStockBOT);
            System.debug('**esto es ratiosNumber: '+bwReport.numStockPAL);
            System.debug('**esto es stockSubHeaders: '+bwReport.stockSubHeaders);
            System.debug('**esto es totalValues: '+bwReport.totalValues);

            tableWrapper.ratiosNumber = bwReport.ratiosNumber;
            tableWrapper.numStockBOT = bwReport.numStockBOT;
            tableWrapper.numStockPAL = bwReport.numStockPAL;
            tableWrapper.stockSubHeaders = bwReport.stockSubHeaders;
            tableWrapper.totalValues = new List<String>(); 

               
            for (Double value : bwReport.totalValues) {
               tableWrapper.totalValues.add(String.valueOf(value)); // ✅ Convertimos `Double` a `String`
            }
                

            List<Map<String, Object>> tableData = new List<Map<String, Object>>();
            Integer rows = 1;
            for(OM_BW_Wrapper.BWStocksRow row : bwReport.rows){
                Map<String, Object> mapData = new Map<String, Object>();
                mapData.put('id', String.valueOf(rows));
                mapData.put('centro', row.centro);
                mapData.put('color', row.color);
                mapData.put('material', row.material);
                mapData.put('modelo', row.modelo);
                mapData.put('almacen', row.almacen);

                Integer contador = 0;
                for(String value : row.dataValues){
                    mapData.put('value'+contador, value);
                    contador++;
                }

                tableData.add(mapData);
            }

            if(tableData.size() > 0) tableWrapper.tableData = tableData;
        }
            		
System.debug('**esto es tableWrapper: '+tableWrapper);
        return tableWrapper;
    }
}