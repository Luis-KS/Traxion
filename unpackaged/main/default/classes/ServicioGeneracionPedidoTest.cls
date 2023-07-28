@isTest
public class ServicioGeneracionPedidoTest {
    // Test data creation
    private static List<ServicioGeneracionPedido.Envio> createEnvios() {
        List<ServicioGeneracionPedido.Envio> envios = new List<ServicioGeneracionPedido.Envio>();

        // Create a test Envio object
        ServicioGeneracionPedido.Envio envio = new ServicioGeneracionPedido.Envio();
        envio.client_id = '123';
        envio.external_id = 'ext-001';
        envio.document_number = 'doc-001';
        envio.early_delivery_date = '2023-01-01';
        envio.early_ship_date = '2022-12-31';
        envio.late_delivery_date = '2023-01-10';
        envio.late_ship_date = '2023-01-05';
        envio.remision = 'rem-001';
        envio.shipment_number = 'ship-001';
        envio.entered_date = '2022-12-30';
        envio.ship_address = '123 Main St';
        envio.customer_date = '2023-01-02';
        envio.order_type = 'Regular';
        envio.change_carrier = 'Yes';
        envio.release_remaining = 'No';
        envio.customer_number = 'CUST-001';
        envio.bto_rush = 'No';

        // Create a test Item object
        ServicioGeneracionPedido.Item item = new ServicioGeneracionPedido.Item();
        item.order_line = '1';
        item.order_sub = 'A';
        item.entered_date = '2022-12-30';
        item.product_number = 'PROD-001';
        item.ordered_quantity = '10';
        item.process_priority = 'High';
        item.partial_flag = 'No';
        item.back_order = 'No';
        item.cross_dock = 'Yes';
        item.quantity_ordered = '10';
        item.split_case = 'No';
        item.order_inventory = 'Yes';
        item.assignment_profile = 'Profile-001';
        item.freshness_date_flag = 'Yes';
        item.unit_price = '100.00';
        item.plan_number = 'PLAN-001';
        item.currency_name = 'USD';

        envio.items = new List<ServicioGeneracionPedido.Item>{ item };
        envios.add(envio);

        return envios;
    }

    public class TestHttpCalloutMock implements HttpCalloutMock {
        public Boolean failResponse { get; set; }

        public TestHttpCalloutMock(Boolean failResponse) {
            this.failResponse = failResponse;
        }
        
        MuleSoft_Integration_Settings__mdt settings =  [SELECT Api_Base_Url__c, AccessToken_Url__c 
                                                            FROM  MuleSoft_Integration_Settings__mdt
                                                            WHERE DeveloperName = 'Traxion'];

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains(settings.Api_Base_Url__c)) {
                if (failResponse) {
                    res.setStatusCode(400);
                    res.setBody('{"error": "Error al crear la orden."}');
                } else {
                    res.setStatusCode(200);
                    res.setBody('{"traxion_response": {"completed_succesfully": "true", "response": {"message": "Pedido creado exitosamente.", "data": {}}}}');
                }
            } else if (req.getEndpoint().contains(settings.AccessToken_Url__c)) {
                res.setStatusCode(200);
                res.setBody('{"access_token": "TU_TOKEN_DE_ACCESO", "token_type": "Bearer", "expires_in": 3600}');
            } else {
                res.setStatusCode(404);
            }
            return res;
        }
    }

    @isTest
    static void testCrearPedidoRespuestaFallida() {
        Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(true));

        List<ServicioGeneracionPedido.Envio> envios = createEnvios();

        Test.startTest();
        AutorizacionMuleSoft.CABECERA_DE_AUTORIZACION.put(ServicioGeneracionPedido.AUTORIZACION_NOMBRE_CABECERA, 'Bearer TU_TOKEN_DE_ACCESO');
        Exception excepcionEsperada;
        try {
            ServicioGeneracionPedido.RespuestaTraxionWrapper respuesta = ServicioGeneracionPedido.crearPedido(envios);
        } catch (CalloutException e) {
            excepcionEsperada = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, excepcionEsperada, 'Expected a CalloutException to be thrown');
        System.assertEquals('Error al crear pedido. Código de estado: 400, Mensaje: {"error": "Error al crear la orden."}', excepcionEsperada.getMessage(), 'El mensaje de excepción debe corresponder al valor lanzado.');
    }


    @isTest
    static void testCrearPedidoRespuestaExitosa() {
        String mensajeEsperado = 'Pedido creado exitosamente.';
        Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(false));

        List<ServicioGeneracionPedido.Envio> envios = createEnvios();

        Test.startTest();
        AutorizacionMuleSoft.CABECERA_DE_AUTORIZACION.put(ServicioGeneracionPedido.AUTORIZACION_NOMBRE_CABECERA, 'Bearer TU_TOKEN_DE_ACCESO'); // Mock the token retrieval
        ServicioGeneracionPedido.RespuestaTraxionWrapper respuesta = ServicioGeneracionPedido.crearPedido(envios);
        Test.stopTest();

        System.assertNotEquals(null, respuesta, 'RespuestaTraxionWrapper no debe ser null.');
        System.assertNotEquals(null, respuesta.traxion_response, 'RespuestaTraxion no debe ser null.');
        System.assertEquals('true', respuesta.traxion_response.completed_succesfully, 'completed_succesfully debe ser true');
        System.assertNotEquals(null, respuesta.traxion_response.response, 'Respuesta no puede ser null');
        System.assertEquals(mensajeEsperado, respuesta.traxion_response.response.message, 'El mensaje debe ser ' + mensajeEsperado);
    }
}