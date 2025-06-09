/*
* @TestedBy: OM_VID_AccountTRGHandler_UT
*/
public class OM_VID_AccountTRGHandlerMethods {
	private static List<String> vidralaSalesOrgs = new List<String>{'VD10','VD50'};
        
    public static void customerInsertActions(List<Account> newList){
        List<Account> destinatariosToInsert = new List<Account>();
    
        Id customerRecordType = OM_Utils.RecordTypes.getRecordTypeByDevName('Account', 'Customers');
        
        for(Account acc : newList){
            if(acc.RecordTypeId == customerRecordType && acc.SAP_Account_Number__c != null && acc.OM_VID_SalesOrganizations__c != null && checkIsVidralaAccount(acc.OM_VID_SalesOrganizations__c, vidralaSalesOrgs)){
                destinatariosToInsert.add(createDestinatarioMercancia(acc));
            }
            
        }
        System.debug('**destinatariosToInsert: '+destinatariosToInsert);
        if(destinatariosToInsert.size() > 0){
            OM_Utils.shouldSkipTriggerGlobal = true;
            insert destinatariosToInsert;
        }
    }
    
    @TestVisible
    private static Account createDestinatarioMercancia(Account acc){
        
        Id destinatarioRecordType = OM_Utils.RecordTypes.getRecordTypeByDevName('Account', 'OM_VID_Destinatario');
        Account destinatario = new Account();
        destinatario.RecordTypeId = destinatarioRecordType;
        destinatario.ParentId = acc.Id;
        destinatario.Name = acc.Name;
        destinatario.BillingStreet = acc.BillingStreet;
        destinatario.BillingCity = acc.BillingCity;
        destinatario.BillingPostalCode = acc.BillingPostalCode;
        destinatario.BillingCountry = acc.BillingCountry;
        destinatario.BillingState = acc.BillingState;
        destinatario.BillingLongitude = acc.BillingLongitude;
        destinatario.BillingLatitude = acc.BillingLatitude;
        destinatario.Phone = acc.phone; 
        destinatario.Market__c = acc.Market__c;
        destinatario.OM_VID_SalesOrganizations__c = acc.OM_VID_SalesOrganizations__c;
        destinatario.OwnerID = acc.OwnerId;

        return destinatario;
    }
    
    @TestVisible
    private static Boolean checkIsVidralaAccount(String salesOrganizations, List<String> vidralaSalesOrgs){
        Boolean isVidralaAccount = false;
        for(String salesOrg : vidralaSalesOrgs){
            if(salesOrganizations.split(';').contains(salesOrg)) isVidralaAccount = true;
        }
        return isVidralaAccount;
    }
    
    
    public static void setOwnerId(List<Account> newList) {
        
        Id destinatarioRecordType = OM_Utils.RecordTypes.getRecordTypeByDevName('Account', 'OM_VID_Destinatario');
        Set<Id> parentIds = new Set<Id>();
        Map<Id, Account> parentAccountsMap = new Map<Id, Account>();
        
   		for (Account acc : newList) {
       		if (acc.RecordTypeId == destinatarioRecordType && acc.ParentId != null && acc.OM_VID_SalesOrganizations__c != null && checkIsVidralaAccount(acc.OM_VID_SalesOrganizations__c, vidralaSalesOrgs)) {
                parentIds.add(acc.ParentId);
        	}
		} 
        
        if (!parentIds.isEmpty()) {
        	parentAccountsMap = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN :parentIds]);
    	}
        
        //if mapa no vacio
       if (parentAccountsMap != null) {
        	for (Account acc : newList) {
                if (acc.ParentId != null && parentAccountsMap.containsKey(acc.ParentId)) {
                    Account parentAcc = parentAccountsMap.get(acc.ParentId);
                    acc.OwnerId = parentAcc.OwnerId;
                }
            }
		}
   }
}