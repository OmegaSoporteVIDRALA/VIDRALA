public class OM_BW_Wrapper {
	public class BWReport{
        //public BWFilter filter {get;set;}
        public String name {get;set;}
        public Date reportDate {get;set;}
        //public BWStocksRow header {get;set;}
        public List<BWStocksRow> rows {get;set;}
        public Integer ratiosNumber {get;set;} //Número de ratios (habrá tantos AxisData en una Row como Ratios)
        public Integer numStockBOT {get;set;}
        public Integer numStockPAL {get;set;}
        public List<String> stockSubHeaders {get;set;}
        public List<Double> totalValues {get;set;}
        
        public BWReport(){
            this.rows = new List<BWStocksRow>();
            this.numStockBOT = 0;
            this.numStockPAL = 0;
            this.ratiosNumber = 0;
            this.stockSubHeaders = new List<String>();
            this.totalValues = new List<Double>();
        }
    }
    
    public class BWStocksDataHeader{
        public Integer axis {get;set;}
        public Integer numHeaders {get;set;}
        public List<String> headers {get;set;}
           
    }
    
    public class BWStocksRow{
        public Integer axis {get;set;}
        public String centro {get;set;}
        public String color {get;set;}
        public String material {get;set;}
        public String modelo {get;set;}
        public String lote {get;set;}
        public String almacen {get;set;}
        //VentasAbonos
        public String fecha {get;set;}
        public String ventas {get;set;} //Org. ventas
        public String cliente {get;set;} //Grupo cliente
        public String solicitante {get;set;} //Solicitante
        public String destinatario {get;set;} //Destinatario mcia
        public String factura {get;set;} //Factura
        public String motivo {get;set;} //Motivo de pedido
        public String albaran {get;set;} //Albaran
        
        
        
        public List<String> dataValues {get;set;}
        
        public BWStocksRow(){
            this.dataValues = new List<String>();
        }
           
    }
    
    
    public class BWFilter{
        public String yearFrom {get;set;}
        public String yearTo {get;set;}
        public String monthFrom {get;set;}
        public String monthTo {get;set;}
        public String customerCode {get;set;} //Código cliente
        public String shippingAddressCode {get;set;} //Código destinatario mercancía
        public List<String> orderReason {get;set;} //Motivo del pedido
        public String salesOrganization {get;set;} //Organización de ventas
        public String salesGroup {get;set;} //Grupo de ventas (EN IMPLEMENTACIÓN) Representa el Account Manager. Entre España, Francia y Portugal hay 12.
        public String batch {get;set;} //Lote
        public String model {get;set;} //Modelo
        public String material {get;set;} //Material
        public String moneda {get;set;} //Moneda

        
        
        public BWFilter(String yearFrom, String yearTo, String monthFrom, String monthTo, String customerCode, 
                        String shippingAddressCode, List<String> orderReason, String model, String material, String batch ){
            		
                            this.yearFrom = yearFrom;
                            this.yearTo = yearTo;
                            this.monthFrom = monthFrom;
                            this.monthTo = monthTo;
                            this.customerCode = customerCode;
                            this.shippingAddressCode = shippingAddressCode;
                            this.orderReason = orderReason;
                            this.model = model;
                            this.material = material;
                            this.batch = batch;
                            
        }
        
        public BWFilter(String yearFrom, String yearTo, String monthFrom, String monthTo, String salesOrganization, String salesGroup){
            		
                            this.yearFrom = yearFrom;
                            this.yearTo = yearTo;
                            this.monthFrom = monthFrom;
                            this.monthTo = monthTo;
                            this.salesOrganization = salesOrganization;
                            this.salesGroup = salesGroup;
                            
        }
        
        public BWFilter(String year, String month, String model, String batch){
            		
                            this.yearFrom = year;
                            this.yearTo = year;
                            this.monthFrom = month;
                            this.monthTo = month;
                            this.model = model;
            				this.batch = batch;
                        
        }
        
        public BWFilter(String yearFrom, String monthFrom, String salesGroup){
            		
                            this.yearFrom = yearFrom;
                            this.monthFrom = monthFrom;
                            this.salesGroup = salesGroup;
                            
        }

    }
}