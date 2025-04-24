/**
* @author Jamie Kennedy <jamie.kennedy@cloudshiftgroup.com>
* @date 2021-10-01
* @group CloudShiftGroup
* @description This handler class is to be used with the Lead trigger.
*
* Date              Author              Change Description
* -----------------------------------------------------------------------------------
* 2021-11-01        Jamie Kennedy      	Created Classz
**/

public class LeadHandler {

   /**
     *  @desc	To be used with the after Insert trigger, will loop through comma separated 
     * 			values and create Lead_Product__c records for each comma separated value. 	     
     *  @param  List<Lead> leadList
     *  @return void
     */
    public void processWebProducts(List<Lead> leadList) {
        
        if(leadList == null || leadList.isEmpty()) {
            return;
        }

        List<Lead> leadUpdates = new List<Lead>();
        List<Lead_Product__c> leadProductInserts = new List<Lead_Product__c>();
        
        for(Lead lead : leadList) {
            
            if (String.isBlank(lead.Product__c)) {
                continue;
            }

            List<String> lstProducts = lead?.Product__c.split(',');
            List<String> lstVolPallets = lead?.Volume_Pallets_Web_Capture__c.split(',');
            List<String> lstVolUnits = lead?.Volume_Units_Web_Capture__c.split(',');
            
            if (lstProducts.isEmpty() || lstVolPallets.isEmpty() || lstVolUnits.isEmpty() || 
                lstProducts.size() != lstVolPallets.size() || lstProducts.size() != lstVolUnits.size()) {
                continue;
            }
            
            Integer totalUnits = 0;
            Integer totalPallets = 0;
            
            Map<String, Id> productMap = new Map<String, Id>();
            
            List<Product2> allProducts = new List<Product2>([SELECT Id, ProductCode FROM Product2]);
            
            for(Product2 product : allProducts) {
                productMap.put(product.ProductCode, product.Id);
            }
            
            if(productMap.isEmpty()) {
                continue;
            }

            for(Integer i = 0; i < lstProducts.size(); i++) {
                
                if (!productMap.containsKey(lstProducts[i])) {
                    continue;
                }
                
                Lead_Product__c newLP = new Lead_Product__c(); 
                
                newLP.Lead__c = lead.Id; 
                newLP.Volume_Units__c = Integer.valueOf(lstVolUnits[i]);
                newLP.Volume_Pallets__c = Integer.valueOf(lstVolPallets[i]);
                
                newLP.Products__c = productMap.get(lstProducts[i]);
                
                totalUnits += Integer.valueOf(lstVolUnits[i]);
                totalPallets += Integer.valueOf(lstVolPallets[i]);
                
                leadProductInserts.add(newLP);
            }
            
            if (!leadProductInserts.isEmpty()) {
                leadUpdates.add(new Lead(
                    Id = lead.Id,
                    Volume_Pallets__c = totalPallets,
                    Volume_Units_000__c = totalUnits
                ));
            }
        }
        try{
            if(leadProductInserts.Size() > 0) {
            	insert leadProductInserts;
        	}           
        } catch(DmlException e){
          	throw new CustomException('Error inserting Lead_Product__c records: ' + e.getMessage());

        }
        

        try{       
            if(leadUpdates.Size() > 0) {
                update leadUpdates;
            }
        } catch(DmlException e){
            throw new CustomException('Error inserting Lead_Product__c records: ' + e.getMessage());

        }
    }
    public class CustomException extends Exception {}

}




/*public class LeadHandler {

   /**
     *  @desc	To be used with the after Insert trigger, will loop through comma seperated 
     * 			values and create Lead_Product__c records for each Comma seperated value. 	     
     *  @param  List<Lead> leadList
     *  @return void
     */
    /*public void processWebProducts(List<Lead> leadList) {
        
        List<Lead> leadUpdates = new List<Lead>();
        List<Lead_Product__c> leadProductInserts = new List<Lead_Product__c>();
        
        for(Lead lead : leadList) {
            
            if(!String.isBlank(lead.Product__c)){

                // split the input strings into lists, seperated by Comma. 
                List<String> lstProducts = lead?.Product__c.split(',');
                List<String> lstVolPallets = lead?.Volume_Pallets_Web_Capture__c.split(',');
                List<String> lstVolUnits = lead?.Volume_Units_Web_Capture__c.split(',');
                
                if(lstProducts.Size() > 0) {
                    
                    // Integers to count up our total values
                    Integer totalUnits = 0;
                    Integer totalPallets = 0;
                    
                    // creating a ProductName to Id Map so we can retrieve the Product Id. 
                    Map<String, Id> productMap = new Map<String, Id>();
                    
                    List<Product2> allProducts = new List<Product2>([SELECT Id, ProductCode FROM Product2]);
                    
                    // looping through our Product to put values into the Map.
                    for(Product2 product : allProducts) {
                        productMap.put(product.ProductCode, product.Id);
                    }
                    
                    // looping through the products list to create Lead_Product__c records. 
                    for(Integer i = 0; i < lstProducts.Size(); i++) {
                        
                        Lead_Product__c newLP = new Lead_Product__c(); 
                        
                        newLP.Lead__c = lead.Id; 
                        newLP.Volume_Units__c = Integer.ValueOf(lstVolUnits[i]);
                        newLP.Volume_Pallets__c = Integer.ValueOf(lstVolPallets[i]);
                        
                        newLP.Products__c = productMap?.get(lstProducts[i]);
                        
                        totalUnits = totalUnits + Integer.ValueOf(lstVolUnits[i]);
                        totalPallets = totalPallets + Integer.ValueOf(lstVolPallets[i]);
                        
                        leadProductInserts.add(newLP);
                    }
                    
                    if(leadProductInserts.Size() > 0) {
                        // after we've gone over our Products update the parent Lead with total values. 
                        leadUpdates.add(new Lead(
                            Id = lead.Id,
                            Volume_Pallets__c = totalPallets,
                            Volume_Units_000__c = totalUnits
                        ));
                    }
                }
            }
        }
        
        // after we've looped through all leads, update Leads and insert Lead_Product__c
        if(leadProductInserts.Size() > 0) {
            insert leadProductInserts;
        }
        if(leadUpdates.Size() > 0) {
            update leadUpdates;
        }
    }
}*/