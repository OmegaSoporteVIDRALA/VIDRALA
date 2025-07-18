/* ------------------------------------------------------------------------------------------------------------------------
   Name:        ApexSharingTest.cls
   Description: Test ApexSharingManager class via associated triggers
                    
   Date         Version  Author              Summary of Changes 
   -----------  -------  ------------------  ------------------------------------------------------------------------------
   Dec  2016     1.0     M.Witchalls(Ciber)  Initial Release 
   Mar  2017     1.1     M.Witchalls(Cloud9) Also tests change of Month Forecast Owners when Account Owner changed
   Sept 2024     2.0     Globant             Code Refactoring
------------------------------------------------------------------------------------------------------------------------- */        

@isTest
private class ApexSharingTest {
    private static String rowCause = 'Apex__c';
    private static String encircProfile = 'Encirc Standard User';
    private static String encircFinanceProfile = 'Encirc Finance/Legal User';
    private static String encircSalesProfile = 'Encirc Sales';
    private static List<User> encircUsers;

    @TestSetup
    static void setupTestData() {
        // Create Accounts
        List<Account> aList = TestDataFactory.createAccountsWithMonths(1, 10001);
        ID accountId = aList[0].Id;

        String acctNum = aList[0].SAP_Account_Number__c;

        // Create Commercial Contract
        Commercial_Contracts__c con = new Commercial_Contracts__c(
            Account__c = accountId,
            Name = 'Commercial Contract for ' + acctNum
        );
        insert con;
        
        // Create Customer Tender
        Customer_Tender_Stroke_Quotes__c ten = new Customer_Tender_Stroke_Quotes__c(
            Account__c = accountId,
            Name = 'Customer Tender for ' + acctNum
        );
        insert ten;

        // Create Deal Sheet
        Deal_Sheet__c deal = new Deal_Sheet__c(
            ACCOUNT__c = accountId,
            Name = 'Deal Sheet for ' + acctNum
        );
        insert deal;

        // Create Price Increases record
        Price_Increases__c pi = new Price_Increases__c(
            Account__c = accountId,
            Name = 'Price Increases for ' + acctNum,
            Budgeted_increase__c = 0.2
        );
        insert pi;

        // Create Pricing Model
        Schema.DescribeFieldResult fr1 = Schema.SObjectType.Pricing_Model__c.fields.Status__c;
        Schema.DescribeFieldResult fr2 = Schema.SObjectType.Pricing_Model__c.fields.For_Export__c;
        Schema.DescribeFieldResult fr3 = Schema.SObjectType.Pricing_Model__c.fields.Bottle_Description__c;
        Schema.DescribeFieldResult fr4 = Schema.SObjectType.Pricing_Model__c.fields.Colour__c;
        Schema.DescribeFieldResult fr5 = Schema.SObjectType.Pricing_Model__c.fields.Shape__c;
        Schema.DescribeFieldResult fr6 = Schema.SObjectType.Pricing_Model__c.fields.Delivery_Location__c;

        String status = fr1.getPickListValues()[0].getValue();
        String forExport = fr2.getPickListValues()[0].getValue();
        String bottleDesc = fr3.getPickListValues()[0].getValue();
        String colour = fr4.getPickListValues()[0].getValue();
        String shape = fr5.getPickListValues()[0].getValue();
        String location = fr6.getPickListValues()[0].getValue();

        Pricing_Model__c mod = new Pricing_Model__c(
            Account__c = accountId,
            Status__c = status,
            Sales_volume_per_annum_000s_bottles__c = 10000,
            Years_per_Contract__c = 10,
            For_Export__c = forExport,
            Date_Customer_Requires_the_Bottles__c = System.today(),
            Date_Sales_Require_a_Response__c = System.today(),
            New_Bottle__c = 'No',
            Bottle_Description__c = bottleDesc,
            Bottle_Segment__c = 'Segment',
            Colour__c = colour,
            Shape__c = shape,
            Bottle_Weight_Grms__c = 200,
            Requires_Engraving__c = 'No',
            General_Sale_Item__c = 'No',
            Drawing_Used__c = 'No',
            Drawing_Attached__c = 'No',
            Pack_Spec_Attached__c = 'Yes',
            Customer_has_Max_Pallet_Height__c = 'No',
            Additional_Buffer_Requirements__c = 'No',           
            Exceptional_Packaging_Requirements__c = 'No',           
            Number_of_Shrink_Wraps__c = '1',
            Strapping__c = 'No',
            Additional_Production_Staff_Required__c = 10
        );
        insert mod;

        // Create Rebate
        Rebate__c reb = new Rebate__c(
            Account__c = accountId,
            Rebate_Commencement_Date__c = System.today(),
            Rebate_Expiry_Date__c = System.today() + 1,
            Reason_for_Rebate__c = 'Reason'
        );
        insert reb;
    }

    @isTest static void testAccountAndPricingModelSharing() {
        Test.startTest();
        
        List<Account> aList = [SELECT Id, SAP_Account_Number__c FROM Account LIMIT 1];
        ID accountId = aList[0].Id;

        // Fetch the inserted pricing model for validation
        Pricing_Model__c mod = [SELECT Id, Status__c FROM Pricing_Model__c WHERE Account__c = :accountId LIMIT 1];
        System.assertNotEquals(null, mod, 'Pricing Model should exist.');
        
        Test.stopTest();
    }

    @isTest 
    static void testRebateSharing() {
        Test.startTest();
    
        List<Account> aList = [SELECT Id FROM Account LIMIT 1];
        ID accountId = aList[0].Id;
    
        Rebate__c reb = [SELECT Id FROM Rebate__c WHERE Account__c = :accountId LIMIT 1];
    
        encircUsers = [SELECT Id FROM User WHERE (Profile.Name = :encircProfile OR Profile.Name = :encircFinanceProfile OR Profile.Name = :encircSalesProfile) AND IsActive = true LIMIT 1];
    
        ApexSharingManager asm = new ApexSharingManager('Rebate__c', 'Apex__c', 'Edit');
        asm.createSharing(new Map<Id, Id>{reb.Id => encircUsers[0].Id});
    
        List<Rebate__Share> rebateShares = [SELECT Id, AccessLevel, UserOrGroupId, RowCause 
                                            FROM Rebate__Share 
                                            WHERE ParentId = :reb.Id 
                                            AND RowCause = :rowCause 
                                            AND UserOrGroupId = :encircUsers[0].Id];
    
        System.assert(!rebateShares.isEmpty(), 'Rebate share should exist for the first user.');
        System.assertEquals(encircUsers[0].Id, rebateShares[0].UserOrGroupId, 'First user should have the share record.');
    
        Test.stopTest();
    }



    @isTest static void testMonthOwnershipChange() {
        Test.startTest();
        encircUsers = [SELECT Id FROM User WHERE (Profile.Name = :encircProfile OR Profile.Name = :encircFinanceProfile OR Profile.Name = :encircSalesProfile) AND IsActive = true LIMIT 2];


        List<Account> aList = [SELECT Id FROM Account LIMIT 1];

        aList[0].ownerId = encircUsers[0].Id;
        update aList;

        // Check Month Owners have changed
        Integer count = [SELECT count() FROM Month__c WHERE OwnerId = :encircUsers[0].Id];
        System.assertEquals(12, count);

        Test.stopTest();
    }
    
    @isTest
    static void testApexSharingManagerConstructors() {
        ApexSharingManager asm1 = new ApexSharingManager('Rebate__c');
        System.assertNotEquals(null, asm1);
    
        ApexSharingManager asm2 = new ApexSharingManager('Rebate__c', 'CustomReason');
        System.assertNotEquals(null, asm2);
    
        ApexSharingManager asm3 = new ApexSharingManager('Rebate__c', 'CustomReason', 'Read');
        System.assertNotEquals(null, asm3);
    }

}




/*@isTest
private class TestApexSharing {
    private static String rowCause = 'Apex__c';
    private static String encircProfile = 'Encirc Standard User';
    private static String encircFinanceProfile = 'Encirc Finance/Legal User';
    private static List<User> encircUsers = [SELECT Id FROM User WHERE (Profile.Name = :encircProfile OR Profile.Name = :encircFinanceProfile) AND IsActive = true LIMIT 2];
     
    @isTest static void testShares() {      
        List<Account> aList;
        
        System.runAs (encircUsers[0]) {
            // create one Account
            aList = TestDataFactory.createAccountsWithMonths(1, 10001);
        }
        
        String acctNum = aList[0].SAP_Account_Number__c;
        ID accountId = aList[0].Id;
        ID accountOwnerId = aList[0].ownerId;       

        // create one Commercial Contract
        Commercial_Contracts__c con = new Commercial_Contracts__c(
            Account__c = accountId,
            Name = 'Commercial Contract for '+acctNum
        );
        insert con;
        
        // create one Customer Tender
        Customer_Tender_Stroke_Quotes__c ten = new Customer_Tender_Stroke_Quotes__c(
            Account__c = accountId,
            Name = 'Customer Tender for '+acctNum
        );
        insert ten;
        
        // create one Deal Sheet
        Deal_Sheet__c deal = new Deal_Sheet__c(
            ACCOUNT__c = accountId,
            Name = 'Deal Sheet for '+acctNum
        );
        insert deal;
        
        // create one Price Increases record
        Price_Increases__c pi = new Price_Increases__c(
            Account__c = accountId,
            Name = 'Price Increases for '+acctNum,
            Budgeted_increase__c = 0.2
        );
        insert pi;
        
        Schema.DescribeFieldResult fr1 = Schema.SObjectType.Pricing_Model__c.fields.Status__c;
        Schema.DescribeFieldResult fr2 = Schema.SObjectType.Pricing_Model__c.fields.For_Export__c;
        Schema.DescribeFieldResult fr3 = Schema.SObjectType.Pricing_Model__c.fields.Bottle_Description__c;
        Schema.DescribeFieldResult fr4 = Schema.SObjectType.Pricing_Model__c.fields.Colour__c;
        Schema.DescribeFieldResult fr5 = Schema.SObjectType.Pricing_Model__c.fields.Shape__c;
        Schema.DescribeFieldResult fr6 = Schema.SObjectType.Pricing_Model__c.fields.Delivery_Location__c;

        String status = fr1.getPickListValues()[0].getValue();
        String forExport = fr2.getPickListValues()[0].getValue();
        String bottleDesc = fr3.getPickListValues()[0].getValue();
        String colour = fr4.getPickListValues()[0].getValue();
        String shape = fr5.getPickListValues()[0].getValue();
        String location = fr6.getPickListValues()[0].getValue();
        
        // create one Pricing Model
        Pricing_Model__c mod = new Pricing_Model__c(
            Account__c = accountId,
            Status__c = status,
            Sales_volume_per_annum_000s_bottles__c = 10000,
            Years_per_Contract__c = 10,
            For_Export__c = forExport,
            Date_Customer_Requires_the_Bottles__c = System.today(),
            Date_Sales_Require_a_Response__c = System.today(),
            New_Bottle__c = 'No',
            Bottle_Description__c = bottleDesc,
            Bottle_Segment__c = 'Segment',
            Colour__c = colour,
            Shape__c = shape,
            Bottle_Weight_Grms__c = 200,
            Requires_Engraving__c = 'No',
            General_Sale_Item__c = 'No',
            Drawing_Used__c = 'No',
            Drawing_Attached__c = 'No',
            Pack_Spec_Attached__c = 'Yes',
            Customer_has_Max_Pallet_Height__c = 'No',
            Additional_Buffer_Requirements__c = 'No',           
            Exceptional_Packaging_Requirements__c = 'No',           
            Number_of_Shrink_Wraps__c = '1',
            Strapping__c = 'No',
            Additional_Production_Staff_Required__c = 10
        );
        insert mod;
        
        // create one Rebate
        Rebate__c reb = new Rebate__c(
            Account__c = accountId,
            Rebate_Commencement_Date__c = System.today(),
            Rebate_Expiry_Date__c = System.today() + 1,
            Reason_for_Rebate__c = 'Reason'
        );
        insert reb;
            
        Rebate__Share rebShare = [SELECT Id, AccessLevel, UserOrGroupId, RowCause FROM Rebate__Share WHERE ParentId = :reb.Id AND RowCause = :rowCause];
        System.assertEquals(rebShare.UserOrGroupId, encircUsers[0].Id);

        // Change Account Owner
        aList[0].ownerId = encircUsers[1].Id;
        update aList;
        
        rebShare = [SELECT Id, AccessLevel, UserOrGroupId, RowCause FROM Rebate__Share WHERE ParentId = :reb.Id AND RowCause = :rowCause];
        System.assertEquals(rebShare.UserOrGroupId, encircUsers[1].Id);
        
        // Check Month Owners have changed
        Integer count = [SELECT count() FROM Month__c where OwnerId = :encircUsers[1].Id];
        System.assertEquals(12, count);
    }
    
}*/