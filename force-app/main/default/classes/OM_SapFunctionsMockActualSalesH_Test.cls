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
        // Simula respuesta
        OM_SapFunctionsStyle.GetQueryViewDataResponse_element responseElement = 
            new OM_SapFunctionsStyle.GetQueryViewDataResponse_element();

        // Crear dummy AxisData
        OM_SapFunctionsStyle.RrwsThxAxisData axisData = new OM_SapFunctionsStyle.RrwsThxAxisData();
        axisData.item = new List<OM_SapFunctionsStyle.RrwsSxAxisData>();

         // Simulamos dos dimensiones
        for (Integer i = 0; i < 2; i++) {
            OM_SapFunctionsStyle.RrwsSxAxisData axisItem = new OM_SapFunctionsStyle.RrwsSxAxisData();
            axisItem.Axis = '00' + i;
            //axisItem.Member = new List<OM_SapFunctionsStyle.RrwsSxKeyFigure>();
			axisItem.Set_x = new OM_SapFunctionsStyle.RrwsTxSet();
            axisItem.Set_x.item = new List<OM_SapFunctionsStyle.RrwsSxTuple>();
            for (Integer j = 0; j < 3; j++) {
                OM_SapFunctionsStyle.RrwsSxTuple member = new OM_SapFunctionsStyle.RrwsSxTuple();
                member.TupleOrdinal = String.valueOf(j);
                
                member.Chanm = '0MATERIAL';
                member.Chavl = '12344';
                member.ChavlExt = '12344';
                
                //member.Tuples = 'Tuple_' + i + '_' + j;
                axisItem.Set_x.item.add(member);
            }

            axisData.item.add(axisItem);
        }

        // -----------------------
        // FILL CELL DATA (MEASURES)
        // -----------------------
        OM_SapFunctionsStyle.RrwsTCell cellData = new OM_SapFunctionsStyle.RrwsTCell();
        cellData.item = new List<OM_SapFunctionsStyle.RrwsSCell>();

        for (Integer i = 0; i < 20; i++) {
            OM_SapFunctionsStyle.RrwsSCell cell = new OM_SapFunctionsStyle.RrwsSCell();
            cell.Value = String.valueOf(i * 100);
            //cell.ColumnIndex = i;
            //cell.RowIndex = 0;
            cellData.item.add(cell);
        }
        // Asignar datos ficticios
        responseElement.AxisData = axisData;
        responseElement.CellData = cellData;

        // Insertar en el mapa de respuesta
        response.put('response_x', responseElement);
    }
}