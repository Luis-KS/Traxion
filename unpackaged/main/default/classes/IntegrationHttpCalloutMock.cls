@isTest
public class IntegrationHttpCalloutMock implements HttpCalloutMock {
    public Boolean failResponse { get; set; } 
    
    MuleSoft_Integration_Settings__mdt settings =  [SELECT Api_Base_Url__c, AccessToken_Url__c 
                                                            FROM  MuleSoft_Integration_Settings__mdt
                                                            WHERE DeveloperName = 'Traxion'];

    public IntegrationHttpCalloutMock(Boolean failResponse) {
        this.failResponse = failResponse;
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        if (req.getEndpoint().contains(settings.Api_Base_Url__c)) {
            if (failResponse) {
                res.setStatusCode(400);
                res.setBody('{"error": "Failed to get availability."}');
            } else {
                res.setStatusCode(200);
                res.setBody('[{"sku": "sku1", "availability": 10, "package_key": "package1", "packages_details": [{"quantity_pieces_package": 1, "availability": 2}]}]');
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