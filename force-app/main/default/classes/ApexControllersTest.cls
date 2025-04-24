/* -----------------------------------------------------------------------------------------------------------------------
   Name:        ApexControllersTest.cls
   Description: Test Visualforce Page Controllers
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Dec 2017     1.0     M.Witchalls(Ciber)  Initial Release 
   Oct 2024     1.1     Refactored          Refactored class for better testing practices
------------------------------------------------------------------------------------------------------------------------ */        
@isTest
private class ApexControllersTest { 
    private static String lateRecordType = 'Late_Load';
    private static String earlyRecordType = 'Early_Load';
    private static String collapsedRecordType = 'Collapsed_Load';
    
    @testSetup static void setup() {
        // create one Account
        List<Account> aList = TestDataFactory.createAccountsWithMonths(1, 10001);
        String acctNum = aList[0].SAP_Account_Number__c;
        ID accountId = aList[0].Id;
   
        // create 12 Forecasts
        List<Forecast__c> fList = TestDataFactory.createForecasts(1, acctNum, 800, 1000);
        // Create a dispatch record for the current month
        Integer i = System.today().month() - 1;
        List<Dispatch__c> dispatches = TestDataFactory.createDispatches(1, accountId, fList[i], 500); 
    }    
    
    @isTest static void testNewLateLoad() {
        // Fetch a dispatch record
        Dispatch__c d = [
            SELECT Id, Name, Customer__c, Bottle__c, Dispatch_ID__c, Unique_ID__c, Year__c, Calendar_Month__c, Bottle_Identifier__c, 
                Dispatch_Date__c, Planned_Delivery_Date__c, Units__c, Tonnage__c
            FROM Dispatch__c LIMIT 1
        ];

        Schema.DescribeFieldResult fr = Schema.SObjectType.Late_Load__c.fields.Reason_for_Delay__c;
        String reason = fr.getPickListValues()[0].getValue();
        
        PageReference pageRef = Page.NewLateLoad;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', d.Id);
       
        ApexPages.StandardController stdcon = new ApexPages.StandardController(d);
        NewLateLoadExtensionController con = new NewLateLoadExtensionController(stdcon);
        con.getReadOnlyFields();
        con.getLateLoadFields();
        con.getEarlyLoadFields();
        con.getCollapsedLoadFields();
        con.getCustomerInformedFields();
        con.getLinesDownFields();
        con.getReplacementFields();
        
        con.load.New_Delivery_Date__c = d.Planned_Delivery_Date__c + 1;
        con.load.Reason_for_Delay__c = reason;
        con.save();
        
        con.replacementChange();
        con.customerInformedChange();
        con.linesDownChange();

        // data null check
        con.load = null;
        con.save();
        con.replacementChange();
        con.customerInformedChange();

        // Negative
        ApexPages.currentPage().getParameters().put('id', '');
       
        ApexPages.StandardController stdconNeg = new ApexPages.StandardController(d);
        NewLateLoadExtensionController conNeg = new NewLateLoadExtensionController(stdcon);
    }
 
    @isTest
    static void testNewLateLoadOverride() {
        PageReference pageRef = Page.NewLateLoadOverride;
        Test.setCurrentPage(pageRef);
    
        ApexPages.StandardController stdcon = new ApexPages.StandardController(new Late_Load__c());
        NewLateLoadOverrideExtension con = new NewLateLoadOverrideExtension(stdcon);
    
        con.abortAction();
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size(), 'There should be one error message.');
        System.assertEquals(ApexPages.Severity.FATAL, messages[0].getSeverity(), 'Expected a FATAL error message.');
        System.assertEquals('New Late Load records must be created from the Dispatch Detail Page', 
            messages[0].getSummary(), 'The error message content should match.');
    
        PageReference cancelRedirect = con.cancel();
        Schema.DescribeSObjectResult schema = Late_Load__c.SObjectType.getDescribe();
        String expectedUrl = '/' + schema.getKeyPrefix() + '/o';
        System.assertEquals(expectedUrl, cancelRedirect.getUrl(), 'The URL should redirect to the Late Load list view.');
        System.assert(cancelRedirect.getRedirect(), 'The page should be set to redirect.');
    }

    
    @isTest
    static void testNewMonthForecastForYear() {
        Test.startTest();
        Account testAccount = new Account(Name = 'Test Account', SAP_Account_Number__c = '1234567');
        insert testAccount;
    
        PageReference pageRef = Page.NewMonthForecastForYear;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testAccount.Id);
    
        ApexPages.StandardController stdcon = new ApexPages.StandardController(testAccount);
        NewMonthForecastExtensionController con = new NewMonthForecastExtensionController(stdcon);
    
        con.isUK = true;
        con.isItaly = true;
        con.isSpain = true;
    
        con.check();
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size(), 'There should be one message after the check.');
        System.assertEquals(ApexPages.Severity.INFO, messages[0].getSeverity(), 'Expected an INFO message.');
        
        con.contin();
    
        List<Month__c> monthRecords = [SELECT Id, Customer__c, Year__c, Sales_Organization__c, Unique_ID__c FROM Month__c WHERE Customer__c = :testAccount.Id];
        System.assertEquals(36, monthRecords.size(), 'There should be 36 month forecast records (12 for UK, 12 for Italy, 12 for Spain).');
    
        Set<String> expectedSalesOrgs = new Set<String>{'EN60', 'VD30', 'VD10'};
        for (Month__c month : monthRecords) {
            System.assert(expectedSalesOrgs.contains(month.Sales_Organization__c), 'Unexpected Sales Organization for month record: ' + month.Sales_Organization__c);
        }
    
        String expectedYear = String.valueOf(System.today().year());
        for (Month__c month : monthRecords) {
            System.assertEquals(expectedYear, month.Year__c, 'The Year__c should match the current year.');
            System.assertEquals(testAccount.Id, month.Customer__c, 'The Customer__c should match the account ID.');
        }
    
        Set<String> uniqueIds = new Set<String>();
        for (Month__c month : monthRecords) {
            System.assert(!uniqueIds.contains(month.Unique_ID__c), 'Unique_ID__c should be unique for each month.');
            uniqueIds.add(month.Unique_ID__c);
        }
        Test.stopTest();
    }

    
    @isTest static void testMonthForecastList() {   
        Test.startTest();
        PageReference pageRef = Page.MonthForecastList;
        Test.setCurrentPage(pageRef);
        
        Account a = [SELECT Id, SAP_Account_Number__c FROM Account LIMIT 1];
        ApexPages.currentPage().getParameters().put('id', a.Id); 
                  
        ApexPages.StandardController stdcon = new ApexPages.StandardController(a);
        MonthForecastListController con = new MonthForecastListController(stdcon);
        
        System.assertNotEquals(null, con.theAccount, 'Expected theAccount to be initialized');
        System.assertEquals(a.Id, con.theAccount.Id, 'Expected theAccount to match the queried Account Id');
        
        List<Month__c> monthRecords = con.getRecords();
        
        System.assertNotEquals(null, monthRecords, 'Expected non-null list of month records');
        System.assertNotEquals(null, con.monthSetController, 'Expected monthSetController to be initialized');
        Test.stopTest();
    }


    
    @isTest static void testProductForecastList() {     
        Account a = [select Id, SAP_Account_Number__c from Account];    
        PageReference pageRef = Page.ProductForecastUnits;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('customerNo', a.SAP_Account_Number__c);
           
        ProductForecastListController con = new ProductForecastListController();
        ApexPages.StandardSetController setCon = con.setCon;  
        con.getRecords();
        con.getTotals();      
        
        List<Schema.FieldSetMember> unitsList = con.getUnitsList();
        List<Schema.FieldSetMember> tonnageList = con.getTonnageList();
        System.assertNotEquals(null, unitsList, 'Units list should not be null');
        System.assertNotEquals(null, tonnageList, 'Tonnage list should not be null');
        
        List<Schema.FieldSetMember> customerUnitsList = con.getCustomerUnitsList();
        List<Schema.FieldSetMember> customerTonnageList = con.getCustomerTonnageList();
        System.assertNotEquals(null, customerUnitsList, 'Customer units list should not be null');
        System.assertNotEquals(null, customerTonnageList, 'Customer tonnage list should not be null');
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('customerNo', '00000');  // Non-existing customerNo
        ProductForecastListController conNoMonth = new ProductForecastListController();
        ApexPages.StandardSetController setConNoMonth = conNoMonth.setCon;
        System.assertEquals(null, setConNoMonth, 'setCon should be null when no Month__c is found');
        Test.stopTest();
       
    }
    
    @isTest
    static void testDailyComparatives() {
        Test.startTest();
        
        DailyComparativesComponentController con = new DailyComparativesComponentController();
        
        List<DailyComparativesComponentController.Top20Record> units = con.getUnits();
        System.assertNotEquals(null, units, 'getUnits() should not return null');
        System.assert(!units.isEmpty(), 'getUnits() should return a non-empty list');
        
        DailyComparativesComponentController.Top20Record unitTotalsRecord = units[0];
        System.assertEquals('Current Month Totals', unitTotalsRecord.customer, 'First unit record should be the totals record');
        System.assertNotEquals(null, unitTotalsRecord.budget, 'Budget should not be null for totals record');
        System.assertNotEquals(null, unitTotalsRecord.forecast, 'Forecast should not be null for totals record');
        
        List<DailyComparativesComponentController.Top20Record> tonnage = con.getTonnage();
        System.assertNotEquals(null, tonnage, 'getTonnage() should not return null');
        System.assert(!tonnage.isEmpty(), 'getTonnage() should return a non-empty list');
        
        DailyComparativesComponentController.Top20Record tonnageTotalsRecord = tonnage[0];
        System.assertEquals('Current Month Totals', tonnageTotalsRecord.customer, 'First tonnage record should be the totals record');
        System.assertNotEquals(null, tonnageTotalsRecord.budget, 'Budget should not be null for totals record');
        System.assertNotEquals(null, tonnageTotalsRecord.forecast, 'Forecast should not be null for totals record');
        
        if (units.size() > 1) {
            DailyComparativesComponentController.Top20Record unitCustomerRecord = units[1];
            System.assertNotEquals(null, unitCustomerRecord.customer, 'Customer name should not be null for unit records');
            System.assertNotEquals('', unitCustomerRecord.hrefValue, 'HrefValue should not be empty for unit records');
        }
    
        if (tonnage.size() > 1) {
            DailyComparativesComponentController.Top20Record tonnageCustomerRecord = tonnage[1];
            System.assertNotEquals(null, tonnageCustomerRecord.customer, 'Customer name should not be null for tonnage records');
            System.assertNotEquals('', tonnageCustomerRecord.hrefValue, 'HrefValue should not be empty for tonnage records');
        }
        
        String unitsReportLink = con.getUnitsReportLink();
        System.assertNotEquals('', unitsReportLink, 'getUnitsReportLink() should return a non-empty URL');
        
        String tonnageReportLink = con.getTonnageReportLink();
        System.assertNotEquals('', tonnageReportLink, 'getTonnageReportLink() should return a non-empty URL');
        
        Test.stopTest();
    }

    
    @isTest static void testDailyOTIF() {       
        // Fetch a dispatch record
        Dispatch__c d = [ 
            SELECT Id, Name, Customer__c, Bottle__c, Dispatch_ID__c, Unique_ID__c, Year__c, Calendar_Month__c, Bottle_Identifier__c, 
                Dispatch_Date__c, Planned_Delivery_Date__c, Units__c, Tonnage__c
            FROM Dispatch__c LIMIT 1
        ];

        Schema.DescribeFieldResult fr = Schema.SObjectType.Late_Load__c.fields.Reason_for_Delay__c;
        String reason = fr.getPickListValues()[0].getValue();
        String objectName = Schema.SObjectType.Late_Load__c.Name;
        RecordType rtll = [SELECT Id FROM RecordType WHERE SObjectType = :objectName AND DeveloperName = :lateRecordType];
        RecordType rtel = [SELECT Id FROM RecordType WHERE SObjectType = :objectName AND DeveloperName = :earlyRecordType];
        RecordType rtcl = [SELECT Id FROM RecordType WHERE SObjectType = :objectName AND DeveloperName = :collapsedRecordType];

        // Create late load records
        Late_Load__c l1 = new Late_Load__c(
            RecordTypeId = rtll.Id,
            Customer__c = d.Customer__c,
            Product__c = d.Bottle__c,
            Dispatch__c = d.Id,
            New_Delivery_Date__c = d.Planned_Delivery_Date__c.addHours(1),
            Reason_for_Delay__c = reason,
            Status__c = 'Late',
            Collapsed__c = false        
        );
        Late_Load__c l2 = new Late_Load__c(
            RecordTypeId = rtel.Id,
            Customer__c = d.Customer__c,
            Product__c = d.Bottle__c,
            Dispatch__c = d.Id,
            New_Delivery_Date__c = d.Planned_Delivery_Date__c.addHours(-1),
            Reason_for_Early_Delivery__c = reason,
            Status__c = 'Early',
            Collapsed__c = false                        
        );
        Late_Load__c l3 = new Late_Load__c(
            RecordTypeId = rtcl.Id,
            Customer__c = d.Customer__c,
            Product__c = d.Bottle__c,
            Dispatch__c = d.Id,
            New_Delivery_Date__c = d.Planned_Delivery_Date__c,
            Status__c = 'On Time',
            Collapsed__c = true     
        );
        insert new List<Late_Load__c>{l1,l2,l3};        
        
        DailyOTIFComponentController con = new DailyOTIFComponentController();
        con.getRecords();
        con.getLast48hourLateReportLink();
        con.getLast48hourEarlyReportLink();
        con.getLast48hourCollapsedReportLink();
        con.getLateLoadReportLink();
        con.getEarlyLoadReportLink();
        con.getCollapsedLoadReportLink();
    }
    
}

/*@isTest
private class ApexControllersTest { 
    private static String lateRecordType = 'Late_Load';
    private static String earlyRecordType = 'Early_Load';
    private static String collapsedRecordType = 'Collapsed_Load';
    
    @testSetup static void setup() {
        // create one Account
        List<Account> aList = TestDataFactory.createAccountsWithMonths(1, 10001);
        String acctNum = aList[0].SAP_Account_Number__c;
        ID accountId = aList[0].Id;
   
        // create 12 Forecasts
        List<Forecast__c> fList = TestDataFactory.createForecasts(1, acctNum, 800, 1000);
        // Create a dispatch record for the current month
        Integer i = System.today().month() - 1;
        List<Dispatch__c> dispatches = TestDataFactory.createDispatches(1, accountId, fList[i], 500); 
    }    
    
    @isTest static void testNewLateLoad() {
        // Fetch a dispatch record
        Dispatch__c d = [
            SELECT Id, Name, Customer__c, Bottle__c, Dispatch_ID__c, Unique_ID__c, Year__c, Calendar_Month__c, Bottle_Identifier__c, 
                Dispatch_Date__c, Planned_Delivery_Date__c, Units__c, Tonnage__c
            FROM Dispatch__c LIMIT 1
        ];

        Schema.DescribeFieldResult fr = Schema.SObjectType.Late_Load__c.fields.Reason_for_Delay__c;
        String reason = fr.getPickListValues()[0].getValue();
        
        PageReference pageRef = Page.NewLateLoad;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', d.Id);
       
        ApexPages.StandardController stdcon = new ApexPages.StandardController(d);
        NewLateLoadExtensionController con = new NewLateLoadExtensionController(stdcon);
        con.getReadOnlyFields();
        con.getLateLoadFields();
        con.getEarlyLoadFields();
        con.getCollapsedLoadFields();
        con.getCustomerInformedFields();
        con.getLinesDownFields();
        con.getReplacementFields();
        
        con.load.New_Delivery_Date__c = d.Planned_Delivery_Date__c + 1;
        con.load.Reason_for_Delay__c = reason;
        con.save();
        
        con.replacementChange();
        con.customerInformedChange();
        con.linesDownChange();
    }
    
    @isTest static void testNewLateLoadOverride() {   
        PageReference pageRef = Page.NewLateLoadOverride;
        Test.setCurrentPage(pageRef);
       
        ApexPages.StandardController stdcon = new ApexPages.StandardController(new Late_Load__c());
        NewLateLoadOverrideExtension con = new NewLateLoadOverrideExtension(stdcon);
        con.abortAction();
        con.cancel();
    }
    
    @isTest static void testNewMonthForecastForYear() {   
        PageReference pageRef = Page.NewMonthForecastForYear;
        Test.setCurrentPage(pageRef);
        Account a = [SELECT Id, SAP_Account_Number__c FROM Account LIMIT 1];
        ApexPages.currentPage().getParameters().put('id', a.Id); 
              
        ApexPages.StandardController stdcon = new ApexPages.StandardController(a);
        NewMonthForecastExtensionController con = new NewMonthForecastExtensionController(stdcon);
        con.isUK = TRUE;
        con.isItaly = TRUE;
        con.isSpain = TRUE;
        con.check();
        con.contin();
    }
    
    @isTest static void testMonthForecastList() {   
        PageReference pageRef = Page.MonthForecastList;
        Test.setCurrentPage(pageRef);
        Account a = [SELECT Id, SAP_Account_Number__c FROM Account LIMIT 1];
        ApexPages.currentPage().getParameters().put('id', a.Id); 
              
        ApexPages.StandardController stdcon = new ApexPages.StandardController(a);
        MonthForecastListController con = new MonthForecastListController(stdcon);
        con.getRecords();
    }
    
    @isTest static void testProductForecastList() {     
        Account a = [select Id, SAP_Account_Number__c from Account];    
        PageReference pageRef = Page.ProductForecastUnits;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('customerNo', a.SAP_Account_Number__c);
        
        ProductForecastListController con = new ProductForecastListController();
        ApexPages.StandardSetController setCon = con.setCon;  
        con.getRecords();
        con.getTotals();      
    }
    
    @isTest static void testDailyComparatives() {       
        DailyComparativesComponentController con = new DailyComparativesComponentController();
        con.getUnits();
        con.getTonnage();     
    }
    
    @isTest static void testDailyOTIF() {       
        // Fetch a dispatch record
        Dispatch__c d = [ 
            SELECT Id, Name, Customer__c, Bottle__c, Dispatch_ID__c, Unique_ID__c, Year__c, Calendar_Month__c, Bottle_Identifier__c, 
                Dispatch_Date__c, Planned_Delivery_Date__c, Units__c, Tonnage__c
            FROM Dispatch__c LIMIT 1
        ];

        Schema.DescribeFieldResult fr = Schema.SObjectType.Late_Load__c.fields.Reason_for_Delay__c;
        String reason = fr.getPickListValues()[0].getValue();
        String objectName = Schema.SObjectType.Late_Load__c.Name;
        RecordType rtll = [SELECT Id FROM RecordType WHERE SObjectType = :objectName AND DeveloperName = :lateRecordType];
        RecordType rtel = [SELECT Id FROM RecordType WHERE SObjectType = :objectName AND DeveloperName = :earlyRecordType];
        RecordType rtcl = [SELECT Id FROM RecordType WHERE SObjectType = :objectName AND DeveloperName = :collapsedRecordType];

        // Create late load records
        Late_Load__c l1 = new Late_Load__c(
            RecordTypeId = rtll.Id,
            Customer__c = d.Customer__c,
            Product__c = d.Bottle__c,
            Dispatch__c = d.Id,
            New_Delivery_Date__c = d.Planned_Delivery_Date__c.addHours(1),
            Reason_for_Delay__c = reason,
            Status__c = 'Late',
            Collapsed__c = false        
        );
        Late_Load__c l2 = new Late_Load__c(
            RecordTypeId = rtel.Id,
            Customer__c = d.Customer__c,
            Product__c = d.Bottle__c,
            Dispatch__c = d.Id,
            New_Delivery_Date__c = d.Planned_Delivery_Date__c.addHours(-1),
            Reason_for_Early_Delivery__c = reason,
            Status__c = 'Early',
            Collapsed__c = false                        
        );
        Late_Load__c l3 = new Late_Load__c(
            RecordTypeId = rtcl.Id,
            Customer__c = d.Customer__c,
            Product__c = d.Bottle__c,
            Dispatch__c = d.Id,
            New_Delivery_Date__c = d.Planned_Delivery_Date__c,
            Status__c = 'On Time',
            Collapsed__c = true     
        );
        insert new List<Late_Load__c>{l1,l2,l3};        
        
        DailyOTIFComponentController con = new DailyOTIFComponentController();
        con.getRecords();
        con.getLast48hourLateReportLink();
        con.getLast48hourEarlyReportLink();
        con.getLast48hourCollapsedReportLink();
        con.getLateLoadReportLink();
        con.getEarlyLoadReportLink();
        con.getCollapsedLoadReportLink();
    }
    
}*/