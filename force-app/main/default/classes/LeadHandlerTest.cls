/**
* @author Jamie Kennedy <jamie.kennedy@cloudshiftgroup.com>
* @date 2021-10-01
* @group CloudShiftGroup
* @description This handler test class for the Lead trigger.
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 2021-11-01        Jamie Kennedy      	Created Class
**/


@isTest
public class LeadHandlerTest {
    
    private static Integer leadCount = 3;
    private static Integer leadProductCount = 2;
    private static Integer productsToCreate = leadCount * leadProductCount;

    @testSetup
    static void testSetup() {
        
        List<Lead> leadList = new List<Lead>();
        List<Product2> leadProduct = new List<Product2>();
             
        for(Integer i = 0; i < leadCount; i++) {
            leadList.add(new Lead(
                FirstName = 'LeadProcessWebProducts',
                LastName = 'Test: ' + i,
                Status = 'Active',
                Company = 'Test Company'
            ));
        }

        for(Integer i = 0; i < productsToCreate; i++) {
            leadProduct.add(new Product2(
                Name = 'test product name ' + i,
                ProductCode = '1123-' + i,
                Description = 'Test Item'
            ));
        }
        
        insert leadProduct;
        insert leadList;
    }
    
    @isTest
    static void testprocessWebProducts() {
        
        List<Lead> leads = [ SELECT Id, Product__c, Volume_Pallets_Web_Capture__c, Volume_Units_Web_Capture__c
                           	 FROM Lead
                           	 WHERE FirstName = 'LeadProcessWebProducts' ];
        
        List<Product2> products = [ SELECT Id, ProductCode
                                    FROM Product2 
                                    WHERE ProductCode != null ];
        Integer loopCount = 0;
        
        System.Test.startTest();
        
        for(Lead lead : leads) {
            
            lead.Product__c = '';
            lead.Volume_Pallets_Web_Capture__c = '';
            lead.Volume_Units_Web_Capture__c = '';
            
            for(Integer i = 0; i < leadProductCount; i++) {
                
                if(!(i + 1 < leadProductCount)) {
    				//last iteration
    				lead.Product__c += products[loopCount].ProductCode;
                    lead.Volume_Pallets_Web_Capture__c += i;
                    lead.Volume_Units_Web_Capture__c += loopCount;
  				}
                else {
                    lead.Product__c += products[loopCount].ProductCode + ',';
                    lead.Volume_Pallets_Web_Capture__c += i + ',';
                    lead.Volume_Units_Web_Capture__c += loopCount + ',';
                }
                
                loopcount++;
            }
        }
        
        update leads;
        
        LeadHandler testHandler = new LeadHandler();
		testHandler.processWebProducts(leads);
        
        System.Test.stopTest();
        
        List<Lead_Product__c> insertedLeadProducts = [ SELECT Id FROM Lead_Product__c ];
        
        System.assertEquals(productsToCreate, insertedLeadProducts.Size(), 'checking total lead products');
    }
}

/*@isTest
public class LeadHandlerTest {
    
    private static Integer leadCount = 3;
    private static Integer leadProductCount = 2;
    private static Integer productsToCreate = leadCount * leadProductCount;

    @testSetup
    static void testSetup() {
        
        List<Lead> leadList = new List<Lead>();
        List<Product2> leadProduct = new List<Product2>();
             
        for(Integer i = 0; i < leadCount; i++) {
            leadList.add(new Lead(
                FirstName = 'LeadProcessWebProducts',
                LastName = 'Test: ' + i,
                Status = 'Active',
                Company = 'Test Company'
            ));
        }

        for(Integer i = 0; i < productsToCreate; i++) {
            leadProduct.add(new Product2(
                Name = 'test product name ' + i,
                ProductCode = '1123-' + i,
                Description = 'Test Item'
            ));
        }
        
        insert leadProduct;
        insert leadList;
    }
    
    @isTest
    static void testprocessWebProducts() {
        
        List<Lead> leads = [ SELECT Id, Product__c, Volume_Pallets_Web_Capture__c, Volume_Units_Web_Capture__c
                           	 FROM Lead
                           	 WHERE FirstName = 'LeadProcessWebProducts' ];
        
        List<Product2> products = [ SELECT Id, ProductCode
                                    FROM Product2 
                                    WHERE ProductCode != null ];
        Integer loopCount = 0;
        
        for(Lead lead : leads) {
            
            lead.Product__c = '';
            lead.Volume_Pallets_Web_Capture__c = '';
            lead.Volume_Units_Web_Capture__c = '';
            
            for(Integer i = 0; i < leadProductCount; i++) {
                
                if(!(i + 1 < leadProductCount)) {
    				//last iteration
    				lead.Product__c += products[loopCount].ProductCode;
                    lead.Volume_Pallets_Web_Capture__c += i;
                    lead.Volume_Units_Web_Capture__c += loopCount;
  				}
                else {
                    lead.Product__c += products[loopCount].ProductCode + ',';
                    lead.Volume_Pallets_Web_Capture__c += i + ',';
                    lead.Volume_Units_Web_Capture__c += loopCount + ',';
                }
                
                loopcount++;
            }
        }
        
        update leads;
        
        LeadHandler testHandler = new LeadHandler();
		testHandler.processWebProducts(leads);
        
        List<Lead_Product__c> insertedLeadProducts = [ SELECT Id FROM Lead_Product__c ];
        
        // we should have the same amound of productsToCreate in our above SOQL
        system.assertEquals(productsToCreate, insertedLeadProducts.Size(), 'checking total lead products');
    }
}*/