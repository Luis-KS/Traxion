@isTest
private class ServicioAsignacionInventarioTest {
    
     @testSetup 
     static void setup() {
        // create UMU
        Account umuTest = TestDataFactory.createSingleAccount('Hospital UMU');
        System.debug(umuTest);
        
        Contact contactTest = TestDataFactory.createSingleContactRelatedToAccount(umuTest.Id,'contact Test FirstName', 'contact Test LastName', 'Todas');
        System.debug(contactTest);
        
        Product2 claveTest = TestDataFactory.createSingleProduct('Aspirina', 'MEDICINE');
        System.debug(claveTest);
        claveTest.Product_Code_ID__c = '12345asdas';
        update claveTest;
         
                  Date fecha = System.today();
         
         Pedido__c pedidoTest = new Pedido__c(
             UMU__c = umuTest.Id,
             Creado_Por__c = contactTest.Id,
             Es_Programa__c = false,
             Tipo_de_Pedido__c = 'Ordinario',
             Fecha_Limite_de_Entrega__c = fecha.addDays(2)
         );
         
         insert PedidoTest;
         
         Order__c orderTest = new Order__c();
         orderTest.Tipo_de_Pedido__c = 'Ordinario';
         orderTest.order_number__c = '500-1111';
         orderTest.UMU__c = umuTest.Id;
         orderTest.Contacto__c = contactTest.Id;
         orderTest.Estatus__c = 'Verificando Disponibilidad';
         orderTest.Pedido__c = pedidoTest.Id;
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
    static void testCreateRecordNegative() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/AsignacionInventario';
        req.httpMethod = 'POST';

        ServicioAsignacionInventario.RequestBody requestBody = new ServicioAsignacionInventario.RequestBody();
        requestBody.order_number = '500-1111';
        requestBody.skus = new List<ServicioAsignacionInventario.SkuInfo>();

        ServicioAsignacionInventario.SkuInfo sku = new ServicioAsignacionInventario.SkuInfo();
        sku.sku = '12345asdas';
        sku.quantity = 5;

        requestBody.skus.add(sku);

        String requestBodyJson = JSON.serialize(requestBody);
        req.requestBody = Blob.valueOf(requestBodyJson);

        RestResponse res = new RestResponse();

        Test.startTest();
        RestContext.request = req;
        RestContext.response = res;
        
        ServicioAsignacionInventario.throwEx = true;

        try {
            ServicioAsignacionInventario.createRecord();
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
        }

        Test.stopTest();

        System.assertEquals(500, res.statusCode);
        System.assertEquals('Error: Error during testing.', res.responseBody.toString());
    }
    
     @isTest
    static void testCreateRecordPositive() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/AsignacionInventario';
        req.httpMethod = 'POST';

        ServicioAsignacionInventario.RequestBody requestBody = new ServicioAsignacionInventario.RequestBody();
        requestBody.order_number = '500-1111';
        requestBody.skus = new List<ServicioAsignacionInventario.SkuInfo>();

        ServicioAsignacionInventario.SkuInfo sku = new ServicioAsignacionInventario.SkuInfo();
        sku.sku = '12345asdas';
        sku.quantity = 5;

        requestBody.skus.add(sku);

        String requestBodyJson = JSON.serialize(requestBody);
        req.requestBody = Blob.valueOf(requestBodyJson);

        RestResponse res = new RestResponse();

        Test.startTest();
        RestContext.request = req;
        RestContext.response = res;


        try {
            ServicioAsignacionInventario.createRecord();
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
        }

        Test.stopTest();

        System.assertEquals(200, res.statusCode);

    }
}