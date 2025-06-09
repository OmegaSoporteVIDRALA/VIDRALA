@isTest
private class OM_VID_VentasAbonosTableController_Test {

    
    @testSetup
	static void isData() {
    
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customers').getRecordTypeId();

    	Account acc = new Account(
        Name = 'Test Account',
        SAP_Account_Number__c = '11268',
        RecordTypeId = customerRecordTypeId,
        OM_VID_SalesOrganizations__c = 'VD10' 
    );
    insert acc;
}

    @isTest
    static void testGetOrderReasonValues() {
        List<Map<String, String>> values = OM_VID_VentasAbonosTableController.getOrderReasonValues('Account', 'Type');
        System.assertNotEquals(null, values);
    }

    @isTest
    static void testGetModelValues() {
        List<Map<String, String>> values = OM_VID_VentasAbonosTableController.getModelValues('Account', 'Type');
        System.assertNotEquals(null, values);
    }

    @isTest
    static void testGetMaterials() {
        Product2 prod = new Product2(Name='Test Product', ProductCode='P123');
        insert prod;
        
		Bottle__c  bottle = new Bottle__c(Bottle_Identifier__c  = 'A', Name='test', Weight_per_Unit__c = 1.00 );
        insert bottle;        

        SAP_Material_Code__c material = new SAP_Material_Code__c(Bottle__c = bottle.id, Name='MAT-001', OM_ProductRef__c=prod.Id);
        insert material;

        List<String> materials = OM_VID_VentasAbonosTableController.getMaterials(prod.Id);
        System.assertEquals(1, materials.size());
        System.assertEquals('MAT-001', materials[0]);
    }

    @isTest
    static void testGetProductCode() {
        Product2 prod = new Product2(Name='Product X', OM_Product_Code_SIP__c='CODE456');
        insert prod;

        Product2 result = OM_VID_VentasAbonosTableController.getProductCode(prod.Id);
        System.assertEquals('CODE456', result.OM_Product_Code_SIP__c);
    }

    @isTest
    static void testGetAccountCode() {
        Account account = [SELECT Id, Name, SAP_Account_Number__c FROM Account WHERE SAP_Account_Number__c = '11268' LIMIT 1];

        Account result = OM_VID_VentasAbonosTableController.getAccountCode(account.Id);
        System.assertEquals('11268', result.SAP_Account_Number__c);
    }

    @isTest
    static void testMakeBWVACallout() {
        Test.setMock(WebServiceMock.class, new OM_SapFunctionsMockAbonosDev_Test());
        Test.startTest();
        OM_VID_VentasAbonosTableController.makeBWVACallout(
            '2024','2024','01','01','C001','S001',
            new List<String>{'R1'}, 'ModelX', 'M001', 'B001'
        );
        Test.stopTest();
    }

      @isTest
    static void testGetTableData() {
        // Mock necesario si el método hace un callout real
        Test.setMock(WebServiceMock.class, new OM_SapFunctionsMockAbonosDev_Test());

        Test.startTest();
        OM_VID_VentasAbonosTableController.TableWrapper result =
            OM_VID_VentasAbonosTableController.getTableData(
                '2024', '2024', '01', '12',
                'CUST001', 'ADDR001',
                new List<String>{'R1'}, 'ModelX', 'MAT001', 'B001'
            );
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.tableData);
        System.assert(result.tableData.size() > 0, 'Se esperaban datos en tableData');
    }
    
    
}