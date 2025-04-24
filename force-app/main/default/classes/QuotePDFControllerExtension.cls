public class QuotePDFControllerExtension {
     
    public Quote quot {get; set;}
    public String accountInfo {get; set;}
    public String userQuoteInfo {get; set;}
    public List<QuoteItemWrapper> lineItems {get; set;}
    public List<Rebate__c> rebates {get; set;}
    public List<Rebate__c> childRebates {get; set;}
    public List<Packaging_Agreement__c> packageAgreements {get; set;}
    public List<Rebate__c> accountRebates {get; set;}
    public List<Discount__c> discounts {get; set;}
    public String accountName {get; set;}
    public String accountAddress {get; set;}
    public String accountStreet {get; set;}
    public String accountPhone {get; set;}
    public String accountEmail {get; set;}
    public String accountWebsite {get; set;}
    public String renderDiscount {get; set;}
    public String renderRebates {get; set;}
    public String renderDiscountTitle {get; set;}
    public String renderRebatesAccount {get; set;}
    public String renderThirdPage {get; set;}
    public String renderOnSecondPage {get; set;}
    public String dateFrom {get; set;}
    public String dateTo {get; set;}
    public String signature {get; set;}
    public String userInformation {get; set;}
    public String transporationCost {get; set;}
    public String expireDate {get; set;}
    public String endOfYear {get; set;}
    public Integer rowNumbers {get; set;}
	 
    public QuotePDFControllerExtension(ApexPages.StandardController stdController) {
        rowNumbers = 0;
        renderDiscountTitle = 'none';
        renderDiscount = 'none';
        renderRebates = 'none';
        renderRebatesAccount = 'none';
        renderThirdPage = 'none';
        renderOnSecondPage = '';
        endOfYear = date.newinstance(Date.today().year(), 12, 31).format();
        expireDate = Date.today().addDays(30).format();
    	Quote recordQuote = (Quote)stdController.getRecord();
    	lineItems = new List<QuoteItemWrapper>();
        quot = getRecord(recordQuote.Id);
        getQuoteUser(quot.Account.OwnerId);
        lineItems = getLineItems(recordQuote.Id, quot.OpportunityId);
        getRebates(quot.Id, quot.AccountId);
        getDiscounts(quot.AccountId);
        packageAgreements = getPackages(quot.AccountId);
        if (packageAgreements != null && !packageAgreements.isEmpty()) {
            transporationCost = packageAgreements[0].Portes_Devolucion__c;
        } 
        if (quot.Type__c == 'Scales') {
            renderRebatesAccount = '';
            renderDiscountTitle = '';
        } else if (quot.Type__c == 'Product') {
            renderRebates = '';
            renderDiscountTitle = '';
        } else if (quot.Type__c == 'Product and Scales') {
            renderRebatesAccount = '';
            renderRebates = '';
            renderDiscountTitle = '';
            renderThirdPage = '';
            renderOnSecondPage = 'none';
        }
        
        prepareHeader(quot.Account.Market__c);
        getUserInfo();
        accountInfo = quot.Account.Name + '\n ' + (quot.Account.BillingStreet != null ? quot.Account.BillingStreet + '\n ' : '') + 
            (quot.Account.BillingPostalCode != null ? quot.Account.BillingPostalCode + ' ' : '') +
            (quot.Account.BillingCity != null ? quot.Account.BillingCity + '\n ' : '') + (quot.Account.Phone != null ? 'Tel.' + quot.Account.Phone : '');
    }
	     
    private void getUserInfo() {
        User myUser = [SELECT Id, Username, LastName, Street, City FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (String.isNotEmpty(myUser.City)) {
        	userInformation = myUser.City + ', ';
        } else {
            userInformation = '';
        }
	}  
    
    private void getQuoteUser(String userId) {
        User myUser = [SELECT Id, Name, Title, Email, MobilePhone, Signature__c FROM User WHERE Id = :userId LIMIT 1];
        if (String.isNotBlank(myUser.Signature__c)) {
            String stringStyle = 'style="' + myUser.Signature__c.substringBetween('style="','"') + '"';
        	signature = myUser.Signature__c.replace(stringStyle, 'style="width:150px;height:150px"');
        }
        userQuoteInfo = ' \n ' + myUser.Name + ' \n ' + (myUser.Title != null ? myUser.Title + ' \n ' : '') + 
            (myUser.MobilePhone != null ? 'Tel.' + myUser.MobilePhone + ' \n ' : '') + myUser.Email;
	}
    
    private Quote getRecord(String recordId) {
        return [
            SELECT Id, Name, TotalPrice, Subtotal, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Description,
            	BillingAddress, Email, Phone, Account.Name, AccountId, Account.Market__c, Account.Agreed_Terms__c, Account.Forma_de_pago__c,
            	Account.Phone, Account.BillingStreet, Account.BillingCity, Account.BillingPostalCode, Rebate__r.Rebate_Commencement_Date__c,
            	Rebate__r.Rebate_Expiry_Date__c, CreatedById, QuoteNumber, OpportunityId, Account.CreatedById, Account.OwnerId, Type__c 
            FROM Quote 
            WHERE Id = :recordId
            LIMIT 1
        ];
    }
    
    private void getDiscounts(String accountId) {
        discounts = new List<Discount__c>();
        discounts = [
            SELECT Id, Account__c, TYPE__c, Product__r.ProductCode, 
            	Percentage__c, EUR__c, Quantity__c, Unit_Type__c 
            FROM Discount__c
            WHERE Account__c = :accountId
        ];
        if (discounts != null && !discounts.isEmpty()) {
            renderDiscount = '';
            renderDiscountTitle = '';
        }
    }
    
    private List<QuoteItemWrapper> getLineItems(String recordId, String opportunityId) {
        Map<String, QuoteItemWrapper> wrapperMap = new Map<String, QuoteItemWrapper>();
        List<QuoteLineItem> quoteItems = [
            SELECT Id, Product2.Colour__c, Product2.ProductCode, Product2.Name, UnitPrice, Product2Id, QuoteId
            FROM QuoteLineItem
            WHERE QuoteId = :recordId
        ];
        List<OpportunityLineItem> oppItems = [
            SELECT Id, OpportunityId, Product2Id, Price_Includes_Delivery__c 
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ];
        for(QuoteLineItem item: quoteItems) {
            QuoteItemWrapper itemWrapper = new QuoteItemWrapper(item.Product2.ProductCode, item.Product2.Name, item.Product2.Colour__c, null, item.UnitPrice);
            wrapperMap.put(item.Product2Id, itemWrapper);
        }
        for(OpportunityLineItem item: oppItems) {
            QuoteItemWrapper itemWrapper = wrapperMap.get(item.Product2Id);
            if (itemWrapper != null) {
            	itemWrapper.incoterm = item.Price_Includes_Delivery__c;
            }  
        }
        return wrapperMap.values();
    }
    
    private void getRebates(String quoteId, String accountId) {
        accountRebates = new List<Rebate__c>();
        childRebates = new List<Rebate__c>();
        rebates = [
            SELECT Id, Name, Account__c, Quote__c, Code__c, Percentage__c, Product__c, Product__r.Name, 
            	Scales__c, Product__r.ProductCode, Rebate_Expiry_Date__c, Rebate_Commencement_Date__c  
            FROM Rebate__c
            WHERE Account__c = :accountId
        ];
        for(Rebate__c item: rebates) {
            if (item.Product__c != null) {
                accountRebates.add(item); 
            }
            else {
                childRebates.add(item);
            }
        }
        if (rebates != null && !rebates.isEmpty()) {
        	if (rebates[0].Rebate_Commencement_Date__c != null) {
            	dateFrom = rebates[0].Rebate_Commencement_Date__c.format();
        	}
        	if (rebates[0].Rebate_Expiry_Date__c != null) {
            	dateTo = rebates[0].Rebate_Expiry_Date__c.format();
        	}
        } 
    }
    
    private List<Packaging_Agreement__c> getPackages(String accountId) {
        return [
            SELECT Id, Name, Debit_Price__c, Credit_Price__c, Material__c, Portes_Devolucion__c 
            FROM Packaging_Agreement__c
            WHERE Account__c = :accountId
        ];
    }
    
    private void prepareHeader(String accountMarket) {
        switch on accountMarket {
            when 'FR' {		
                accountName = 'VIDRALA FRANCE';
                accountAddress = '1, Quai Wilson La Porte De Bègles';
                accountStreet = '33130 Bègles, Gironde (France)';
                accountPhone = 'Tel. 05 56 20 59 89';
                accountEmail = 'commercial@vidrala.com';
                accountWebsite = 'www.vidrala.com';
            }	
            when 'PT'  {
                accountName = 'VIDRALA, S.A.';
                accountAddress = 'Barrio Munegazo, 22';
                accountStreet = '01400 Llodio, Alava (Spain)';
                accountPhone = 'Tel. 244 555 010';
                accountEmail = 'vendas@vidrala.com';
                accountWebsite = 'www.vidrala.com';
            }
            when 'ES' {
                accountName = 'VIDRALA, S.A.';
                accountAddress = 'Barrio Munegazo, 22';
                accountStreet = '01400 Llodio, Alava (Spain)';
                accountPhone = 'Tel. 94 671 97 10';
                accountEmail = 'comercial@vidrala.com';
                accountWebsite = 'www.vidrala.com';
            }
            when 'RM' {
                accountName = 'VIDRALA, S.A.';
                accountAddress = 'Barrio Munegazo, 22';
                accountStreet = '01400 Llodio, Alava (Spain)';
                accountPhone = 'Tel. 94 671 97 15';
                accountEmail = 'export@vidrala.com';
                accountWebsite = 'www.vidrala.com';
            }
            when 'NM' {
                accountName = 'VIDRALA, S.A.';
                accountAddress = 'Barrio Munegazo, 22';
                accountStreet = '01400 Llodio, Alava (Spain)';
                accountPhone = 'Tel. 94 671 97 15';
                accountEmail = 'export@vidrala.com';
                accountWebsite = 'www.vidrala.com';
            }
        }
    }
    
    public class QuoteItemWrapper {
        public String code {get; set;}
        public String name {get; set;}
        public String colour {get; set;}
        public String incoterm {get; set;}
        public Decimal price {get; set;}
 
        public QuoteItemWrapper(String code, String name, String colour, String incoterm, Decimal price) {
            this.code = code;
            this.name = name;
            this.colour = colour;
            this.incoterm = incoterm;
            this.price = price;
        }
    }

}