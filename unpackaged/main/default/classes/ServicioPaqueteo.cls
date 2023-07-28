/**
 * 
 * @description La clase ServicioPaqueteo es responsable de realizar llamadas a la API externa
 * Traxion Albatros para obtener la disponibilidad y las opciones de paqueteo de productos en Salesforce.
 * La clase consulta la API y devuelve la respuesta en un objeto de tipo RespuestaDisponibilidadWrapper.
 * 
 * La clase contiene clases anidadas para representar el esquema de la solicitud y la respuesta de la API,
 * así como métodos para manejar la consulta de disponibilidad y paqueteo de productos.
 * 
 */

public class ServicioPaqueteo {
    private static final String METODO_POST = 'POST';
    private static final Integer REQUEST_TIME_OUT = 120000;
    private static final String TIPO_CONTENIDO_CABECERA = 'Content-Type';
    private static final String TIPO_CONTENIDO_CABECERA_JSON = 'application/json';
    private static final String API_BASE_URL;
    private static final String API_RUTA = '/api/shipments/availability?system_request=salesforce&customer_name=ISSTE';
    @testVisible
    private static final String AUTORIZACION_NOMBRE_CABECERA = 'Authorization';
    
     static {
        MuleSoft_Integration_Settings__mdt settings =  [SELECT Api_Base_Url__c 
                                                        FROM  MuleSoft_Integration_Settings__mdt 
                                                        WHERE DeveloperName = 'Traxion'];
        API_BASE_URL = settings.Api_Base_Url__c;
    }
	
    @AuraEnabled
    public static List<SkuDisponibilidad> obtenerDisponibilidad(List<String> skus) {
        HttpRequest pedido = new HttpRequest();
        pedido.setEndpoint(API_BASE_URL + API_RUTA);
        pedido.setMethod(METODO_POST);
        pedido.setTimeout(REQUEST_TIME_OUT);
        pedido.setHeader(TIPO_CONTENIDO_CABECERA, TIPO_CONTENIDO_CABECERA_JSON);
        pedido.setHeader(AUTORIZACION_NOMBRE_CABECERA, 'Bearer ' + AutorizacionMuleSoft.CABECERA_DE_AUTORIZACION.get(AUTORIZACION_NOMBRE_CABECERA));
        pedido.setBody(JSON.serialize(new Map<String, List<String>>{ 'skus' => skus }));

        HttpResponse respuesta = new Http().send(pedido);

        if (respuesta.getStatusCode() != 200) {
            throw new CalloutException('Error getting availability: ' +
                    'Status Code: ' + respuesta.getStatusCode() +
                    ', Status: ' + respuesta.getStatus() +
                    ', Message: ' + respuesta.getBody());
        }
        
        List<SkuDisponibilidad> skusDisponibles;
    
    	try {
        	skusDisponibles = (List<SkuDisponibilidad>) JSON.deserialize(respuesta.getBody(), List<SkuDisponibilidad>.class);
    	} catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        	throw new JsonDeserializationException('Error during JSON deserialization: ' + e.getMessage());
    	}
    
    	return skusDisponibles;
        
    }
    
    public class SkuDisponibilidad {
        public String sku;
        public Integer availability;
        public String package_key;
        public List<Packages_details> packages_details;
    }
    
    public class Packages_details  {
        public Integer quantity_pieces_package {get;set;}
        public Integer availability {get;set;}
    }

    public class DisponibilidadRespuesta  {
        public List<SkuDisponibilidad> skus {get;set;}
    }
    
    public class JsonDeserializationException extends Exception {}
}