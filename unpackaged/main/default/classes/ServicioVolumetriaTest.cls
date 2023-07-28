@isTest
public class ServicioVolumetriaTest {
    private static Map<String, Integer> createSkus() {
        Map<String, Integer> skus = new Map<String, Integer>{
            'sku1' => 10,
                'sku2' => 20
                };
                    return skus;
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
                    res.setStatus('Bad Request');
                    res.setBody('{"error": "Failed to get volumetry."}');
                } else {
                    res.setStatusCode(200);
                    res.setBody('{' +
                                '"total_volume": 300,' +
                                '"skus": [{' +
                                '"sku": "sku1",' +
                                '"quantity": 10,' +
                                '"volume": 100,' +
                                '"weight": 50' +
                                '}, {' +
                                '"sku": "sku2",' +
                                '"quantity": 20,' +
                                '"volume": 200,' +
                                '"weight": 100' +
                                '}]' +
                                '}');
                }
            } else if (req.getEndpoint().contains(settings.AccessToken_Url__c)) {
                res.setStatusCode(200);
                res.setBody('{"access_token": "YOUR_ACCESS_TOKEN", "token_type": "Bearer", "expires_in": 3600}');
            } else {
                res.setStatusCode(404);
            }
            return res;
        }
    }
    
    @isTest
    static void testObtenerVolumetriaRespuestaFallida() {
        Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(true));
        
        Map<String, Integer> skus = createSkus();
        
        AutorizacionMuleSoft.CABECERA_DE_AUTORIZACION.put(ServicioVolumetria.AUTORIZACION_NOMBRE_CABECERA, 'Bearer YOUR_ACCESS_TOKEN');
        Exception expectedException;
        Test.startTest();
        try {
            ServicioVolumetria.RespuestaTraxionWrapper respuesta = ServicioVolumetria.obtenerVolumetria(skus);
        } catch (CalloutException e) {
            expectedException = e;
        }
        Test.stopTest();
         
        System.assertNotEquals(null, expectedException, 'Expected a CalloutException to be thrown');
    }
    
    @isTest
    static void testObtenerVolumetriaRespuestaExitosa() {
        Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(false));
        
        Map<String, Integer> skus = createSkus();
        
        Test.startTest();
        AutorizacionMuleSoft.CABECERA_DE_AUTORIZACION.put(ServicioVolumetria.AUTORIZACION_NOMBRE_CABECERA, 'Bearer YOUR_ACCESS_TOKEN');
        ServicioVolumetria.RespuestaTraxionWrapper respuesta = ServicioVolumetria.obtenerVolumetria(skus);
        Test.stopTest();
        
        System.assertNotEquals(null, respuesta, 'ResponseWrapper should not be null');
        System.assertEquals(300, respuesta.total_volume, 'Total volume should be 300');
        System.assertNotEquals(null, respuesta.skus, 'Skus list should not be null');
        System.assertEquals(2, respuesta.skus.size(), 'Skus list should have 2 items');
        
        ServicioVolumetria.SkuWrapper sku1 = respuesta.skus[0];
        System.assertEquals('sku1', sku1.sku, 'SKU should be "sku1"');
        System.assertEquals(10, sku1.quantity, 'Quantity should be 10');
        System.assertEquals(100, sku1.volume, 'Volume should be 100');
        System.assertEquals(50, sku1.weight, 'Weight should be 50');
        
        ServicioVolumetria.SkuWrapper sku2 = respuesta.skus[1];
        System.assertEquals('sku2', sku2.sku, 'SKU should be "sku2"');
        System.assertEquals(20, sku2.quantity, 'Quantity should be 20');
        System.assertEquals(200, sku2.volume, 'Volume should be 200');
        System.assertEquals(100, sku2.weight, 'Weight should be 100');
    }
}