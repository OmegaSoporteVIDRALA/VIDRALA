/*
 *  Class Name  : UniqueProductCodeIdentifier 
 *  Description : This is a utility class for checkDupProductCode Trigger
 *  Company     : Cloudshift Group
 *  CreatedDate : 05/01/2022
 *  Test class  : UniqueProductCodeIdentifierTest
 *
 *  Modification Log
 *  ----------------------------------------------------------------------
 *  Developer                  Modification Date           Comments
 *  ----------------------------------------------------------------------
 *  Prasanna Kawle              05/01/2022                Orginal Version 
 *  Globant						16/09/2024				  Code Refactoring
 * 
 */
 


public class UniqueProductCodeIdentifier {

    /*
     *  Method Name:    checkDupProductCode 
     *  Description:    Method to check for duplicate Product Codes and raise an Error.
     *  Param:          Trigger.new (products), oldProductsMap (optional)
     *  Return:         None
     */
    public static void checkDupProductCode(List<Product2> products, Map<Id, Product2> oldProductsMap) {
        
        List<String> pCodes = new List<String>();
        
        for (Product2 pr : products) {
            if (oldProductsMap == null || oldProductsMap.get(pr.Id).ProductCode != pr.ProductCode) {
                pCodes.add(pr.ProductCode);
            }
        }

        List<Product2> duplicateProducts = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :pCodes];
        
        if (!duplicateProducts.isEmpty()) {
            for (Product2 pr : products) {
                pr.addError('Product Code is already present in the system. Please enter a unique Product Code.');
            }
        }
    }
}




/*public class unique_Product_Code_Identifier {
    
    /*
     *  Method Name:    checkDupProductCode 
     *  Description:    Method to check duplicate Product Code and give an Error.
     *  Param:          Trigger.new
     *  Return:         None
     */
   /* public static void checkDupProductCode(List<Product2> products, Map<Id, Product2> oldProductsMap){
        
        List<String> pCodes = new List<String>();
        for(Product2 pr: products) {
            if (oldProductsMap != null && oldProductsMap?.get(pr.Id).ProductCode != pr.ProductCode) {
                
                pCodes.add(pr.ProductCode);                    
            } else if (oldProductsMap == null) {
                
                pCodes.add(pr.ProductCode);
            }
        }
        
        List<Product2> oldProducts = [SELECT Id , ProductCode FROM Product2 WHERE ProductCode =: pCodes ];
        
        for(Product2 pr: products){
        
            if (oldProducts.size() > 0) {
            
               pr.addError('Product Code is already present in the system . Please enter unique Product Code .'); 
            }
        }        
    }
}*/