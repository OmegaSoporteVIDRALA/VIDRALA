@IsTest
private class OM_BW_Wrapper_Test {

    @IsTest
    static void testBWWrapperStructures() {
        
        OM_BW_Wrapper.BWReport report = new OM_BW_Wrapper.BWReport();
        report.name = 'Test Report';
        report.reportDate = Date.today();
        report.numStockBOT = 100;
        report.totalValues.add(1500.50);
        
        System.assertEquals('Test Report', report.name);
        System.assertEquals(100, report.numStockBOT);
        System.assertNotEquals(null, report.rows, 'La lista de filas debe inicializarse en el constructor');

        
        OM_BW_Wrapper.BWStocksRow row = new OM_BW_Wrapper.BWStocksRow();
        row.centro = 'V001';
        row.material = 'MAT-01';
        row.ventas = '1000';
        row.dataValues.add('750.00');
        
        OM_BW_Wrapper.BWStocksDataHeader header = new OM_BW_Wrapper.BWStocksDataHeader();
        header.headers = new List<String>{'Header1', 'Header2'};
        
        System.assertEquals('V001', row.centro);
        System.assertEquals('750.00', row.dataValues[0]);
        System.assertEquals(2, header.headers.size());

        
        List<String> reasons = new List<String>{'Reason1'};
        OM_BW_Wrapper.BWFilter filterFull = new OM_BW_Wrapper.BWFilter(
            '2024', '2025', '01', '12', 'C001', 'S001', reasons, 'MOD-A', 'MAT-B', 'BATCH-01'
        );
        System.assertEquals('C001', filterFull.customerCode);
        System.assertEquals('BATCH-01', filterFull.batch);

       
        OM_BW_Wrapper.BWFilter filterSales = new OM_BW_Wrapper.BWFilter(
            '2024', '2025', '01', '12', 'VD50', 'GRP1'
        );
        System.assertEquals('VD50', filterSales.salesOrganization);
        System.assertEquals('GRP1', filterSales.salesGroup);

        
        OM_BW_Wrapper.BWFilter filterStock = new OM_BW_Wrapper.BWFilter(
            '2024', '03', 'MOD-X', 'LOT-Y'
        );
        System.assertEquals('2024', filterStock.yearFrom);
        System.assertEquals('LOT-Y', filterStock.batch);

        
        OM_BW_Wrapper.BWFilter filterTAM = new OM_BW_Wrapper.BWFilter(
            '2025', '01', 'GRP_MANAGER'
        );
        System.assertEquals('2025', filterTAM.yearFrom);
        System.assertEquals('01', filterTAM.monthFrom);
        System.assertEquals('GRP_MANAGER', filterTAM.salesGroup);
    }

    @IsTest
    static void testSerialization() {
        
        OM_BW_Wrapper.BWFilter filter = new OM_BW_Wrapper.BWFilter('2024', '01', 'GRP1');
        
        Test.startTest();
        String jsonStr = JSON.serialize(filter);
        System.assert(String.isNotBlank(jsonStr));
        
        OM_BW_Wrapper.BWFilter deserialized = (OM_BW_Wrapper.BWFilter)JSON.deserialize(jsonStr, OM_BW_Wrapper.BWFilter.class);
        System.assertEquals(filter.salesGroup, deserialized.salesGroup);
        Test.stopTest();
    }
}