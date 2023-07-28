@isTest
private class ServicioSalidaAlmacenTest {
    
    @testSetup 
    static void setup() {
        Account umuTest = TestDataFactory.createSingleAccount('Hospital UMU');
        System.debug(umuTest);
        
        Contact contactTest = TestDataFactory.createSingleContactRelatedToAccount(umuTest.Id,'contact Test FirstName', 'contact Test LastName', 'Todas');
        System.debug(contactTest);
        
        Product2 claveTest = TestDataFactory.createSingleProduct('Aspirina', 'MEDICINE');
        System.debug(claveTest);
        claveTest.Product_Code_ID__c = '12345asdas';
        update claveTest;
            
        Order__c orderTest = new Order__c();
        orderTest.Tipo_de_Pedido__c = 'Ordinario';
        orderTest.order_number__c = '500-1111';
		orderTest.UMU__c = umuTest.Id;
       	orderTest.Contacto__c = contactTest.Id;
        orderTest.Estatus__c = 'Preparando Envío';
        System.debug(orderTest);
        
        
        
		insert orderTest;
        
        Order_Line_Item__c orderLineItemTest = new Order_Line_Item__c();
        orderLineItemTest.Product__c = claveTest.Id;
		orderLineItemTest.Cantidad_Solicitada__c = 10;
        orderLineItemTest.Cantidad_de_Piezas__c = 10;
		orderLineItemTest.Order__c = orderTest.Id;
		orderLineItemTest.UMU__c = umuTest.Id;
        
        insert orderLineItemTest;
        
    }
    
    @isTest
    static void testCreateRecord() {
        Test.startTest();
        IntegrationHttpCalloutMock httpMock = new IntegrationHttpCalloutMock(false);
        Test.setMock(HttpCalloutMock.class, httpMock);

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/SalidaAlmacen';
        req.httpMethod = 'POST';
        
        List<ServicioSalidaAlmacen.Order> orders = new List<ServicioSalidaAlmacen.Order>();
        
        ServicioSalidaAlmacen.Order order = new ServicioSalidaAlmacen.Order();
        order.order_number = '500-1111';
        order.load = '500-1111';
        order.box_quantity = 10;
        order.skus = new List<ServicioSalidaAlmacen.SkuInfo>();
        
        ServicioSalidaAlmacen.SkuInfo sku = new ServicioSalidaAlmacen.SkuInfo();
        sku.sku = '12345asdas';
        sku.quantity = 5;
        sku.avg_cost = 10.0;
        sku.lote_info = new List<ServicioSalidaAlmacen.LoteInfo>();
        
        ServicioSalidaAlmacen.LoteInfo lote = new ServicioSalidaAlmacen.LoteInfo();
        lote.quantity = 2;
        lote.expiration_date = '05/01/2023';
        lote.lot_number = '5DSA4';
        
        sku.lote_info.add(lote);
        order.skus.add(sku);
        orders.add(order);
        
        String requestBodyJson = JSON.serialize(orders);
        req.requestBody = Blob.valueOf(requestBodyJson);
        
        RestResponse res = new RestResponse();
        
        RestContext.request = req;
        RestContext.response = res;
        try {
            ServicioSalidaAlmacen.createRecord();
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
        }
        
        Test.stopTest();
        
        System.assertEquals(200, res.statusCode);
        
        ServicioSalidaAlmacen.RespuestaTraxion traxionResponse = (ServicioSalidaAlmacen.RespuestaTraxion) JSON.deserialize(res.responseBody.toString(), ServicioSalidaAlmacen.RespuestaTraxion.class);
        
        System.assertEquals(true, traxionResponse.completedSuccessfully);
        System.assertEquals('successful', traxionResponse.response.message);


    }

}