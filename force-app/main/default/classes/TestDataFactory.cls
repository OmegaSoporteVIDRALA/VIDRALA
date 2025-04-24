/* -----------------------------------------------------------------------------------------------------------------------
   Name:        TestDataFactory.cls
   Description: Generate test data for various Salesforce objects
                    
   Date         Version Author              Summary of Changes 
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Dec 2016     1.0     M.Witchalls(Ciber)  Initial Release 
   Sep 2024     2.0     Globant             Refactored code, added error handling, removed debug statements
------------------------------------------------------------------------------------------------------------------------ */        
@isTest
public class TestDataFactory {
    
    /** Mapping of month numbers to their abbreviations */
    public static final Map<Integer, String> monthMap = new Map<Integer, String>{
        1 => 'JAN', 2 => 'FEB', 3 => 'MAR', 4 => 'APR', 5 => 'MAY', 6 => 'JUN',
        7 => 'JUL', 8 => 'AUG', 9 => 'SEP', 10 => 'OCT', 11 => 'NOV', 12 => 'DEC'
    };

    /** The current year */
    private static final Integer thisYear = System.today().year();
    /** Prefix for product codes */
    private static String prefix = 'BB';
    /** Sales organization code */
    private static final String salesOrg = 'EN60'; 
    
    
    /**
     * @description Creates an Account record with an active contract status. 
     *              This account has no contract expiration date and a default commercial contract status.
     * @return Account - The Account record representing an active customer account.
     */
    public static Account createActiveCustomerAccount() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customers').getRecordTypeId();
        return new Account(
            RecordTypeId = accRecordTypeId,
            Name = 'Test account',
            CurrencyIsoCode = 'GBP'
        );
    }
    
    /**
     * Creates a Consumer Complaint record for the specified Account.
     * 
     * @param accountId The Id of the Account associated with the Consumer Complaint.
     * @param plant The name of the plant where the issue occurred.
     * @param faultPresent Indicates if a manufacturing fault is present ('Yes' or 'No').
     * @return Consumer_Complaint__c The Consumer Complaint instance (not inserted).
     */
    public static Consumer_Complaint__c createConsumerComplaint(Id accountId, String plant, String faultPresent) {
        return new Consumer_Complaint__c(
            Customer__c = accountId,
            Plant__c = plant,
            Manufacturing_Fault_Present__c = faultPresent
        );
    }

    /**
     * Creates a list of Consumer Complaint records for the specified Account.
     * 
     * @param accountId The Id of the Account associated with the Consumer Complaints.
     * @param count The number of Consumer Complaint records to create.
     * @return List<Consumer_Complaint__c> A list of Consumer Complaint instances (not inserted).
     */
    public static List<Consumer_Complaint__c> createConsumerComplaints(Id accountId, Integer count) {
        List<Consumer_Complaint__c> complaints = new List<Consumer_Complaint__c>();
        List<String> validPlants = new List<String>{'Unknown', 'Elton', 'Derrylin', 'Corsico'};

        for (Integer i = 0; i < count && i < validPlants.size(); i++) {
            complaints.add(createConsumerComplaint(accountId, validPlants[i], 'Yes'));
        }
        return complaints;
    }
    
    
    /**
     * Method to create Accounts with Commercial Contract Status records.
     * @return List of Accounts created for testing
     */
    public static List<Account> createTestAccountsWithContracts() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customers').getRecordTypeId();
        
        // Create accounts
        List<Account> accounts = new List<Account>{
            new Account(RecordTypeId = accRecordTypeId, Name = 'Test account', CurrencyIsoCode = 'GBP'),
            new Account(RecordTypeId = accRecordTypeId, Name = 'Test account 2', CurrencyIsoCode = 'GBP', 
                        Contract_Expire_Date__c = Date.today().addDays(-2), Commercial_Contract_Status__c = 'Green')
        };
        insert accounts;

        // Create Commercial Contract Status records
        List<Commercial_Contract_Status__c> contractStatuses = new List<Commercial_Contract_Status__c>{
            new Commercial_Contract_Status__c(Name = 'test 1', Account__c = accounts[0].Id, 
                                              Contract_Status__c = 'Amber', Start_date__c = Date.today().addDays(-2), 
                                              End_Date__c = Date.today().addDays(2)),
            new Commercial_Contract_Status__c(Name = 'test 2', Account__c = accounts[0].Id, 
                                              Contract_Status__c = 'Amber', Start_date__c = Date.today().addDays(-4), 
                                              End_Date__c = Date.today().addDays(-3))
        };
        insert contractStatuses;

        return accounts;
    }

    /** 
     * Creates accounts with associated months.
     * 
     * @param numAccts The number of accounts to create.
     * @param firstNum The starting number for account names and SAP numbers.
     * @return List of created accounts.
     */
    public static List<Account> createAccountsWithMonths(Integer numAccts, Integer firstNum) {
        if (numAccts <= 0) {
            return new List<Account>();
        }
    
        List<Account> accts = new List<Account>();
        List<Month__c> months = new List<Month__c>();
    
        for (Integer i = 0; i < numAccts; i++) {
            Account a = new Account(
                Name = 'EncircTestAcc' + (firstNum + i),
                SAP_Account_Number__c = String.valueOf(firstNum + i),
                Encirc_Account_Number__c = String.valueOf(firstNum + i)
            );
            accts.add(a);
        }
        insert accts;
    
        for (Account a: accts) {
            for (Integer j = 0; j < 12; j++) {
                months.add(
                    new Month__c(
                        Customer__c = a.Id,
                        Name = monthMap.get(j + 1),
                        Calendar_Month__c = monthMap.get(j + 1),
                        Year__c = String.valueOf(thisYear),
                        Sales_Organization__c = salesOrg
                    )
                );
            }
        }
        insert months;
    
        return [
            SELECT Id, Name, OwnerId, SAP_Account_Number__c, 
                (SELECT Id, Name, Calendar_Month__c, Year__c, Unique_ID__c FROM Months__r)
            FROM Account
            WHERE Name LIKE 'EncircTestAcc%'
        ];
	}


    /** 
     * Upserts products.
     * 
     * @param numProducts The number of products to upsert.
     * @return List of upserted products.
     */
    public static List<Bottle__c> upsertProducts(Integer numProducts) {
        if (numProducts <= 0) {
            return new List<Bottle__c>();
        }

        List<Bottle__c> bottles = new List<Bottle__c>();

        for (Integer i = 0; i < numProducts; i++) {
            String code = prefix + String.valueOf(1000 + i + 1);
            bottles.add(
                new Bottle__c(
                    Name = 'Bottle' + (i + 1),
                    Bottle_Identifier__c = code,
                    SAP_Material_Code__c = code,
                    SAP_Model_Number__c = code,
                    Weight_per_Unit__c = 200
                )
            );
        }
        upsert bottles Bottle_Identifier__c;
        return bottles;
    }

    /** 
     * Creates forecasts.
     * 
     * @param numBottles Number of bottles.
     * @param accountNum Account number prefix.
     * @param budget Budget amount.
     * @param forecast Forecast amount.
     * @return List of created forecasts.
     */
    public static List<Forecast__c> createForecasts(Integer numBottles, String accountNum, Integer budget, Integer forecast) {
        if (numBottles <= 0 || budget <= 0 || forecast <= 0) {
            return new List<Forecast__c>();
        }

        List<Bottle__c> bottles = upsertProducts(numBottles);
        List<Forecast__c> forecasts = new List<Forecast__c>();
        String acctNumPrefix = accountNum.leftPad(7, '0');

        for (Bottle__c b: bottles) {
            for (Integer j = 0; j < 12; j++) {
                String monthUniqueID = salesOrg + '-' + acctNumPrefix + '-' + String.valueOf(thisYear) + '-' + String.valueOf(j + 1).leftPad(2, '0');
                String uniqueID = monthUniqueID + '-' + b.Bottle_Identifier__c;

                forecasts.add(
                    new Forecast__c(
                        Month__r = new Month__c(Unique_ID__c = monthUniqueID),
                        Product__c = b.Id,
                        Name = b.Bottle_Identifier__c,                      
                        Unique_ID__c = uniqueID,
                        Budget__c = budget,
                        Forecast__c = forecast,
                        Budget_Tonnage__c = budget / 10,
                        Forecast_Tonnage__c = forecast / 10
                    )
                );                      
            }
        }
		upsert forecasts Unique_ID__c;
        return [
            SELECT Id, Name, Unique_ID__c, Month__c, Year__c, Month_No__c, Calendar_Month__c, Product__c, Product_Name__c, 
                Budget__c, Forecast__c, Budget_Tonnage__c, Forecast_Tonnage__c
            FROM Forecast__c
            WHERE Name LIKE 'BB%'
            ORDER BY Product_Name__c, Unique_ID__c
        ];
    }

    /** 
     * Creates dispatches.
     * 
     * @param numRecords Number of dispatch records.
     * @param accountId Account ID for dispatch.
     * @param f Forecast object.
     * @param units Number of units.
     * @return List of created dispatches.
     */
    public static List<Dispatch__c> createDispatches(Integer numRecords, String accountId, Forecast__c f, Integer units) {
        if (numRecords <= 0 || String.isEmpty(accountId) || f == null || units <= 0) {
            return new List<Dispatch__c>();
        }

        List<Dispatch__c> dispatches = new List<Dispatch__c>();

        for (Integer j = 0; j < numRecords; j++) {
            String dispatchId = String.valueOf(77000 + j + 1);
            String uniqueID = dispatchId + '-XX99-' + f.Year__c + '-' + f.Month__c + '-01';
            Date dispatchDate = Date.newInstance(Integer.valueOf(f.Year__c), Integer.valueOf(f.Month_No__c), 1);
            Datetime deliveryDate = Datetime.newInstance(dispatchDate, Time.newInstance(12, 0, 0, 0));

            dispatches.add(
                new Dispatch__c(
                    Name = 'Dispatch' + (j + 1),
                    Customer__c = accountId,
                    Month__c = f.Month__c,
                    Bottle__c = f.Product__c,
                    Forecast__c = f.Id,
                    Dispatch_ID__c = dispatchId,
                    Unique_ID__c = uniqueID,
                    Dispatch_Date__c = dispatchDate, 
                    Planned_Delivery_Date__c = deliveryDate,
                    Site_ID__c = 'ST',
                    Warehouse_ID__c = 'WH',
                    Units__c = units,
                    Tonnage__c = units / 10,
                    Sales_Organization__c = salesOrg
                )
            );                      
        }
		insert dispatches;
        
        return [
            SELECT Id, Name, Customer__c, Bottle__c, Dispatch_ID__c, Unique_ID__c, Year__c, Calendar_Month__c, Bottle_Identifier__c, 
                Dispatch_Date__c, Planned_Delivery_Date__c, Units__c, Tonnage__c
            FROM Dispatch__c
            ORDER BY Unique_ID__c
        ];
    }

    /** 
     * Creates sales history records.
     * 
     * @param numBottles Number of bottles.
     * @param accountId Account ID for sales history.
     * @param sales Number of sales.
     * @return List of created sales history records.
     */
    public static List<Actual_Sales_History__c> createSalesHistory(Integer numBottles, String accountId, Integer sales) {
        if (numBottles <= 0 || String.isEmpty(accountId) || sales <= 0) {
            return new List<Actual_Sales_History__c>();
        }

        List<Bottle__c> bottles = upsertProducts(numBottles);
        List<Actual_Sales_History__c> salesRecords = new List<Actual_Sales_History__c>();

        for (Integer year = thisYear - 1; year <= thisYear; year++) {
            for (Bottle__c b: bottles) {
                for (Integer j = 0; j < 12; j++) {
                    salesRecords.add(
                        new Actual_Sales_History__c(
                            Account__c = accountId,
                            Month__c = monthMap.get(j + 1),
                            Item__c = b.Bottle_Identifier__c,
                            Volume_000_s__c = sales,
                            Tonnes__c = sales / 10,
                            Revenue__c = 50 * sales,
                            Year__c = String.valueOf(year),
                            Sales_Organization__c = salesOrg
                        )
                    );                      
                }
            } 
        }
        insert salesRecords;
       
        return [
            SELECT Id, Name, Account__r.SAP_Account_Number__c, Month__c, Year__c, Item__c, Volume_000_s__c, Tonnes__c, Revenue__c
            FROM Actual_Sales_History__c
            WHERE Item__c LIKE 'AB%'
            ORDER BY Year__c, Item__c, Date__c
        ];
    }

    /** 
     * Creates dispatch staging records.
     * 
     * @param numProds Number of products.
     * @param accountNum Account number.
     * @param haulierNum Haulier number.
     * @param bottles Number of bottles.
     * @param tonnage Total tonnage.
     * @return List of created dispatch staging records.
     */
    public static List<Dispatch_Staging__c> createDispatchStaging(Integer numProds, String accountNum, String haulierNum, Integer bottles, Integer tonnage) {
        if (numProds <= 0 || String.isEmpty(accountNum) || String.isEmpty(haulierNum) || bottles <= 0 || tonnage <= 0) {
            return new List<Dispatch_Staging__c>();
        }

        List<Dispatch_Staging__c> dispatchStaging = new List<Dispatch_Staging__c>();

        for (Integer i = 0; i < numProds; i++) {
            String bottleName = 'Bottle' + i;
            String bottleIdentifier = prefix + String.valueOf(1000 + i + 1);

            for (Integer j = 0; j < 12; j++) {
                Date dispatchDate = Date.newInstance(thisYear, j + 1, 1);
                Date deliveryDate = dispatchDate.addDays(1);

                dispatchStaging.add(
                    new Dispatch_Staging__c(
                        Encirc_Account_Number__c = accountNum,
                        Customer_Name__c = 'Customer ' + accountNum,
                        Haulier_Code__c = haulierNum,
                        Haulier_Name__c = 'Haulier ' + haulierNum,
                        Site_ID__c = 'ST',
                        Warehouse_ID__c = 'WH',
                        Delivery_Name__c = 'Dispatch' + (j + 1),
                        Dispatch_ID__c = accountNum + bottleIdentifier + String.valueOf(500 + j + 1),
                        Bottle_Identifier__c = bottleIdentifier,
                        Bottle_Description__c = bottleName,
                        Dispatch_Date__c = dispatchDate,
                        Planned_Delivery_Date__c = deliveryDate,
                        Planned_Delivery_Time__c = '12:00:00',
                        Pack_Specification__c = 'XX99',
                        Bottles__c = bottles,
                        Tonnage__c = tonnage,
                        Sales_Organization__c = salesOrg,
                        SAP_Material_Code__c = '007009'
                    )
                );

                if (i == numProds - 1 && j == 11) {
                    dispatchStaging.add(
                        new Dispatch_Staging__c(
                            Encirc_Account_Number__c = accountNum,
                            Customer_Name__c = 'Customer ' + accountNum,
                            Haulier_Code__c = haulierNum,
                            Haulier_Name__c = 'Haulier ' + haulierNum,
                            Site_ID__c = 'ST',
                            Warehouse_ID__c = 'WH',
                            Delivery_Name__c = 'Dispatch' + (j + 1),
                            Dispatch_ID__c = accountNum + bottleIdentifier + String.valueOf(500 + j + 1),
                            Bottle_Identifier__c = bottleIdentifier,
                            Bottle_Description__c = bottleName,
                            Dispatch_Date__c = null,
                            Planned_Delivery_Date__c = deliveryDate,
                            Planned_Delivery_Time__c = '12:00:00',
                            Pack_Specification__c = 'XX99',
                            Bottles__c = bottles,
                            Tonnage__c = tonnage,
                            Sales_Organization__c = salesOrg
                        )
                    );
                }
            }
        }
        insert dispatchStaging;
       
        return [
            SELECT 
                Id, Delivery_Name__c, Dispatch_ID__c, Unique_ID__c, 
                Dispatch_Date__c, Planned_Delivery_Date__c, Planned_Delivery_Time__c,
                Encirc_Account_Number__c, Customer_Name__c, Haulier_Code__c, Haulier_Name__c, 
                Site_ID__c, Warehouse_ID__c,
                Bottle_Identifier__c, Bottle_Description__c, Pack_Specification__c, 
                Bottles__c, Units__c, Tonnage__c, Year__c, Calendar_Month__c, Week_in_Month__c
            FROM Dispatch_Staging__c
            WHERE Delivery_Name__c LIKE 'Dispatch%'
        ];
    }

    /** 
     * Creates a quote with associated records.
     * 
     * @return Created quote object.
     */
    public static Quote createQuote() {
        Account objAccount = new Account(
            Name = 'Test Acc1', BillingCity = 'Test City', BillingState = 'Test State', 
            BillingStreet = 'Test Street', BillingPostalCode = '12345', Market__c = 'FR',
            BillingCountry = 'Test Country', Phone = '123456'
        );
        insert objAccount;
    
        Product2 objProduct = new Product2(Name = 'Test product1', Family = 'Cafe');
        insert objProduct;
        
        Opportunity objOpp = new Opportunity(
            Name = 'Test Opp', AccountId = objAccount.Id, StageName = 'Verbal Confirmation', CloseDate = Date.today() + 1
        );
        insert objOpp;
    
        Quote testQuote = new Quote(
            OpportunityId = objOpp.Id, Name = 'Test Quote', Status = 'Review Pending', Account_Id_Copy__c = objAccount.Id
        );
        insert testQuote;
    
        return testQuote;
    }

}




// TODO remove once it has been tested/validated/QA-ed
/*public class TestDataFactory { 
    public static final Map<Integer,String> monthMap = new Map<Integer,String>{
        1 => 'jan',
        2 => 'feb',
        3 => 'mar',
        4 => 'apr',
        5 => 'may',
        6 => 'jun',
        7 => 'jul',
        8 => 'aug',
        9 => 'sep',
        10 => 'oct',
        11 => 'nov',
        12 => 'dec'
    };
    private static final Integer thisYear = System.today().year();
    private static String prefix = 'AB';
    private static final String salesOrg = 'EN60'; 

    public static List<Account> createAccountsWithMonths(Integer numAccts, Integer firstNum) {
        List<Account> accts = new List<Account>();
        Integer num = firstNum;
 
        for(Integer i=0; i<numAccts; i++) {
            Account a = new Account(
                Name = 'EncircTestAccount' + num,
                SAP_Account_Number__c = String.valueOf(num),
                Encirc_Account_Number__c = String.valueOf(num)
            );
            accts.add(a);
            num++;
        }
        insert accts;
         
        List<Month__c> months = new List<Month__c>();
        for (Account a: accts) {
            for (Integer j=0; j<12; j++) {
                String calendarMonth = (monthMap.get(j+1)).toUpperCase();
                months.add(
                    new Month__c(
                        Customer__c = a.Id,
                        Name = calendarMonth,
                        Calendar_Month__c = calendarMonth,
                        Year__c = String.valueOf(thisYear),
                        Sales_Organization__c = salesOrg
                    )
                );                      
            }
        }   
        system.debug(months);   
        insert months;
         
        return [
            SELECT Id, Name, OwnerId, SAP_Account_Number__c, 
                (SELECT Id, Name, Calendar_Month__c, Year__c, Unique_ID__c from Months__r)
            FROM Account
            WHERE Name LIKE 'EncircTestAccount%'
        ];
    }

    public static List<Bottle__c> upsertProducts(Integer numProducts) {
        List<Bottle__c> bottles = new List<Bottle__c>();
        for(Integer i=0; i<numProducts; i++) {
            String code = prefix + String.valueOf(1000 + i + 1);
            
            Bottle__c b = new Bottle__c(
                Name = 'Bottle' + i + 1,
                Bottle_Identifier__c = code,
                SAP_Material_Code__c = code,
                SAP_Model_Number__c = code,
                Weight_per_Unit__c = 200
             );
            bottles.add(b);
        }
        upsert bottles Bottle_Identifier__c;
        return bottles;
    }

    public static List<Forecast__c> createForecasts(Integer numBottles, String accountNum, Integer budget, Integer forecast) {
        List<Bottle__c> bottles = upsertProducts(numBottles);
         
        String acctNumPrefix = accountNum.leftPad(7).replace(' ','0');
        List<Forecast__c> forecasts = new List<Forecast__c>();
        
        for (Bottle__c b: bottles) {
            for (Integer j=0; j<12; j++) {
                String calendarMonth = (monthMap.get(j+1)).toUpperCase();
                String monthUniqueID = salesOrg + '-' + acctNumPrefix + '-' + String.valueOf(thisYear) + '-' + String.valueOf(j+1).leftPad(2).replace(' ','0');
                String uniqueID = monthUniqueID + '-' + b.Bottle_Identifier__c;
                forecasts.add(
                    new Forecast__c(
                        Month__r = new Month__c(Unique_ID__c = monthUniqueID),
                        Product__c = b.Id,
                        Name = b.Bottle_Identifier__c,                      
                        Unique_ID__c = uniqueID,
                        Budget__c = budget,
                        Forecast__c = forecast,
                        Budget_Tonnage__c = budget/10,
                        Forecast_Tonnage__c = forecast/10
                    )
                );                      
            }
        }   
        system.debug(forecasts);   
        upsert forecasts Unique_ID__c;
         
        return [
            SELECT Id, Name, Unique_ID__c, Month__c, Year__c, Month_No__c, Calendar_Month__c, Product__c, Product_Name__c, 
                Budget__c, Forecast__c, Budget_Tonnage__c, Forecast_Tonnage__c
            FROM Forecast__c
            WHERE Name LIKE 'AB%'
            ORDER BY Product_Name__c, Unique_ID__c
        ];
    }

    public static List<Dispatch__c> createDispatches(Integer numRecords, String accountId, Forecast__c f, Integer units) {         
        List<Dispatch__c> dispatches = new List<Dispatch__c>();
        
        for (Integer j=0; j<numRecords; j++) {
            String dispatchId = String.valueOf(77000 + j + 1);
            String pack = 'XX99';
            Integer mon = Integer.valueOf(f.Month_No__c);
            Integer yno = Integer.valueOf(f.Year__c);
            String uniqueID = dispatchId + '-' + pack + '-' + f.Year__c + '-' + f.Month_No__c + '-01';
            Date dispatchDate = Date.newInstance(yno, mon, 1);
            Datetime deliveryDate = Datetime.newInstance(dispatchDate, Time.newInstance(12,0,0,0));
            
            dispatches.add(
                new Dispatch__c(
                    Name = 'Dispatch' + j + 1,
                    Customer__c = accountId,
                    Month__c = f.Month__c,
                    Bottle__c = f.Product__c,
                    Forecast__c = f.Id,
                    Dispatch_ID__c = dispatchId,
                    Unique_ID__c = uniqueID,
                    Dispatch_Date__c = dispatchDate, 
                    Planned_Delivery_Date__c = deliveryDate,
                    Site_ID__c = 'ST',
                    Warehouse_ID__c = 'WH',
                    Units__c = units,
                    Tonnage__c = units/10,
                    Sales_Organization__c = salesOrg
                )
            );                      
        } 
        system.debug(dispatches);   
        insert dispatches;
         
        return [
            SELECT Id, Name, Customer__c, Bottle__c, Dispatch_ID__c, Unique_ID__c, Year__c, Calendar_Month__c, Bottle_Identifier__c, 
                Dispatch_Date__c, Planned_Delivery_Date__c, Units__c, Tonnage__c
            FROM Dispatch__c
            ORDER BY Unique_ID__c
        ];
    }

    public static List<Actual_Sales_History__c> createSalesHistory(Integer numBottles, String accountId, Integer sales) {
        List<Bottle__c> bottles = upsertProducts(numBottles);        
        List<Actual_Sales_History__c> salesRecords = new List<Actual_Sales_History__c>();
            
        for (Integer year=thisYear - 1; year<thisYear + 1; year++) {
            for (Bottle__c b: bottles) {
                for (Integer j=0; j<12; j++) {
                    String calendarMonth = (monthMap.get(j+1)).capitalize();
                    salesRecords.add(
                        new Actual_Sales_History__c(
                            Account__c = accountId,
                            Month__c = calendarMonth,
                            Item__c = b.Bottle_Identifier__c,
                            Volume_000_s__c = sales,
                            Tonnes__c = sales/10,
                            Revenue__c = 50 * sales,
                            Year__c = String.valueOf(year),
                            Sales_Organization__c = salesOrg
                        )
                    );                      
                }
            } 
        }  
        system.debug(salesRecords);   
        insert salesRecords;
         
        return [
            SELECT Id, Name, Account__r.SAP_Account_Number__c, Month__c, Year__c, Item__c, Volume_000_s__c, Tonnes__c, Revenue__c
            FROM Actual_Sales_History__c
            WHERE Item__c LIKE 'AB%'
            ORDER BY Year__c, Item__c, Date__c
        ];
    }


    public static List<Dispatch_Staging__c> createDispatchStaging(Integer numProds, String accountNum, String haulierNum, Integer bottles, Integer tonnage) {
 
        String acctNumPrefix = accountNum.leftPad(7).replace(' ','0');
        List<Dispatch_Staging__c> dispatchStaging = new List<Dispatch_Staging__c>();
        
        for(Integer i=0; i<numProds; i++) {
            String bottleName = 'Bottle'+i;
            String bottleIdentifier = 'AB'+String.valueOf(1000 + i + 1); 
            
            for (Integer j=0; j<12; j++) {
                Date dispatchDate = Date.newInstance(thisYear, j+1, 1);
                Date deliveryDate = dispatchDate + 1;
                
                dispatchStaging.add(
                    new Dispatch_Staging__c(
                        Encirc_Account_Number__c = accountNum,
                        Customer_Name__c = 'Customer '+accountNum,
                        Haulier_Code__c = haulierNum,
                        Haulier_Name__c = 'Haulier '+haulierNum,
                        Site_ID__c = 'ST',
                        Warehouse_ID__c = 'WH',
                        Delivery_Name__c = 'Dispatch' + j + 1,
                        Dispatch_ID__c = accountNum + bottleIdentifier + String.valueOf(500 + j + 1),
                        Bottle_Identifier__c = bottleIdentifier,
                        Bottle_Description__c = bottleName,
                        Dispatch_Date__c = dispatchDate,
                        Planned_Delivery_Date__c = deliveryDate,
                        Planned_Delivery_Time__c = '12:00:00',
                        Pack_Specification__c = 'XX99',
                        Bottles__c = bottles,
                        Tonnage__c = tonnage,
                        Sales_Organization__c = salesOrg
                    )
                );                      
            }
            // this next "if" only exists to test 2 specific cases: on DispatchStagingHandler.handleSpuriousDups() on the if (keySet.contains(key)), inside the for cicle
            // and in case Dispatch Date is null
            if (i == numProds-1)
            {
                Integer j = 11;
                Date dispatchDate = Date.newInstance(thisYear, j+1, 1);
                Date deliveryDate = dispatchDate + 1;
                dispatchStaging.add(
                    new Dispatch_Staging__c(
                        Encirc_Account_Number__c = accountNum,
                        Customer_Name__c = 'Customer '+accountNum,
                        Haulier_Code__c = haulierNum,
                        Haulier_Name__c = 'Haulier '+haulierNum,
                        Site_ID__c = 'ST',
                        Warehouse_ID__c = 'WH',
                        Delivery_Name__c = 'Dispatch' + j + 1,
                        Dispatch_ID__c = accountNum + bottleIdentifier + String.valueOf(500 + j + 1),
                        Bottle_Identifier__c = bottleIdentifier,
                        Bottle_Description__c = bottleName,
                        Dispatch_Date__c = dispatchDate,
                        Planned_Delivery_Date__c = deliveryDate,
                        Planned_Delivery_Time__c = '12:00:00',
                        Pack_Specification__c = 'XX99',
                        Bottles__c = bottles,
                        Tonnage__c = tonnage,
                        Sales_Organization__c = salesOrg
                    )
                );
                dispatchStaging.add(
                    new Dispatch_Staging__c(
                        Encirc_Account_Number__c = accountNum,
                        Customer_Name__c = 'Customer '+accountNum,
                        Haulier_Code__c = haulierNum,
                        Haulier_Name__c = 'Haulier '+haulierNum,
                        Site_ID__c = 'ST',
                        Warehouse_ID__c = 'WH',
                        Delivery_Name__c = 'Dispatch' + j + 1,
                        Dispatch_ID__c = accountNum + bottleIdentifier + String.valueOf(500 + j + 1),
                        Bottle_Identifier__c = bottleIdentifier,
                        Bottle_Description__c = bottleName,
                        Dispatch_Date__c = null,
                        Planned_Delivery_Date__c = deliveryDate,
                        Planned_Delivery_Time__c = '12:00:00',
                        Pack_Specification__c = 'XX99',
                        Bottles__c = bottles,
                        Tonnage__c = tonnage,
                        Sales_Organization__c = salesOrg
                    )
                );
            }
        }   
        system.debug(dispatchStaging);   
        insert dispatchStaging;
         
        return [
            SELECT 
                Id, Delivery_Name__c, Dispatch_ID__c, Unique_ID__c, 
                Dispatch_Date__c, Planned_Delivery_Date__c, Planned_Delivery_Time__c,
                Encirc_Account_Number__c, Customer_Name__c, Haulier_Code__c, Haulier_Name__c, 
                Site_ID__c, Warehouse_ID__c,
                Bottle_Identifier__c, Bottle_Description__c, Pack_Specification__c, 
                Bottles__c, Units__c, Tonnage__c, Year__c, Calendar_Month__c, Week_in_Month__c
            FROM Dispatch_Staging__c
            WHERE Delivery_Name__c LIKE 'Dispatch%'
        ];
    }

    public static Quote createQuote() {
        Account objAccount = new Account(Name = 'Test Acc1', BillingCity = 'Test City', BillingState = 'Test State', 
        BillingStreet = 'Test Street', BillingPostalCode = '12345', Market__c = 'FR',
        BillingCountry = 'Test Country', Phone = '123456');

        insert objAccount;

        Product2 objProduct = new Product2(Name = 'Test product1', family = 'Cafe');
                                                    
        insert objProduct;
        
        Opportunity objOpp = new Opportunity(Name = 'Test Opp', AccountId = objAccount.Id, StageName = 'Verbal Confirmation', CloseDate = Date.today()+1);
        insert objOpp;

        Quote testQuote = new Quote(OpportunityId = objOpp.Id, Name = 'Test Quote', Status = 'Review Pending');
        insert testQuote;

        System.debug('testQuote='+testQuote.AccountId);

        return testQuote;
    }

}*/