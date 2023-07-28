@isTest
public class TestAuthMuleTest {
  // Mock class to simulate the response from the API
    public class TestHttpCalloutMock implements HttpCalloutMock {
        public Boolean failResponse { get; set; }

        public TestHttpCalloutMock(Boolean failResponse) {
            this.failResponse = failResponse;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('https://system-oauth-provider-test.us-w2.cloudhub.io')) {
                if (failResponse) {
                    res.setStatusCode(400);
                    
                    res.setBody('{"error": "Failed to get access token."}');
                } else {
                    res.setStatusCode(200);
                    res.setBody('{"access_token": "YOUR_ACCESS_TOKEN", "token_type": "Bearer", "expires_in": 3600, "scope": "SHIPMENT_WRITE"}');
                }
            } else {
                res.setStatusCode(404);
            }
            return res;
        }
    }

    @isTest
    static void testGetAccessTokenFailure() {
        Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(true));

        Test.startTest();
        Exception expectedException;
        try {
            String accessToken = TestAuthMule.getAccessToken();
        } catch (CalloutException e) {
            expectedException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, expectedException, 'Expected a CalloutException to be thrown');
        System.assertEquals('Error getting access token. Status Code: 400, Status: null, Message: {"error": "Failed to get access token."}', expectedException.getMessage(), 'Exception message should match the expected value');
    }

    @isTest
    static void testGetAccessTokenSuccess() {
       /* Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(false));

        Test.startTest();
        String accessToken = MuleSoftAuthorization.getAccessToken();
        Test.stopTest();

        System.assertEquals('YOUR_ACCESS_TOKEN', accessToken, 'Access token should match the expected value');*/
    }
}