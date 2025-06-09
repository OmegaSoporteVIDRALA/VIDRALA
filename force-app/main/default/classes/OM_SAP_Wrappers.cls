public class OM_SAP_Wrappers {
	
    public class CustomerWrapper{
        public String customerCode {get;set;}
        //public String salesforceId {get;set;}
        public String customerName {get;set;}
        public String parentCustomer {get;set;}
        public String blocked {get;set;}
        public Address address {get;set;}
        public String vatNumber {get;set;}
        public String nif {get;set;}
        public String phone {get;set;}
        public String industry {get;set;}
        public String customerClass {get;set;}
        public String recordType {get;set;}
        public List<CreditSegment> creditSegment {get;set;}
        public List<SalesOrganization> salesOrganizations {get;set;}
    }
    
    public class Address{
        public String street {get;set;}
        public String postalCode {get;set;}
        public String city {get;set;}
        public String state {get;set;}
        public String country {get;set;}
        public Double coordX {get;set;}
        public Double coordY {get;set;}
    }
        
    public class CreditSegment{
        public String territoryCode {get;set;}
        public Double creditLimit {get;set;} //Descomentar
        public String creditStatus {get;set;}
        public Boolean creditBlock {get;set;}
    }
    
    public class SalesOrganization{
        public String organizationCode {get;set;}
        public String market {get;set;}
        public String claseABC {get;set;}
        public Financials financials {get;set;}
        public Boolean creditBlock {get;set;}
        public CustomerTeam customerTeam {get;set;}
    }
    
    public class Financials{
        public String currencyCode {get;set;}
        public String agreedTerms {get;set;}
        public String paymentMethod {get;set;}
    }
    
    public class CustomerTeam{
        public String salesAdmin {get;set;}
        public String customerManager {get;set;}
        public String customerService {get;set;}
        public String salesOffice {get;set;}
    }
    
    public class CustomerPriceWrapper{
        public String priceCode {get;set;}
        public Double price {get;set;}
        public String customerCode {get;set;}
        public String incoterms {get;set;}
        public String plant {get;set;}
        public String currencyCode {get;set;}
        public String productCode {get;set;}
        public String installDate {get;set;}
        public String usageEndDate {get;set;}
        public String salesOrganization {get;set;}
        public String materialCode {get;set;}
             
    }

}