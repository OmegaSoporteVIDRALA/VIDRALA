@IsTest
private with sharing class AccountTeamControllerTest {

    @TestSetup
    static void initData() {
        Account acc = TestDataFactory.createActiveCustomerAccount();
        acc.Name = 'Test account'; 
        insert acc;
    }

    @IsTest
    private static void getTeamMembersTest() {
        List<Account> testAccounts = [
            SELECT Id, Name 
            FROM Account 
            WHERE Name = 'Test account'
            LIMIT 1
        ];

        System.assert(testAccounts.size() == 1, 'There should be at least one account.');

        List<String> accountIds = new List<String>{ testAccounts[0].Id };

        Test.startTest();
            Map<Id, Account> accTeamMembersMap = AccountTeamController.getTeamMembers(accountIds);
        Test.stopTest();

        System.assert(accTeamMembersMap.containsKey(testAccounts[0].Id), 'The map should contain the test account Id');

        Account accountWithTeamMembers = accTeamMembersMap.get(testAccounts[0].Id);
        System.assertEquals('Test account', accountWithTeamMembers.Name);
    }

    @IsTest
    private static void getTeamMembersTestNoIds() {
        Test.startTest();
        try {
            AccountTeamController.getTeamMembers(new List<String>());
            System.assert(false, 'A CustomException should have been thrown for empty Ids');
        } catch (AccountTeamController.CustomException e) {
            System.assertEquals('No record Ids provided.', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    private static void getTeamMembersTestInvalidIds() {
        Test.startTest();
        try {
            AccountTeamController.getTeamMembers(new List<String>{ 'invalidId' });
            System.assert(false, 'A CustomException should have been thrown for invalid Ids');
        } catch (AccountTeamController.CustomException e) {
            System.assertEquals('No valid Accounts found for the provided Ids.', e.getMessage());
        }
        Test.stopTest();
    }
}


/*@IsTest
private with sharing class AccountTeamControllerTest {
    
    @TestSetup
    static void initData(){
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customers').getRecordTypeId();
        Account acc = new Account(RecordTypeId = accRecordTypeId,
                                    Name = 'Text account',
                                    CurrencyIsoCode = 'GBP');
        insert acc;
    }

    @IsTest
    private static void getTeamMembersTest(){      
        Test.startTest();
            Account testAccount = [
                SELECT Id, Name 
                FROM Account
                LIMIT 1
            ];
            Account accMembers = AccountTeamController.getTeamMembers(testAccount.Id);
        Test.stopTest();  
        System.assertEquals('Text account', accMembers.Name);     
    }
}*/