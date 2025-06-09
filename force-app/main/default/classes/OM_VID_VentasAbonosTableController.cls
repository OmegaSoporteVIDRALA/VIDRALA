public with sharing class OM_VID_VentasAbonosTableController {
    
    public class TableWrapper{
        
        @AuraEnabled public List<Map<String, Object>> tableData {get;set;}
        @AuraEnabled public Integer ratiosNumber {get;set;}

        public TableWrapper(){
            this.tableData = new List<Map<String, Object>>();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getOrderReasonValues(String objectApiName, String fieldApiName) {
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();

        
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
            .get(objectApiName)
            .getDescribe()
            .fields.getMap()
            .get(fieldApiName)
            .getDescribe();
        
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            Map<String, String> picklistMap = new Map<String, String>();
            picklistMap.put('label', entry.getLabel()); 
            picklistMap.put('value', entry.getValue()); 
            picklistValues.add(picklistMap);
        }

        return picklistValues;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getModelValues(String objectApiName, String fieldApiName) {
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();

        
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
            .get(objectApiName)
            .getDescribe()
            .fields.getMap()
            .get(fieldApiName)
            .getDescribe();
        
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            Map<String, String> picklistMap = new Map<String, String>();
            picklistMap.put('label', entry.getLabel()); 
            picklistMap.put('value', entry.getValue()); 
            picklistValues.add(picklistMap);
        }

        return picklistValues;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getMaterials(String productId) {
        
        List<SAP_Material_Code__c> materials = [SELECT Name FROM SAP_Material_Code__c WHERE OM_ProductRef__c = :productId];
        
        
        List<String> materialNames = new List<String>();
        for (SAP_Material_Code__c material : materials) {
            materialNames.add(material.Name);
        }
        return materialNames;
    }
    
     @AuraEnabled(cacheable=true)
	public static Product2 getProductCode(String productId) {
    // Realiza la consulta SOQL para obtener el Product2 por ID
    Product2 product = [SELECT Id, OM_Product_Code_SIP__c  FROM Product2 WHERE Id = :productId LIMIT 1];
    return product;
}
    
    @AuraEnabled(cacheable=true)
	public static Account  getAccountCode(String accountId) {
    // Realiza la consulta SOQL para obtener el Product2 por ID
    Account  account = [SELECT Id, SAP_Account_Number__c FROM Account WHERE Id = :accountId LIMIT 1];
    return account;
}

    @AuraEnabled(cacheable=true)
    public static void makeBWVACallout(String yearFrom, String yearTo, String monthFrom, String monthTo, String customerCode, 
    String shippingAddressCode, List<String> orderReason, String model, String material, String batch){

        OM_BW_Wrapper.BWFilter bwFilter = new OM_BW_Wrapper.BWFilter(yearFrom, yearTo, monthFrom, monthTo, customerCode, 
        shippingAddressCode, orderReason, model, material, batch);
        List<OM_BW_Wrapper.BWStocksRow> listStockRows = new List<OM_BW_Wrapper.BWStocksRow>();
        try {
            OM_BW_AbonosDevolucionesCallout.abonosDevolucionesSACCalloutBW(bwFilter);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static TableWrapper getTableData(String yearFrom, String yearTo, String monthFrom, String monthTo, String customerCode, 
    String shippingAddressCode, List<String> orderReason, String model, String material, String batch/*, OM_SapFunctionsStyle.GetQueryViewDataResponse_element response*/) {

        OM_BW_Wrapper.BWFilter bwFilter = new OM_BW_Wrapper.BWFilter(yearFrom, yearTo, monthFrom, monthTo, customerCode, 
        shippingAddressCode, orderReason, model, material, batch);
        
        OM_BW_Wrapper.BWReport bwReport = new OM_BW_Wrapper.BWReport();
        bwReport = OM_BW_AbonosDevolucionesCallout.abonosDevolucionesSACCalloutBW(bwFilter);
        TableWrapper tableWrapper = new TableWrapper();
        if(bwReport != null && bwReport.rows.size() > 0){
            System.debug('**esto es ratiosNumber: '+bwReport.ratiosNumber);

            tableWrapper.ratiosNumber = bwReport.ratiosNumber;

            List<Map<String, Object>> tableData = new List<Map<String, Object>>();
            Integer rows = 1;
            for(OM_BW_Wrapper.BWStocksRow row : bwReport.rows){
                Map<String, Object> mapData = new Map<String, Object>();
                mapData.put('id', String.valueOf(rows));
                mapData.put('fecha', row.fecha);
                mapData.put('ventas', row.ventas);
                mapData.put('cliente', row.cliente);
                mapData.put('solicitante', row.solicitante);
                mapData.put('factura', row.factura);
                mapData.put('motivo', row.motivo);
                mapData.put('lote', row.lote);
                mapData.put('material', row.material);
                mapData.put('modelo', row.modelo);
                mapData.put('albaran', row.albaran);
				mapData.put('destinatario', row.destinatario);
                
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