@isTest
public class OM_VID_StocksTableController_Test {
    
    @isTest
    static void testGetProductCode() {
        Product2 prod = new Product2(Name='Product X', OM_Product_Code_SIP__c='CODE456');
        insert prod;

        Product2 result = OM_VID_StocksTableController.getProductCode(prod.Id);
        System.assertEquals('CODE456', result.OM_Product_Code_SIP__c);
    }
    
    @isTest
        static void testmakeBWStocksCallout() {
            Test.setMock(WebServiceMock.class, new OM_SapFunctionsMock_Test());
            Test.startTest();
            OM_VID_StocksTableController.makeBWStocksCallout(
                '2024','01','M001', '256532123'
            );
            Test.stopTest();
        }
    
    @isTest
    static void testGetTableData() {
        // Mock necesario si el método hace un callout real
        Test.setMock(WebServiceMock.class, new OM_SapFunctionsMock_Test());

        Test.startTest();
        OM_VID_StocksTableController.TableWrapper result =
            OM_VID_StocksTableController.getTableData(
                '2024',  '01', 'ADDR001', '256532123'
            );
        Test.stopTest();

        System.assertNotEquals(null, result);
       System.assertNotEquals(null, result.tableData);
        System.assert(result.tableData.size() > 0, 'Se esperaban datos en tableData');
    }
    
}