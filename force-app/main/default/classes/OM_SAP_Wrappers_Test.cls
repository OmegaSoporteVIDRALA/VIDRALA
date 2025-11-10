@IsTest
private class OM_SAP_Wrappers_Test {

    @IsTest
    static void testCustomerWrapperSerialization() {
        
        OM_SAP_Wrappers.Address address = new OM_SAP_Wrappers.Address();
        address.street = 'Calle Falsa 123';
        address.postalCode = '28080';
        address.city = 'Madrid';
        address.state = 'Madrid';
        address.country = 'ES';
        address.coordX = 40.4168;
        address.coordY = -3.7038;
        
        OM_SAP_Wrappers.CreditSegment credit = new OM_SAP_Wrappers.CreditSegment();
        credit.territoryCode = 'ES01';
        credit.creditLimit = 10000.0;
        credit.creditStatus = 'ACTIVE';
        credit.creditBlock = false;
        
        OM_SAP_Wrappers.Financials fin = new OM_SAP_Wrappers.Financials();
        fin.currencyCode = 'EUR';
        fin.agreedTerms = '30D';
        fin.paymentMethod = 'Transfer';
        
        OM_SAP_Wrappers.CustomerTeam team = new OM_SAP_Wrappers.CustomerTeam();
        team.salesAdmin = 'User1';
        team.customerManager = 'User2';
        team.customerService = 'User3';
        team.salesOffice = 'MAD';
        
        OM_SAP_Wrappers.SalesOrganization salesOrg = new OM_SAP_Wrappers.SalesOrganization();
        salesOrg.organizationCode = 'ES01';
        salesOrg.market = 'Spain';
        salesOrg.claseABC = 'A';
        salesOrg.financials = fin;
        salesOrg.creditBlock = false;
        salesOrg.customerTeam = team;
        
        OM_SAP_Wrappers.CustomerWrapper customer = new OM_SAP_Wrappers.CustomerWrapper();
        customer.customerCode = 'C0001';
        customer.customerName = 'Farmacia Central';
        customer.parentCustomer = 'Grupo Farma';
        customer.blocked = 'false';
        customer.address = address;
        customer.vatNumber = 'ESB12345678';
        customer.nif = '12345678Z';
        customer.phone = '911234567';
        customer.industry = 'Pharma';
        customer.customerClass = 'Premium';
        customer.recordType = 'Pharmacy';
        customer.creditSegment = new List<OM_SAP_Wrappers.CreditSegment>{ credit };
        customer.salesOrganizations = new List<OM_SAP_Wrappers.SalesOrganization>{ salesOrg };
        
        String jsonCustomer = JSON.serialize(customer);
        System.assertNotEquals(null, jsonCustomer, 'Debe generar un JSON válido');

        OM_SAP_Wrappers.CustomerWrapper deserialized =
        (OM_SAP_Wrappers.CustomerWrapper) JSON.deserialize(jsonCustomer, OM_SAP_Wrappers.CustomerWrapper.class);
        
        System.assertEquals('C0001', deserialized.customerCode);
        System.assertEquals('Farmacia Central', deserialized.customerName);
        System.assertEquals('Spain', deserialized.salesOrganizations[0].market);
        System.assertEquals('ES01', deserialized.creditSegment[0].territoryCode);
    }
    
    
    @IsTest
    static void testCustomerOrderWrapper() {
        OM_SAP_Wrappers.CustomerPriceWrapper price = new OM_SAP_Wrappers.CustomerPriceWrapper();
        price.priceCode = 'P001';
        price.price = 12.5;
        price.customerCode = 'C0001';
        price.incoterms = 'DAP';
        price.plant = 'PL01';
        price.currencyCode = 'EUR';
        price.productCode = 'PROD001';
        price.installDate = '2025-01-10';
        price.usageEndDate = '2025-12-31';
        price.salesOrganization = 'ES01';
        price.materialCode = 'MAT001';
        
        OM_SAP_Wrappers.CustomerOrderWrapper orderWrapper = new OM_SAP_Wrappers.CustomerOrderWrapper();
        orderWrapper.order = new List<OM_SAP_Wrappers.CustomerPriceWrapper>{ price };
        
        String jsonOrder = JSON.serialize(orderWrapper);
        System.assert(jsonOrder.contains('C0001'), 'El JSON debe contener el código del cliente');
        
        OM_SAP_Wrappers.CustomerOrderWrapper back =
            (OM_SAP_Wrappers.CustomerOrderWrapper) JSON.deserialize(jsonOrder, OM_SAP_Wrappers.CustomerOrderWrapper.class);
        System.assertEquals('PROD001', back.order[0].productCode);
    }
}