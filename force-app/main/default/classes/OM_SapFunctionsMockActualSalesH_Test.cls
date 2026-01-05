@isTest
global class OM_SapFunctionsMockActualSalesH_Test implements WebServiceMock {
    global void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
        
        OM_SapFunctionsStyle.GetQueryViewDataResponse_element resp = new OM_SapFunctionsStyle.GetQueryViewDataResponse_element();
        resp.AxisData = new OM_SapFunctionsStyle.RrwsThxAxisData();
        resp.AxisData.item = new List<OM_SapFunctionsStyle.RrwsSxAxisData>();

        OM_SapFunctionsStyle.RrwsSxAxisData axis001 = new OM_SapFunctionsStyle.RrwsSxAxisData();
        axis001.Axis = '001';
        axis001.Set_x = new OM_SapFunctionsStyle.RrwsTxSet();
        axis001.Set_x.item = new List<OM_SapFunctionsStyle.RrwsSxTuple>();

        // Datos mínimos para que los IFs de la clase se activen
        axis001.Set_x.item.add(createT('0', '0CALMONTH', '202511', ''));
        axis001.Set_x.item.add(createT('0', '0SOLD_TO', '12516', '12516'));
        axis001.Set_x.item.add(createT('0', '0MATERIAL__ZISDMODEL', '221004B', '221004B'));
        axis001.Set_x.item.add(createT('0', '0MATERIAL', '18403', '18403')); 

        resp.AxisData.item.add(axis001);

        resp.CellData = new OM_SapFunctionsStyle.RrwsTCell();
        resp.CellData.item = new List<OM_SapFunctionsStyle.RrwsSCell>();
        for (Integer i = 0; i < 20; i++) {
            OM_SapFunctionsStyle.RrwsSCell cell = new OM_SapFunctionsStyle.RrwsSCell();
            cell.Value = '10.0';
            resp.CellData.item.add(cell);
        }

        response.put('response_x', resp);
    }

    private OM_SapFunctionsStyle.RrwsSxTuple createT(String ord, String chanm, String chavl, String chavlExt) {
        OM_SapFunctionsStyle.RrwsSxTuple t = new OM_SapFunctionsStyle.RrwsSxTuple();
        t.TupleOrdinal = ord; t.Chanm = chanm; t.Chavl = chavl; t.ChavlExt = chavlExt;
        return t;
    }
}