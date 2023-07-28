@isTest
public class ServicioPaqueteoTest {
    private static List<String> createSkus() {
        List<String> skus = new List<String>{'sku1', 'sku2', 'sku3'};
        return skus;
    }

    @isTest
    static void testObtenerDisponibilidadRespuestaExitosa() {
        Test.setMock(HttpCalloutMock.class, new IntegrationHttpCalloutMock(false));

        List<String> skus = createSkus();

        Test.startTest();
        AutorizacionMuleSoft.CABECERA_DE_AUTORIZACION.put(ServicioPaqueteo.AUTORIZACION_NOMBRE_CABECERA, 'Bearer YOUR_ACCESS_TOKEN'); // Mock the token retrieval
        List<ServicioPaqueteo.SkuDisponibilidad> respuesta = ServicioPaqueteo.obtenerDisponibilidad(skus);
        Test.stopTest();

        System.assertNotEquals(null, respuesta, 'DisponibilidadRespuesta should not be null');
        System.assertEquals(1, respuesta.size(), 'respuesta size should be 1');

        ServicioPaqueteo.SkuDisponibilidad sku1 = respuesta[0];
        System.assertEquals('sku1', sku1.sku, 'sku should match the expected value');
        System.assertEquals(10, sku1.availability, 'availability should match the expected value');
        System.assertEquals('package1', sku1.package_key, 'package_key should match the expected value');
    }
    
    @isTest
    static void testObtenerDisponibilidadRespuestaFallida() {
        Test.setMock(HttpCalloutMock.class, new IntegrationHttpCalloutMock(true));

        List<String> skus = createSkus();

        Test.startTest();
        AutorizacionMuleSoft.CABECERA_DE_AUTORIZACION.put(ServicioPaqueteo.AUTORIZACION_NOMBRE_CABECERA, 'Bearer YOUR_ACCESS_TOKEN'); // Mock the token retrieval
        Exception expectedException;
        try {
            List<ServicioPaqueteo.SkuDisponibilidad> respuesta = ServicioPaqueteo.obtenerDisponibilidad(skus);
        } catch (CalloutException e) {
            expectedException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, expectedException, 'Expected a CalloutException to be thrown');
        System.assertEquals('Error getting availability: Status Code: 400, Status: null, Message: {"error": "Failed to get availability."}', expectedException.getMessage(), 'Exception message should match the expected value');
    }
}