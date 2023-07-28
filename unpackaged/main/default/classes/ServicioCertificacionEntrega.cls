/**
 * 
 * @description Esta clase se encarga de manejar el proceso de certificación de entrega con la API de Traxion Albatros.
 * Proporciona un método para obtener una certificación de entrega para un envío mediante una solicitud HTTP a la API.
 * La clase también incluye clases anidadas para mapear la respuesta JSON de la API a objetos Apex.
 */
public class ServicioCertificacionEntrega {
    private static final String METODO_POST = 'POST';
    private static final String TIPO_CONTENIDO_CABECERA = 'Content-Type';
    private static final String TIPO_CONTENIDO_CABECERA_JSON = 'application/json';
    private static final String API_BASE_URL;
	private static final String API_RUTA = '/api/shipments/delivery_certification?customer_name=ISSTE&system_request=salesforce';
    @testVisible
    private static final String AUTORIZACION_NOMBRE_CABECERA = 'Authorization';

    static {
        MuleSoft_Integration_Settings__mdt settings =  [SELECT Api_Base_Url__c 
                                                        FROM  MuleSoft_Integration_Settings__mdt 
                                                        WHERE DeveloperName = 'Traxion'];
        API_BASE_URL = settings.Api_Base_Url__c;
    }
        
    public static RespuestaTraxionWrapper obtenerCertificacion(Map<String,String> data) {

        System.debug(data);

        HttpRequest pedido = new HttpRequest();
        pedido.setTimeout(50000);
        pedido.setEndpoint(API_BASE_URL + API_RUTA);
        pedido.setMethod(METODO_POST);
        pedido.setHeader(TIPO_CONTENIDO_CABECERA, TIPO_CONTENIDO_CABECERA_JSON);
        pedido.setHeader(AUTORIZACION_NOMBRE_CABECERA, 'Bearer ' + AutorizacionMuleSoft.CABECERA_DE_AUTORIZACION.get(AUTORIZACION_NOMBRE_CABECERA));
        // OJO: We should be sending the RespuestaTraxion, but need to confirm with the service provider which format is better.
        pedido.setBody(JSON.serialize(data));
        HttpResponse respuesta = new Http().send(pedido);

        
        System.debug(JSON.serialize(data));
        System.debug(respuesta.getStatusCode());

        if (respuesta.getStatusCode() != 200) {
            throw new CalloutException('Error obteniendo certificación: ' +
                    'Código de error: ' + respuesta.getStatusCode() +
                    ', Estado: ' + respuesta.getStatus() +
                    ', Mensaje: ' + respuesta.getBody());
        }

        System.debug(respuesta.getBody());

		RespuestaTraxionWrapper respuestaTraxion = (RespuestaTraxionWrapper) JSON.deserialize(respuesta.getBody(), RespuestaTraxionWrapper.class);

        System.debug(respuestaTraxion);

        return respuestaTraxion;

    }

    public class RespuestaTraxionWrapper {
        public RespuestaTraxion traxion_response;
    }

    public class RespuestaTraxion {
        public String completed_succesfully;
        public ResponseData response; 
    }
    
    public class ResponseData {
        public String message;
        public DataInfo data;
    }
    
    public class DataInfo {
        public String base_64_pdf;
        public String order_number;
        public String document_id;
    }
}