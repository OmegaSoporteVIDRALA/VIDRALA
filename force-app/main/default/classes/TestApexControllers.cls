/* -----------------------------------------------------------------------------------------------------------------------
   Name:        TestApexControllers.cls
   Description: Test Visualforece Page Controllers
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Dec 2017     1.0     M.Witchalls(Ciber)  Initial Release 
------------------------------------------------------------------------------------------------------------------------ */        
@isTest
private class TestApexControllers { 
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
    
}