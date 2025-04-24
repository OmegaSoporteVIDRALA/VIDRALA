/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchStagingHandler.cls
   Description: Handler class for processing of the Dispatch_Staging__c object
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Jun 2018     1.0     M.Witchalls(Cloud9) Handling of spurious duplicates/Haulier Code 0 if null
   Sep 2024     1.1     Globant             Code refactoring and added comments
------------------------------------------------------------------------------------------------------------------------ */        

public class DispatchStagingHandler {

    /**
     * Processes a list of Dispatch_Staging__c records to handle spurious duplicates and ensures that null Haulier Codes are set to '0'.
     * 
     * @param itemList - The list of Dispatch_Staging__c records to be processed.
     */
    public void handleSpuriousDups(List<Dispatch_Staging__c> itemList) {
        if (itemList == null || itemList.isEmpty()) {
            return; 
        }

        Set<String> keySet = new Set<String>();
        for (Integer n = 0; n < itemList.size(); n++) {
            Dispatch_Staging__c item = itemList[n];

            // Set Haulier Code to '0' if null
            if (String.isBlank(item.Haulier_Code__c)) {
                item.Haulier_Code__c = '0';
            }

            String key = keyString(
                item.Dispatch_ID__c,
                item.SAP_Material_Code__c,
                item.Pack_Specification__c,
                item.Dispatch_Date__c, 
                item.Dispatch_Time__c
            );
           			
            if (keySet.contains(key)) {
                item.Dispatch_ID__c = item.Dispatch_ID__c + 'XX' + String.valueOf(n);
                key = keyString(
                    item.Dispatch_ID__c,
                    item.SAP_Material_Code__c,
                    item.Pack_Specification__c,
                    item.Dispatch_Date__c,
                    item.Dispatch_Time__c
                );
            }

            keySet.add(key);
        }
    }

    /**
     * Generates a unique key string for a Dispatch_Staging__c record based on its fields.
     * 
     * @param di - Dispatch ID
     * @param mc - SAP Material Code
     * @param ps - Pack Specification
     * @param dd - Dispatch Date
     * @param dt - Dispatch Time
     * @return A unique key string.
     */
    private String keyString(String di, String mc, String ps, Date dd, String dt) {
        if (di == null) {
            di = ''; 
        }
        if (mc == null) {
            mc = ''; 
        }
        if (ps == null) {
            ps = ''; 
        }
        if (dt == null) {
            dt = ''; 
        }

        if (dd == null) {
            dd = Date.today();
        }

        return di + mc + ps + dd.format() + dt;
    }
}


/*public class DispatchStagingHandler {

    public void handleSpuriousDups(List<Dispatch_Staging__c> itemList) {
        Set<String> keySet = new Set<String>();
        for (Integer n=0; n<itemList.size(); n++) {
            Dispatch_Staging__c item = itemList[n];
            
            // Haulier Code 0 if null
            if (item.Haulier_Code__c == null) item.Haulier_Code__c = '0';
            
            String key = keyString(
                item.Dispatch_ID__c,
                item.SAP_Material_Code__c,
                item.Pack_Specification__c,
                item.Dispatch_Date__c, 
                item.Dispatch_Time__c
            );
            if (keySet.contains(key)) {
                item.Dispatch_ID__c = item.Dispatch_ID__c + 'XX' + String.valueOf(n);
                key = keyString(
                    item.Dispatch_ID__c,
                    item.SAP_Material_Code__c,
                    item.Pack_Specification__c,
                    item.Dispatch_Date__c,
                    item.Dispatch_Time__c
                );
            }
            keySet.add(key);
        }
    }
    
    private String keyString(String di, String mc, String ps, Date dd, String dt) {
        
        //@Antony If client doesn't want null dates to default to current date, delete this if!
        if (dd == null)
        {
            dd = Date.today();
        }
        
        return di + mc + ps + dd.format() + dt;
    }
     
}*/