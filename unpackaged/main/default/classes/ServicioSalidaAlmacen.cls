@RestResource(urlMapping='/SalidaAlmacen/*')
global class ServicioSalidaAlmacen {

    @HttpPost
    global static void createRecord() {
        RestRequest pedido = RestContext.request;
        System.debug(pedido);
        RestResponse respuesta = RestContext.response;
        try {
            List<Order> orders = (List<Order>)JSON.deserialize(pedido.requestBody.toString(), List<Order>.class);
            System.debug('here');
			System.debug(orders);
            RespuestaTraxion respuestaTraxion = new RespuestaTraxion();
            respuestaTraxion.completedSuccessfully = true;
            respuestaTraxion.response = new ResponseData();
            respuestaTraxion.response.message = 'successful';
            respuestaTraxion.response.data = new DataInfo();

 

            Map<String, Entrega__c> entregaMap = new Map<String, Entrega__c>();
            Map<String, Order> orderMap = new Map<String, Order>();
            Set<String> allSkus = new Set<String>();

 

            for(Order orderRequest : orders){
                String loadNumber = orderRequest.load;

 

                Entrega__c entrega = new Entrega__c();
                entrega.Name = loadNumber;
                entrega.ID_de_Viaje__c = loadNumber;

 

                entregaMap.put(loadNumber, entrega);
                orderMap.put(orderRequest.order_number, orderRequest);

 

                for(SkuInfo sku : orderRequest.skus) {
                    allSkus.add(sku.sku);
                }
            }

 

            // upserting Entrega__c using External Id field
            Database.UpsertResult[] urList = Database.upsert(entregaMap.values(), Entrega__c.Fields.ID_de_Viaje__c, true);

 

            for(Database.UpsertResult ur : urList) {
                if(!ur.isSuccess()) {
                    respuesta.responseBody = Blob.valueOf('Error: ' + ur.getErrors());
                    respuesta.statusCode = 500;
                    return;
                }
            }

 

            List<Order__c> existingOrders = [SELECT Id, Order_Number__c, Estatus__c, Entrega__c,
                                             Cantidad_de_Cajas_en_la_Orden__c,
                                             (SELECT Id, Product__r.Product_Code_ID__c, Cantidad_de_Piezas__c, Numero_de_Lote__c, Fecha_de_Expiracion__c, Estatus__c 
                                              FROM Order_Line_Items__r WHERE Product__r.Product_Code_ID__c IN :allSkus) 
                                             FROM Order__c WHERE Order_Number__c IN :orderMap.keySet()];

 

            List<Order_Line_Item__c> itemsToUpdate = new List<Order_Line_Item__c>();
            List<Informacion_De_Lote__c> lotesToUpdate = new List<Informacion_De_Lote__c>();

 

            for(Order__c existingOrder : existingOrders){
                Order orderRequest = orderMap.get(existingOrder.Order_Number__c);
                existingOrder.Entrega__c = entregaMap.get(orderRequest.load).Id;
                existingOrder.Estatus__c = 'Enviado';
                existingOrder.Cantidad_de_Cajas_en_la_Orden__c = orderRequest.box_quantity;


 

                Map<String, Order_Line_Item__c> skuToOrderLineItem = new Map<String, Order_Line_Item__c>();
                for(Order_Line_Item__c oli : existingOrder.Order_Line_Items__r){
                    skuToOrderLineItem.put(oli.Product__r.Product_Code_ID__c, oli);
                }

 

                for(SkuInfo sku : orderRequest.skus){
                    Order_Line_Item__c lineItem = skuToOrderLineItem.get(sku.sku);
                    if(lineItem != null){
                        for(loteInfo lote : sku.lote_info){
                            Informacion_De_Lote__c loteToUpdate = new Informacion_De_Lote__c();
                            
                            // Date is coming in the format DD/MM/YYYY and we need to transform it into MM/DD/YYYY
                            String[] dateParts = lote.expiration_date.split('/');
							// String reformattedDate = dateParts[1] + '/' + dateParts[0] + '/' + dateParts[2];

                            // Date parsedDate = Date.parse(reformattedDate);

                            Integer year = Integer.valueOf(dateParts[2]);
                            Integer month = Integer.valueOf(dateParts[1]);
                            Integer day = Integer.valueOf(dateParts[0]);

                            Date parsedDate = Date.newInstance(year, month, day); 
							
                            
                            loteToUpdate.Fecha_de_Expiracion__c = parsedDate;
                            loteToUpdate.Cantidad__c = lote.quantity;
                            loteToUpdate.Numero_de_Lote__c = lote.lot_number;
                            loteToUpdate.Order_Line_Item__c = lineItem.Id;
                            lotesToUpdate.add(loteToUpdate);
                        }
                        lineItem.Cantidad_de_Piezas__c = sku.quantity;
                        lineItem.Costo_Promedio__c = sku.avg_cost;

                        lineItem.Estatus__c = 'Enviado';
                        itemsToUpdate.add(lineItem);
                    }
                }
            }

 

            update existingOrders;
            update itemsToUpdate;
            insert lotesToUpdate;

 

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

    global class Order {
        public String order_number;
        public String umu;
        public String load;
        public Integer box_quantity;
        public String umu_name;
        public String route;
        public List<SkuInfo> skus;
    }

    global class SkuInfo {
        public String sku;
        public Integer quantity;
        public Double avg_cost;
        public List<LoteInfo> lote_info;
    }

 

    global class LoteInfo {
        public Integer quantity;
        public String expiration_date;
        public String lot_number;
    }
}