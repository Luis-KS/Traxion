@RestResource(urlMapping='/AsignacionInventario/*')
global class ServicioAsignacionInventario {
    
    @testVisible
    private Static Boolean throwEx = false;
    
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
            List<SkuInfo> skus = requestBody.skus; 

            Order__c order = [SELECT Id, Name, Estatus__c, Order_Number__c, (SELECT Id, name, Product__r.Product_Code_ID__c FROM Order_Line_Items__r) FROM Order__c WHERE Order_Number__c =: orderNumber LIMIT 1];
            
            order.Estatus__c = 'Preparando Envío';


            List<Order_Line_Item__c> orderLineItems = order.Order_Line_Items__r;
            
            Map<String, Order_Line_Item__c> productCodeToOrderLineItemMap = new Map<String, Order_Line_Item__c>();

            for(Order_Line_Item__c oli : orderLineItems) {
                productCodeToOrderLineItemMap.put(oli.Product__r.Product_Code_ID__c, oli);
            }
        
            List<Order_Line_Item__c> skuListToUpdate = new List<Order_Line_Item__c>();
            
            
            for(SkuInfo sku : skus){
                if (productCodeToOrderLineItemMap.containsKey(sku.sku)) {
                    Order_Line_Item__c skuLineRecord = productCodeToOrderLineItemMap.get(sku.sku);
                    skuLineRecord.Cantidad_de_Piezas__c = sku.quantity;
                    skuLineRecord.Estatus__c = 'Preparando Envío';
                    skuListToUpdate.add(skuLineRecord);
                }
            }

            update skuListToUpdate;

            update order;

            System.debug(skuListToUpdate);
          
            String responseBody = JSON.serialize(respuestaTraxion);
            
            respuesta.responseBody = Blob.valueOf(responseBody);
            respuesta.statusCode = 200;
            
            if(Test.isRunningTest() && throwEx){
                throw new CustomException('Error during testing.');
            }
            
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
        public List<SkuInfo> skus;
    }
    
    global class SkuInfo {
        public String sku;
        public Integer quantity;
    }
    
    public class CustomException extends Exception {}

}