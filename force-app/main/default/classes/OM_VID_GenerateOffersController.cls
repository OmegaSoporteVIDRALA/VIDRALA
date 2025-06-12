public class OM_VID_GenerateOffersController {
    
    @AuraEnabled
    public static String createQuote(Id opportunityId) {
        try {
            Opportunity opp = [
                SELECT Id, Name, OM_VID_NumQuotes__c, RecordTypeId, Description, Contact__c 
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1
            ];
            
            List<OpportunityLineItem> oppLineList = [
                SELECT Id, Quantity, PricebookEntryId, Product2Id, UnitPrice, Description, TotalPrice, OpportunityId, Price_Includes_Delivery__c, Pallet_Volume__c 
                FROM OpportunityLineItem 
                WHERE OpportunityId = :opportunityId
            ];
            
            RecordType rt = [
                SELECT Id, DeveloperName 
                FROM RecordType 
                WHERE DeveloperName = 'OM_VID_Quote_Fifty'  
                LIMIT 1
            ];
            
            Quote q = new Quote();
            q.Name = opp.Name + '_v' + opp.OM_VID_NumQuotes__c;
            q.OpportunityId = opp.Id;
            q.RecordTypeId = rt.Id;
            q.ExpirationDate = Date.today() + 30;
            q.OM_VID_DetallesAdicionales__c = opp.Description;
            q.ContactId = opp.Contact__c;
            insert q;
            
            List<QuoteLineItem> quoteLines = new List<QuoteLineItem>();
            for (OpportunityLineItem oppLine : oppLineList) {
                QuoteLineItem qLine = new QuoteLineItem();
                qLine.OpportunityLineItemId = oppLine.Id;
                qLine.QuoteId = q.Id;
                qLine.Quantity = oppLine.Quantity;
                qLine.PricebookEntryId = oppLine.PricebookEntryId;
                qLine.Product2Id = oppLine.Product2Id;
                qLine.UnitPrice = oppLine.UnitPrice;
                qLine.Description = oppLine.Description;
                qLine.OM_VID_Incoterms__c = oppLine.Price_Includes_Delivery__c;
                qLine.OM_VID_Pallet_Volume__c = oppLine.Pallet_Volume__c;
                quoteLines.add(qLine);
            }
            insert quoteLines;
            
            return 'Quote creada correctamente';
            
        } catch(Exception e) {
            throw new AuraHandledException('Error al crear la Quote: ' + e.getMessage());
        }
    }
}