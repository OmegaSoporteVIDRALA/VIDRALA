/* -----------------------------------------------------------------------------------------------------------------------
   Name:        DispatchStagingValidationTest.cls
   Description: Test class for DispatchStagingValidation.cls

   Date         Version Author              Summary of Changes
   -----------  ------- ------------------  ------------------------------------------------------------------------------
   Aug 2025		1.0		Globant				Initial Release
------------------------------------------------------------------------------------------------------------------------ */
@isTest
private class DispatchStagingValidationTest {

    @isTest
    static void testCleanTimeFields() {
        Dispatch_Staging__c rec = new Dispatch_Staging__c(
            Dispatch_Time__c = '1:2:3',
            Planned_Delivery_Time__c = '09:05',
            Planned_Check_In_Time__c = 'bad-time',
            Planned_Loading_Start_Time__c = ' 15:5 ',
            Planned_Loading_End_Time__c = null,
            Planned_Transport_Start_Time__c = '20:00:59',
            Planned_Transport_End_Time__c = '25:00:00', // invalid hour, will null out
            Planned_Time_for_Processing__c = '07:07:07',
            Time_of_Transportation_Processing__c = '',
            Actual_Loading_Start_Time__c = '11:5',
            Actual_Loading_End_Time__c = 'invalid',
            Actual_Shipment_End_Time__c = '01:01:01',
            Actual_Transport_Start_Time__c = ' 3:4:5 ',
            Current_Time_of_Check_In__c = '05:05',
            Entry_Time__c = ' 23:59:59 '
        );

        Test.startTest();
        DispatchStagingValidation.cleanTimeFields(new List<Dispatch_Staging__c>{rec});
        Test.stopTest();

        System.assertEquals('01:02:03', rec.Dispatch_Time__c, 'Should normalize time to HH:mm:ss');
        System.assertEquals(null, rec.Planned_Check_In_Time__c, 'Bad time should be null');
        System.assertEquals('25:00:00', rec.Planned_Transport_End_Time__c, 'Hour out of normal range still stored as-is');
    }

    @isTest
    static void testPopulateDerivedFields() {
        Dispatch_Staging__c rec1 = new Dispatch_Staging__c(
            Number_of_Material_Document__c = '123001',
            SAP_Material_Code__c = '45600123',
            Customer_Code__c = '10001'
        );

        Dispatch_Staging__c rec2 = new Dispatch_Staging__c(
            Number_of_Material_Document__c = '123002',
            SAP_Material_Code__c = null
        );

        Dispatch_Staging__c rec3 = new Dispatch_Staging__c(
            Number_of_Material_Document__c = null,
            SAP_Material_Code__c = '45600567'
        );

        Test.startTest();
        DispatchStagingValidation.populateDerivedFields(new List<Dispatch_Staging__c>{rec1, rec2, rec3});
        Test.stopTest();

        System.assertEquals('123001-45600123', rec1.Salesforce_Unique_Id__c, 'Should concatenate material doc and SAP code');
        System.assertEquals('10001', rec1.Encirc_Account_Number__c, 'Customer code should map to Encirc Account Number');
        System.assertEquals(null, rec2.Salesforce_Unique_Id__c, 'Should remain null if one field is blank');
    }
}