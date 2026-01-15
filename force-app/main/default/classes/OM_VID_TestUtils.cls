@isTest
public class OM_VID_TestUtils {
    
    //Test Methods to create Users with profile
    public static User createVidralaUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Fifty Sales Office Profile'];
        User u = new User(Alias = 'vidUser', Email='vidralauser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='vidralauser@testorg.com');
        
        return u;
        
    }
    
    public static void createAccountsWithContacts(Integer accNumber){
        	Id customerRecordType = OM_Utils.RecordTypes.getRecordTypeByDevName('Account', 'Customers');
            List<Account> accListToInsert = new List<Account>();
            for(Integer i = 0; i < accNumber; i++){
                Account objAccount = new Account(Name = 'mockAcckount' + i.toString(), BillingCity = 'Test City', BillingState = 'Test State', 
                BillingStreet = 'Test Street', BillingPostalCode = '12345', Market__c = 'ES', RecordTypeId = customerRecordType, OM_VID_SalesOrganizations__c = 'VD10',
                BillingCountry = 'Test Country', Phone = '90909009'+i.toString(), SAP_Account_Number__c = '1234'+i.toString());
    
                accListToInsert.add(objAccount);
            }
            
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true; 
            Database.insert(accListToInsert, dml); 
    
            //insert accListToInsert;
            createContacts(accListToInsert);
    }
    
    public static void createContacts(List<Account> accList){
        List<Contact> conListToInsert = new List<Contact>();
        for(Account acc : accList){
            Contact cont = new Contact(FirstName = 'Test', LastName = acc.Name, Phone = acc.Phone, Email = 'test@test.com', AccountId = acc.Id);
            conListToInsert.add(cont);
        }

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true; 
        Database.insert(conListToInsert, dml);
        //insert conListToInsert;
    }

    public static void createDrawingWithContentVersion(String accountId/*, String productId*/){
        Drawing__c draw = new Drawing__c();
        draw.Account__c = accountId;
        //draw.Product__c = productId;
        draw.Name = '1234';
        insert draw;

        createContentVersion(draw.Id);
    }

    public static void createQuoteLineItem(OpportunityLineItem oppLine, String quoteId){
        QuoteLineItem qLine = new QuoteLineItem();
        qLine.OpportunityLineItemId = oppLine.Id;
        qLine.QuoteId = quoteId;
        qLine.Quantity = oppLine.Quantity;
        qLine.PricebookEntryId = oppLine.PricebookEntryId;
        qLine.Product2Id = oppLine.Product2Id;
        qLine.UnitPrice = oppLine.UnitPrice;
        qLine.Description = oppLine.Description;

        insert qLine;
    }

    public static void createContentVersion(String quoteId){
        ContentVersion contentVersion = new ContentVersion(Title = 'oferta cliente test', PathOnClient = 'Pic.jpg', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);

        insert contentVersion;

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        //create ContentDocumentLink  record

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = quoteId;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }

    public static void createQuotes(Integer quoteNum){
        List<Quote> quoteToInsert = new List<Quote>();
        List<Opportunity> oppList = createOpportunities(1);
        String recordTypeId = [SELECT Id from RecordType where SobjectType = :OM_VID_Constants.quoteName and DeveloperName = :OM_VID_Constants.quoteRTFifty].Id;
        for(Integer i = 0; i < quoteNum; i++){
            Quote q = new Quote(Name = 'Quote' + i.toString(),
            OpportunityId = oppList[0].Id,
            recordTypeId = recordTypeId,
            ExpirationDate = Date.today() + 30,
            OM_VID_DetallesAdicionales__c = 'Test');

            quoteToInsert.add(q);
        }

        insert quoteToInsert;
    }

    public static List<Opportunity> createOpportunities(Integer numOpp){
        String recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = :OM_VID_Constants.oppName AND DeveloperName =: OM_VID_Constants.opportunityRTFifty LIMIT 1].Id;

        createAccountsWithContacts(1);

        Account objAccount = [SELECT Id FROM ACCOUNT LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();

        List<Opportunity> oppsToInsert = new List<Opportunity>();
        for(Integer i = 0; i < numOpp; i++){
            Opportunity opp = new Opportunity(Name = 'Test Opp v' + i.toString(), pricebook2Id  = pricebookId, AccountId = objAccount.Id, StageName = 'Introduction', RecordTypeId = recordTypeId, CloseDate = Date.today() + 1, CurrencyIsoCode = 'EUR');
            opp.Market__c = 'ES';
            oppsToInsert.add(opp);
        }

        insert oppsToInsert;
        return [
            SELECT 
                Id, Name
            FROM Opportunity
            WHERE RecordTypeId = :recordTypeId
        ];
    }

    public static void createOpportunityLineItems(List<Opportunity> listOpps, Integer numOppLines, String drawId){
        // Use pricebookId to setup PricebookEntry records
        PricebookEntry pb = createPriceBookEntry();
        Product2 producto = [SELECT Id FROM Product2 LIMIT 1];
        if(drawId != '') producto.Drawing__c = drawId;
        update producto;

        List<OpportunityLineItem> oppLineToInsert = new List<OpportunityLineItem>();
        for(Opportunity opp : listOpps){
            for(Integer i = 0; i < numOppLines; i++){
                OpportunityLineItem oppLine = new OpportunityLineItem(OpportunityId = opp.Id, Product2Id = producto.iD, UnitPrice = 100, Volume_000_s__c = 3, PricebookEntryId = pb.Id, Description = 'Test', Quantity = 1);
                oppLineToInsert.add(oppLine);
            }
        }

        insert oppLineToInsert;
    }

    public static PricebookEntry createPriceBookEntry(){
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        
        Integer randomCode = Math.round(Math.random() * 8999) + 1000; 
        String codeStr = String.valueOf(randomCode);

        Product2 producto =new Product2();
        producto.Name='test';
        producto.productCode= codeStr;
        producto.isActive = true;
        producto.CurrencyIsoCode='EUR';        
        insert producto;

        PricebookEntry one = [SELECT ID, UnitPrice, IsActive, CurrencyISOCode FROM PricebookEntry WHERE CurrencyISOCode = 'EUR' LIMIT 1];
	    // one.pricebook2Id = standardPricebook.id;
	    // one.product2id =[SELECT Id FROM Product2 LIMIT 1].Id;
	    // one.unitprice = 1249.0;
	    // one.isactive = true;
	    // insert one;

        return one;
    }
    
    public static void createCases(Integer caseNum){
        List<Case> caseToInsert = new List<Case>();
        createAccountsWithContacts(1);
        Account objAccount = [SELECT Id FROM ACCOUNT LIMIT 1];
        
        String recordTypeId = [SELECT Id from RecordType where SobjectType = :OM_VID_Constants.caseName and DeveloperName = :OM_VID_Constants.insatisfaccionRTVidrala].Id;
        Product2 producto =new Product2();
        producto.Name='test';
        producto.productCode='1234';
        producto.isActive = true;
        producto.CurrencyIsoCode='EUR';        
        insert producto;
        
        Bottle__c botella = new Bottle__c(
                    Name = 'Bottle1',
                    Bottle_Identifier__c = '12324a',
                    SAP_Material_Code__c = '1234b',
                    SAP_Model_Number__c = '1234',
                    Weight_per_Unit__c = 200
                );
        insert botella;
        
        SAP_Material_Code__c material = new SAP_Material_Code__c(Material_Code_Key__c = '1234b');
        material.OM_ProductRef__c = producto.Id;
        material.Bottle__c = botella.Id;
        insert material;
        
        for(Integer i = 0; i < caseNum; i++){
            Case ins = new Case(
            	AccountId = objAccount.Id,
            	RecordTypeId = recordTypeId,
                OM_SAC_Categorizacion_Incidencia__c = 'A',
                OM_SAC_loteOAlbaran__c = '1234554',
                OM_SAC_Defecto__c = 'test',
                OM_SAC_modeloYDenominacion__c = producto.Id,
                OM_VID_Planta__c = '1030',
                OM_SAC_DetectadasEnClienteDeCuantas__c = '2',
                OM_VID_EAN__c = material.Id
			);

            caseToInsert.add(ins);
        }

        insert caseToInsert;
    }
}