@isTest
public class ServicioCertificacionEntregaTest {
    private static Map<String, String> crearDatos() {
        Map<String, String> datos = new Map<String, String>{
            'key1' => 'Id',
            'key2' => 'Id'
        };
        return datos;
    }

    public class TestHttpCalloutMock implements HttpCalloutMock {
        public Boolean respuestaFallida { get; set; }

        public TestHttpCalloutMock(Boolean respuestaFallida) {
            this.respuestaFallida = respuestaFallida;
        }
        
        MuleSoft_Integration_Settings__mdt settings =  [SELECT Api_Base_Url__c, AccessToken_Url__c 
                                                            FROM  MuleSoft_Integration_Settings__mdt
                                                            WHERE DeveloperName = 'Traxion'];

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains(settings.Api_Base_Url__c)) {
                if (respuestaFallida) {
                    res.setStatusCode(400);
                    res.setStatus('Bad Request');
                    res.setBody('{"error": "Error al tratar de obtener la certificacion."}');
                } else {
                    res.setStatusCode(200);
                    res.setBody('{' +
                        '"traxion_response": {' +
                        '"completed_succesfully": "true",' +
                        '"response": {' +
                        '"message": "La certificacion ha sido obtenida exitosamente.",' +
                        '"data": {}' +
                        '}' +
                        '}' +
                        '}');
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
    static void testObtenerCertificacionRespuestaFallida() {
        Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(true));

        Map<String, String> datos = crearDatos();

        Test.startTest();
        AutorizacionMuleSoft.CABECERA_DE_AUTORIZACION.put(ServicioCertificacionEntrega.AUTORIZACION_NOMBRE_CABECERA, 'Bearer TU_TOKEN_DE_ACCESO');
        Exception excepcionEsperada;
        try {
            ServicioCertificacionEntrega.RespuestaTraxionWrapper respuesta = ServicioCertificacionEntrega.obtenerCertificacion(datos);
        } catch (CalloutException e) {
            excepcionEsperada = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, excepcionEsperada, 'Se espera que una CalloutException sea lanzada');
        System.assertEquals('Error obteniendo certificación: Código de error: 400, Estado: Bad Request, Mensaje: {"error": "Error al tratar de obtener la certificacion."}', excepcionEsperada.getMessage(), 'El mensaje de excepción debe corresponder al valor lanzado.');
    }

    @isTest
    static void testObtenerCertificacionRespuestaExitosa() {
        Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(false));

        Map<String, String> datos = crearDatos();

        Test.startTest();
        AutorizacionMuleSoft.CABECERA_DE_AUTORIZACION.put(ServicioCertificacionEntrega.AUTORIZACION_NOMBRE_CABECERA, 'Bearer TU_TOKEN_DE_ACCESO');
        ServicioCertificacionEntrega.RespuestaTraxionWrapper respuesta = ServicioCertificacionEntrega.obtenerCertificacion(datos);
        Test.stopTest();

        System.assertNotEquals(null, respuesta, 'respuestaTraxion no debería ser null');
        System.assertEquals('true', respuesta.traxion_response.completed_succesfully, 'completed_succesfully debería ser "true"');
        System.assertNotEquals(null, respuesta.traxion_response.response, 'La respuesta no debe ser null');
        System.assertEquals('La certificacion ha sido obtenida exitosamente.', respuesta.traxion_response.response.message, 'El mensaje debe ser "La certificacion ha sido obtenida exitosamente."');
    }
}