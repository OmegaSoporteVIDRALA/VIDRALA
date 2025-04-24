@isTest
public class UniqueProductCodeIdentifierTest {
    @testSetup
    static void dataCreation() {
               
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;    
        
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 200; i++) {
            products.add(new Product2(Name = 'Test ' + i, CurrencyIsoCode = 'GBP', ProductCode = '1' + i));
        }
        insert products;        
    }

    @isTest
    static void testUniqueProductCodeInsertion() {
        Test.startTest();
        Product2 newProduct = new Product2();
        newProduct.Name = 'Unique Product';
        newProduct.CurrencyIsoCode = 'GBP';
        newProduct.ProductCode = '1234';

        insert newProduct;

        Product2 insertedProduct = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = :newProduct.ProductCode LIMIT 1];
        System.assertNotEquals(null, insertedProduct, 'The product should have been inserted successfully.');
        System.assertEquals(newProduct.ProductCode, insertedProduct.ProductCode, 'The ProductCode should match the inserted value.');
        Test.stopTest();
    }

    @isTest
    static void testDuplicateProductCodeInsertion() {
        Test.startTest();
        Product2 duplicateProduct = new Product2();
        duplicateProduct.Name = 'Duplicate Product';
        duplicateProduct.CurrencyIsoCode = 'GBP';
        duplicateProduct.ProductCode = '11'; 

        try {
            insert duplicateProduct;
            System.assert(false, 'An exception should have been thrown due to a duplicate Product Code.');
        } catch (DmlException e) {
            String errorMessage = e.getMessage();
            System.assert(errorMessage.contains('Product Code is already present in the system. Please enter a unique Product Code.'),
                'The error message should indicate a duplicate Product Code issue.');
        }
        Test.stopTest();
    }
}



/*@isTest
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
}*/