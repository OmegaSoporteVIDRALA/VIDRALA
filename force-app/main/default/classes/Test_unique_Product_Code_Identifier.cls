@isTest
public class Test_unique_Product_Code_Identifier {
    @testSetup
  		static void dataCreation() {
        List<Product2> products = new List<Product2>();
        for(Integer i=0;i<200;i++){
            products.add(new Product2(Name='Test '+i,CurrencyIsoCode='GBP',ProductCode='1'+i)); 
        }
        insert products;        
    }
    @isTest
    static void testMethod1(){
        Product2 pr = new Product2();
        pr.Name = 'Testing1';
        pr.CurrencyIsoCode ='GBP';
        pr.ProductCode='1234';
        try{
            insert pr;
        } catch(Exception e){
            List<Product2> oldProducts = [SELECT Id,ProductCode FROM Product2 WHERE ProductCode =: pr.ProductCode];
        	system.assertEquals(1, oldProducts.size());
        }
    }
    @isTest
    static void testMethod2(){
        Product2 pr = new Product2();
        pr.Name = 'Testing1';
        pr.CurrencyIsoCode ='GBP';
        pr.ProductCode='11';
        try{
            insert pr;
        } catch(Exception e){
            List<Product2> oldProducts = [SELECT Id,ProductCode FROM Product2 WHERE ProductCode =: pr.ProductCode];
       		system.assertEquals(1, oldProducts.size());
            
        }

	}
}