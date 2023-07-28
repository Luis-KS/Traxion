public class AutorizacionMuleSoft {
	private static final String AUTH_CLIENT_CREDENTIALS = 'CLIENT_CREDENTIALS';
    private static final String AUTH_SCOPE;
    private static final String AUTH_TOKEN_URL;
    private static final String API_BASE_URL;
    private static final String AUTH_CLIENT_ID;
    private static final String AUTH_CLIENT_SECRET;
    private static final String AUTH_TOKEN_REQUEST_BODY;
	private static final String METODO_POST = 'POST';
    private static final String TIPO_CONTENIDO_CABECERA = 'Content-Type';
    private static final String TIPO_CONTENIDO_CABECERA_FORM = 'application/x-www-form-urlencoded';

    public static final Map<String, String> CABECERA_DE_AUTORIZACION {
        public get {
            if (CABECERA_DE_AUTORIZACION == null) {
                CABECERA_DE_AUTORIZACION = new Map<String, String>{
                        'Authorization' => 'Bearer ' + obtenerTokenDeAcceso()
                };
            }
            return CABECERA_DE_AUTORIZACION;
        }
        private set;
    }

    static {
		MuleSoft_Integration_Settings__mdt settings =  [SELECT Api_Base_Url__c,AccessToken_Url__c, ClientId__c, ClientSecret__c, Scope__c 
                                                        FROM  MuleSoft_Integration_Settings__mdt 
                                                        WHERE DeveloperName = 'Traxion'];
        AUTH_TOKEN_URL = settings.AccessToken_Url__c;
        API_BASE_URL = settings.Api_Base_Url__c;
        AUTH_CLIENT_ID = settings.ClientId__c;
        AUTH_CLIENT_SECRET = settings.ClientSecret__c;
        AUTH_SCOPE = settings.Scope__c;
        AUTH_TOKEN_REQUEST_BODY = String.format('grant_type={0}&client_id={1}&client_secret={2}&scope={3}&audience={4}',
                new String[]{
                        AUTH_CLIENT_CREDENTIALS, AUTH_CLIENT_ID, AUTH_CLIENT_SECRET, AUTH_SCOPE, API_BASE_URL
                });
    }

    @TestVisible
    private static String obtenerTokenDeAcceso() {
        HttpRequest pedido = new HttpRequest();
        pedido.setEndpoint(AUTH_TOKEN_URL);
        pedido.setMethod(METODO_POST);
        pedido.setHeader(TIPO_CONTENIDO_CABECERA, TIPO_CONTENIDO_CABECERA_FORM);
        pedido.setBody(AUTH_TOKEN_REQUEST_BODY);

        HttpResponse respuesta = new Http().send(pedido);
        if (respuesta.getStatusCode() != 200) {
            throw new CalloutException('Error getting access token. ' +
                    'Status Code: ' + respuesta.getStatusCode() +
                    ', Status: ' + respuesta.getStatus() +
                    ', Message: ' + respuesta.getBody());
        }

        RespuestaPedidoToken respuestaPedidoToken =
                (RespuestaPedidoToken) JSON.deserialize(respuesta.getBody(), RespuestaPedidoToken.class);

        if (null == respuestaPedidoToken?.access_token) {
            throw new CalloutException('Error getting authorization token for Mulesoft - missing token.');
        }

        return respuestaPedidoToken.access_token;
    }

    private class RespuestaPedidoToken {
        public String tokenType;
        public Integer expiresIn;
        public String access_token;
        public String scope;
    }
}