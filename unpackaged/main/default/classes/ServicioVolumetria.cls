/**
 * Servicio para la volumetría
 */
public class ServicioVolumetria {
    private static final String METODO_POST = 'POST';
    private static final String TIPO_CONTENIDO_CABECERA = 'Content-Type';
    private static final String TIPO_CONTENIDO_CABECERA_JSON = 'application/json';
    private static final String API_BASE_URL;
	private static final String API_RUTA = '/api/shipments/volumetry?customer_name=ISSTE';
    @testVisible
    private static final String AUTORIZACION_NOMBRE_CABECERA = 'Authorization';

    static {
        MuleSoft_Integration_Settings__mdt settings =  [SELECT Api_Base_Url__c 
                                                        FROM  MuleSoft_Integration_Settings__mdt 
                                                        WHERE DeveloperName = 'Traxion'];
        API_BASE_URL = settings.Api_Base_Url__c;
    }
    
       public static RespuestaTraxionWrapper obtenerVolumetria(Map<String, Integer> skus) {
        HttpRequest pedido = new HttpRequest();
        pedido.setEndpoint(API_BASE_URL + API_RUTA);
        pedido.setMethod(METODO_POST);
        pedido.setHeader(TIPO_CONTENIDO_CABECERA, TIPO_CONTENIDO_CABECERA_JSON);
        pedido.setHeader(AUTORIZACION_NOMBRE_CABECERA, 'Bearer ' + AutorizacionMuleSoft.CABECERA_DE_AUTORIZACION.get(AUTORIZACION_NOMBRE_CABECERA));
        pedido.setBody(JSON.serialize(skus ));
        HttpResponse respuesta = new Http().send(pedido);
        if (respuesta.getStatusCode() != 200) {
            throw new CalloutException('Error obteniendo volumetria: ' +
                    'Código de error: ' + respuesta.getStatusCode() +
                    ', Estado: ' + respuesta.getStatus() +
                    ', Mensaje: ' + respuesta.getBody());
        }
		return (RespuestaTraxionWrapper) JSON.deserialize(respuesta.getBody(), RespuestaTraxionWrapper.class);

    }
    
    public class RespuestaTraxionWrapper {
        public Integer total_volume;
        public List<SkuWrapper> skus;
    }
    
    public class SkuWrapper {
        public String sku;
        public Integer quantity;
        public Integer volume;
        public Integer weight;
    }

}