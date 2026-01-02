@isTest
global class OM_SapFunctionsMockActualSalesH_Test implements WebServiceMock {
    global void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType
    ) {
        OM_SapFunctionsStyle.GetQueryViewDataResponse_element responseElement = 
            new OM_SapFunctionsStyle.GetQueryViewDataResponse_element();

        OM_SapFunctionsStyle.RrwsThxAxisData axisData = new OM_SapFunctionsStyle.RrwsThxAxisData();
        axisData.item = new List<OM_SapFunctionsStyle.RrwsSxAxisData>();

        OM_SapFunctionsStyle.RrwsSxAxisData axisItem = new OM_SapFunctionsStyle.RrwsSxAxisData();
        axisItem.Axis = '001';
        axisItem.Set_x = new OM_SapFunctionsStyle.RrwsTxSet();
        axisItem.Set_x.item = new List<OM_SapFunctionsStyle.RrwsSxTuple>();

        // Solo tuples necesarios para parseAxisData
        OM_SapFunctionsStyle.RrwsSxTuple tupleAccount = new OM_SapFunctionsStyle.RrwsSxTuple();
        tupleAccount.TupleOrdinal = '0';
        tupleAccount.Chanm = '0SOLD_TO';
        tupleAccount.ChavlExt = 'ACCT001';
        axisItem.Set_x.item.add(tupleAccount);

        OM_SapFunctionsStyle.RrwsSxTuple tupleProduct = new OM_SapFunctionsStyle.RrwsSxTuple();
        tupleProduct.TupleOrdinal = '0';
        tupleProduct.Chanm = '0MATERIAL__ZISDMODEL';
        tupleProduct.ChavlExt = 'MOD001';
        axisItem.Set_x.item.add(tupleProduct);

        OM_SapFunctionsStyle.RrwsSxTuple tupleMaterial = new OM_SapFunctionsStyle.RrwsSxTuple();
        tupleMaterial.TupleOrdinal = '0';
        tupleMaterial.Chanm = '0MATERIAL';
        tupleMaterial.Chavl = 'MAT001';
        tupleMaterial.ChavlExt = 'MAT001';
        axisItem.Set_x.item.add(tupleMaterial);

        axisData.item.add(axisItem);

        // Crear 20 celdas simuladas para buildRecords
        OM_SapFunctionsStyle.RrwsTCell cellData = new OM_SapFunctionsStyle.RrwsTCell();
        cellData.item = new List<OM_SapFunctionsStyle.RrwsSCell>();
        for (Integer i = 0; i < 20; i++) {
            OM_SapFunctionsStyle.RrwsSCell cell = new OM_SapFunctionsStyle.RrwsSCell();
            cell.Value = String.valueOf(1000 + i * 10);
            cellData.item.add(cell);
        }

        responseElement.AxisData = axisData;
        responseElement.CellData = cellData;
        response.put('response_x', responseElement);
    }
}