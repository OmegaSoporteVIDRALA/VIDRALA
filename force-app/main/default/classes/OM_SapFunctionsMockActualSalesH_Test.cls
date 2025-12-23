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
        // Crear dummy response
        OM_SapFunctionsStyle.GetQueryViewDataResponse_element responseElement = 
            new OM_SapFunctionsStyle.GetQueryViewDataResponse_element();

        // Crear AxisData
        OM_SapFunctionsStyle.RrwsThxAxisData axisData = new OM_SapFunctionsStyle.RrwsThxAxisData();
        axisData.item = new List<OM_SapFunctionsStyle.RrwsSxAxisData>();

        // Simulamos una dimensión con varios registros
        OM_SapFunctionsStyle.RrwsSxAxisData axisItem = new OM_SapFunctionsStyle.RrwsSxAxisData();
        axisItem.Axis = '001'; // Nuestro Axis relevante
        axisItem.Set_x = new OM_SapFunctionsStyle.RrwsTxSet();
        axisItem.Set_x.item = new List<OM_SapFunctionsStyle.RrwsSxTuple>();

        // Simulamos 2 registros
        for (Integer j = 0; j < 2; j++) {
            // Año-Mes
            OM_SapFunctionsStyle.RrwsSxTuple tupleCalMonth = new OM_SapFunctionsStyle.RrwsSxTuple();
            tupleCalMonth.TupleOrdinal = String.valueOf(j);
            tupleCalMonth.Chanm = '0CALMONTH';
            tupleCalMonth.Chavl = '20240' + (j + 1); // 202401, 202402
            axisItem.Set_x.item.add(tupleCalMonth);

            // Cliente
            OM_SapFunctionsStyle.RrwsSxTuple tupleAccount = new OM_SapFunctionsStyle.RrwsSxTuple();
            tupleAccount.TupleOrdinal = String.valueOf(j);
            tupleAccount.Chanm = '0SOLD_TO';
            tupleAccount.ChavlExt = 'ACCT00' + (j+1); // ACCT001, ACCT002
            axisItem.Set_x.item.add(tupleAccount);

            // Material
            OM_SapFunctionsStyle.RrwsSxTuple tupleMaterial = new OM_SapFunctionsStyle.RrwsSxTuple();
            tupleMaterial.TupleOrdinal = String.valueOf(j);
            tupleMaterial.Chanm = '0MATERIAL';
            tupleMaterial.Chavl = 'MAT00' + (j+1);
            tupleMaterial.ChavlExt = 'MAT00' + (j+1);
            axisItem.Set_x.item.add(tupleMaterial);

            // Modelo
            OM_SapFunctionsStyle.RrwsSxTuple tupleModel = new OM_SapFunctionsStyle.RrwsSxTuple();
            tupleModel.TupleOrdinal = String.valueOf(j);
            tupleModel.Chanm = '0MATERIAL__ZISDMODEL';
            tupleModel.ChavlExt = 'MOD00' + (j+1);
            axisItem.Set_x.item.add(tupleModel);

            // Organización de ventas
            OM_SapFunctionsStyle.RrwsSxTuple tupleSalesOrg = new OM_SapFunctionsStyle.RrwsSxTuple();
            tupleSalesOrg.TupleOrdinal = String.valueOf(j);
            tupleSalesOrg.Chanm = '0SALESORG';
            tupleSalesOrg.ChavlExt = 'SO01';
            axisItem.Set_x.item.add(tupleSalesOrg);
        }

        axisData.item.add(axisItem);

       
        OM_SapFunctionsStyle.RrwsTCell cellData = new OM_SapFunctionsStyle.RrwsTCell();
        cellData.item = new List<OM_SapFunctionsStyle.RrwsSCell>();
        // Para cada registro, agregamos 20 celdas de ejemplo
        for (Integer i = 0; i < 40; i++) {
            OM_SapFunctionsStyle.RrwsSCell cell = new OM_SapFunctionsStyle.RrwsSCell();
            cell.Value = String.valueOf(1000 + i * 10); // Valores incrementales
            cellData.item.add(cell);
        }

        // Asignar datos al response
        responseElement.AxisData = axisData;
        responseElement.CellData = cellData;

        // Insertar en el mapa de respuesta
        response.put('response_x', responseElement);
    }
}
