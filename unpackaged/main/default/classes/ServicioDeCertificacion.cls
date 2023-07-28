@RestResource(urlMapping='/Certificacion/*')
global class ServicioDeCertificacion {

    @HttpPost
    global static void createRecord() {
        RestRequest pedido = RestContext.request;
        RestResponse respuesta = RestContext.response;
        try {                     
            RequestBody requestBody = (RequestBody)JSON.deserialize(pedido.requestBody.toString(), RequestBody.class);
            RespuestaTraxion respuestaTraxion = new RespuestaTraxion();
            respuestaTraxion.completedSuccessfully = true;
            respuestaTraxion.response = new ResponseData();
            respuestaTraxion.response.message = 'successful';
            respuestaTraxion.response.data = new DataInfo();
          
            String orderNumber = requestBody.order_number;
            String documentID = requestBody.document_id;
            String base64PDF = requestBody.base_64_pdf;
            
            // look for the order that have the document
            Order__c orderRecord = [SELECT Id FROM Order__c WHERE Order_Number__c = :orderNumber LIMIT 1];

            if (orderRecord != null) {
                // Look for the document version
                ContentVersion documentRecord = [SELECT Id, Title, VersionData, PathOnClient FROM ContentVersion WHERE Id = :documentID LIMIT 1];

                if (documentRecord != null) {
                    // modify the document
                    documentRecord.VersionData = EncodingUtil.base64Decode(base64PDF);

                    // update it
                    update documentRecord; 
                } else {
                    throw new ServicioDeCertificacionException('Document not found');
                }
            } else {
                throw new ServicioDeCertificacionException('Order not found');
            }
            
            String responseBody = JSON.serialize(respuestaTraxion);
            respuesta.responseBody = Blob.valueOf(responseBody);
            respuesta.statusCode = 200;
        } catch (Exception ex) {
            respuesta.responseBody = Blob.valueOf('Error: ' + ex.getMessage());
            respuesta.statusCode = 500;
        }
    }
    
    global class RespuestaTraxion {
        public Boolean completedSuccessfully;
        public ResponseData response;
    }
    
    global class ResponseData {
        public String message;
        public DataInfo data;
    }
    
    global class DataInfo {
    }
    
    global class RequestBody {
        public String order_number;
        public String document_id;
        public String base_64_pdf;
    }
    
    public class ServicioDeCertificacionException extends Exception {}
}