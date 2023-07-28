@isTest
public class ServicioDeCertificacionTest {

    @isTest
    static void testCreateRecord() {
        Test.startTest();
        
        Account umuTest = TestDataFactory.createSingleAccount('Hospital UMU');
        
        Contact contactTest = TestDataFactory.createSingleContactRelatedToAccount(umuTest.Id,'contact Test FirstName', 'contact Test LastName', 'Todas');
        
        Order__c orderRecord = new Order__c(
            UMU__c = umuTest.Id,
            Tipo_de_Pedido__c = 'Ordinario',
            Total_de_Piezas__c = 10,
            Order_Number__c = 'OrderTest1',
            Contacto__c = contactTest.Id,
            Estatus__c = 'Preparando Envío'
        );
        insert orderRecord;

        String testBase64 = EncodingUtil.base64Encode(Blob.valueOf('Test PDF Content'));
        ContentVersion documentRecord = new ContentVersion(
            Title = 'TestPDF',
            PathOnClient = 'TestPDF.pdf',
            VersionData = EncodingUtil.base64Decode(testBase64)
        );
        insert documentRecord;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/Certificacion/';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        
        String jsonString = 
            '{' +
                '"order_number": "' + orderRecord.Order_Number__c + '",' +
                '"document_id": "' + documentRecord.Id + '",' +
                '"base_64_pdf": "' + testBase64 + '"' +
            '}';

        req.requestBody = Blob.valueOf(jsonString);

        RestContext.request = req;
        RestContext.response = res;

        ServicioDeCertificacion.createRecord();

        System.assertEquals(200, res.statusCode);
        System.assert(res.responseBody.toString().contains('successful'));

        ContentVersion updatedDocumentRecord = [
            SELECT VersionData
            FROM ContentVersion
            WHERE Id = :documentRecord.Id
            LIMIT 1
        ];

        System.assertEquals(
            testBase64,
            EncodingUtil.base64Encode(updatedDocumentRecord.VersionData)
        );

        Test.stopTest();
    }
}