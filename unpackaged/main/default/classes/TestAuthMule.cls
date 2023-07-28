/**
 * MuleSoftAuthorization Class
 * Esta clase es responsable de gestionar la autorización de las solicitudes a la API de MuleSoft.
 */
public class TestAuthMule {
    private static final String AUTH_CLIENT_CREDENTIALS = 'CLIENT_CREDENTIALS';
    private static final String AUTH_SCOPE = 'SHIPMENT_WRITE';
    private static final String AUTH_TOKEN_URL = 'https://system-oauth-provider-test.us-w2.cloudhub.io/auth/token';
    private static final String API_BASE_URL = 'https://traxion-albatros-api-test.us-w2.cloudhub.io/';
    private static final String AUTH_CLIENT_ID = 'CRM-TEST-6E2mGd7ZQLzVYY5ZUZrgCekp7uHUKhqHiBnPEBEkDU32kBcrOL';
    private static final String AUTH_CLIENT_SECRET = '2wiAkF8KuJoMut9bxlnUwQ6hFEjaTtkDAcWL4D5jL09rZoCl6g';
    private static final String METHOD_POST = 'POST';
    private static final String HEADER_CONTENT_TYPE = 'Content-Type';
    private static final String HEADER_VALUE_FORM = 'application/x-www-form-urlencoded';
    private static final String AUTH_TOKEN_REQUEST_BODY = String.format('grant_type={0}&client_id={1}&client_secret={2}&scope={3}&audience={4}',
            new String[]{
                    AUTH_CLIENT_CREDENTIALS, AUTH_CLIENT_ID, AUTH_CLIENT_SECRET, AUTH_SCOPE, API_BASE_URL
            });

    /**
     * AUTHORIZATION_HEADER es un mapa que contiene el encabezado de autorización con el token de acceso.
     */
    public static final Map<String, String> AUTHORIZATION_HEADER {
        public get {
            if (AUTHORIZATION_HEADER == null) {
                AUTHORIZATION_HEADER = new Map<String, String>{
                        'Authorization' => 'Bearer ' + getAccessToken()
                };
            }
            return AUTHORIZATION_HEADER;
        }
        private set;
    }

    /**
     * Método para obtener el token de acceso de la API de MuleSoft.
     * @return String con el token de acceso.
     * @throws CalloutException en caso de error al obtener el token de acceso.
     */
    @TestVisible
    public static String getAccessToken() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(AUTH_TOKEN_URL);
        request.setMethod(METHOD_POST);
        request.setHeader(HEADER_CONTENT_TYPE, HEADER_VALUE_FORM);
        request.setBody(AUTH_TOKEN_REQUEST_BODY);

        HttpResponse response = new Http().send(request);
        if (response.getStatusCode() != 200) {
            throw new CalloutException('Error getting access token. ' +
                    'Status Code: ' + response.getStatusCode() +
                    ', Status: ' + response.getStatus() +
                    ', Message: ' + response.getBody());
        }

        TokenRequestResponse tokenRequestResponse =
                (TokenRequestResponse) JSON.deserialize(response.getBody(), TokenRequestResponse.class);

        if (null == tokenRequestResponse?.access_token) {
            throw new CalloutException('Error getting authorization token for Mulesoft - missing token.');
        }
		system.debug(tokenRequestResponse.access_token);
        return tokenRequestResponse.access_token;
    }

    /**
     * Clase interna para almacenar la respuesta de la solicitud del token de acceso.
     */
    private class TokenRequestResponse {
        public String tokenType;
        public Integer expiresIn;
        public String access_token;
        public String scope;
    }
}