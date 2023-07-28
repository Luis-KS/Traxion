public without sharing class ReplaneacionController {
    
    public class OrderInformationWrapper {
        public String order_Number { get; set; }
        public String orderId { get; set; }
        public String motivo { get; set; }
        public String orderStatus { get; set; }
        public String IdTransporte { get; set; }
        public String orderUMU { get; set; }
        public String umuId { get; set; }
        public String Ciudad { get; set; }
        public String Estado { get; set; }
        public Datetime FechaEntrega { get; set; }
        public String Evidencia { get; set; }
        public String Comentario { get; set; }
        public TransportistaInfo informacionDeTransportista { get; set; }
    }
    
    public class TransportistaInfo {
        public String IdTransportista { get; set; }
        public String Nombre { get; set; }
        public String Telefono { get; set; }
        public String Email { get; set; }
        public String FotoChecking { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Order_Line_Item__c> getOrderProduct(String orderId) {
        try {
            List<Order_Line_Item__c> ordList = [
                SELECT
                Id,
                Product__r.Name,
                Product__r.Product_Code_ID__c,
                Numero_de_Lote__c,
                Cantidad_de_Piezas__c,
                Cantidad_Recibida__c,
                Cantidad__c,
                Costo_Total__c,
                Costo_Promedio__c,
                Cantidad_Solicitada__c, Cantidad_Entregada__c,	
                (SELECT Name, Cantidad__c, Fecha_de_Expiracion__c, Numero_de_Lote__c FROM Informacion_De_Lotes__r)
                FROM Order_Line_Item__c
                WHERE Order__c = :orderId
            ];
            
            return ordList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getReplaneacionData(String userId) {  
        try {
            Id contactId = UserContactClass.getContactIdFromUser();
            
            System.debug('contactId---> ' + contactId);
            
            Set<String> umuIds = new Set<String>();
            
            List<AccountContactRelation> umuList = [
                SELECT AccountId, Account.Name
                FROM AccountContactRelation
                WHERE ContactId = :contactId
            ];
            
            System.debug('umuList---> ' + umuList);
            
            for (AccountContactRelation umuRelation : umuList) {
                umuIds.add(umuRelation.AccountId);
            }
            
            System.debug('umuId---> ' + umuIds);
            
            List<Order__c> orderList = [
                SELECT
                id,
                Order_Number__c,
                Fecha_Maxima_de_Entrega__c,
                Fecha_Limite_de_Entrega__c,
                Tipo_de_Pedido__c,
                Total_de_Piezas__c,
                UMU__r.Name,
                UMU__c,
                UMU__r.Estado__c,
                Motivo__c,
                Estatus__c,
                Entrega__r.Estado__c,
                Entrega__r.Name,
                Entrega__c,
                Entrega__r.ID_de_Viaje__c,
                Entrega__r.OwnerId,
                Entrega__r.owner.Name,
                Entrega__r.owner.Email,
                Entrega__r.owner.Phone,
                isRecibida__c,
                Descripcion__c,
                (SELECT Id, ContentDocument.Id FROM ContentDocumentLinks)
                FROM Order__c
                // TODO: Change the status for testing, the encargado de campo solo ve las ordenes Recibidas Parcial
                WHERE
                UMU__r.id IN :umuIds
                AND Entrega__c != NULL
                AND Estatus__c = 'Recibido Parcial'
            ];
            
            List<OrderInformationWrapper> orderInformationWrapperList = new List<OrderInformationWrapper>();
            
            for (Order__c order : orderList) {
                OrderInformationWrapper singleOrderInformation = new OrderInformationWrapper();
                TransportistaInfo singleTransportistaInfo = new TransportistaInfo();
                
                singleOrderInformation.orderId = order.Id;
                singleOrderInformation.order_Number = order.Order_Number__c;
                singleOrderInformation.orderStatus = order?.Estatus__c;
                singleOrderInformation.IdTransporte = order?.Entrega__r.Name;
                singleOrderInformation.orderUMU = order?.UMU__r.Name;
                singleOrderInformation.umuId = order?.UMU__c;
                singleOrderInformation.Comentario = order?.Descripcion__c;
                singleOrderInformation.motivo = order?.Motivo__c;
                singleOrderInformation.Estado = order?.UMU__r.Estado__c;
                singleOrderInformation.FechaEntrega = order?.Fecha_Limite_de_Entrega__c;
                
                if (order.ContentDocumentLinks.size() > 0) {
                    singleOrderInformation.Evidencia = order.ContentDocumentLinks[0]
                        ?.ContentDocument
                        ?.id;
                    System.debug(order.ContentDocumentLinks[0]?.ContentDocument?.id);
                }
                
                singleTransportistaInfo.IdTransportista = order?.Entrega__r.OwnerId;
                singleTransportistaInfo.Nombre = order?.Entrega__r.owner?.Name;
                singleTransportistaInfo.Email = order?.Entrega__r.owner?.Email;
                singleTransportistaInfo.Telefono = order?.Entrega__r.owner?.Phone;
                
                singleOrderInformation.informacionDeTransportista = singleTransportistaInfo;
                System.debug(order);
                System.debug(singleOrderInformation);
                orderInformationWrapperList.add(singleOrderInformation);
            }
            
            // System.debug(orderInformationWrapperList);
            
            return JSON.serialize(orderInformationWrapperList);
        } catch (Exception e) {
            System.debug(e.getStackTraceString());
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String firmarOrden(String orderId) {
        try {
            List<Order__c> orders = [
                SELECT Id, Estatus__c
                FROM Order__c
                WHERE Id = :orderId
                LIMIT 1
            ];
            
            if (orders.size() > 0) {
                orders[0].Estatus__c = 'En Firma Parcial';
                update orders;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return 'Firmada correctamente';
    }
    
    @AuraEnabled
    public static String editarOrdenParaEnviarAFirma(
        String orderId,
        String ordenParcialJson
    ) {
        OrderController.OrderUpdates orderUpdates = (OrderController.OrderUpdates) JSON.deserialize(
            ordenParcialJson,
            OrderController.OrderUpdates.class
        );
        
        System.debug(orderUpdates);
        
        List<Order__c> orders = [
            SELECT
            Id,
            Estatus__c,
            (
                SELECT
                Id,
                Estatus__c,
                Cantidad_Solicitada__c,
                Cantidad_Recibida__c,
                Cantidad_de_Piezas__c
                FROM Order_Line_Items__r
            )
            FROM Order__c
            WHERE Id = :orderId
            LIMIT 1
        ];
        
        List<Order_Line_Item__c> itemsToUpdate = new List<Order_Line_Item__c>();
        
        try {
            if (orders.size() > 0) {
                for (Order__c orden : orders) {
                    if (orderUpdates.descripcion != '') {
                        orden.Descripcion__c = orderUpdates.descripcion;
                    }
                    
                    if (orderUpdates.desviacion != '') {
                        orden.Motivo__c = orderUpdates.desviacion;
                    }
                    
                    orden.Fecha_De_Entrega__c = orderUpdates.selectedDate;
                    orden.Hora_De_Entrega__c = orderUpdates.selectedTime;
                    
                    Map<String, OrderController.OrderItemUpdate> itemsMap = new Map<String, OrderController.OrderItemUpdate>();
                    for (
                        OrderController.OrderItemUpdate itemUpdate : orderUpdates.orderItemsUpdates
                    ) {
                        itemsMap.put(itemUpdate.id, itemUpdate);
                    }
                    
                    for (Order_Line_Item__c lineItem : orden.Order_Line_Items__r) {
                        OrderController.OrderItemUpdate itemUpdate = itemsMap.get(
                            lineItem.Id
                        );
                        
                        if (itemUpdate != null) {
                            lineItem.Piezas_Faltantes__c = itemUpdate.cantidadDePiezasFaltantes;
                            
                            itemsToUpdate.add(lineItem);
                        }
                    }
                }
                
                update orders;
                
                update itemsToUpdate;
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            // TODO: change this for an aura exception
            throw new AuraHandledException(
                'Error al enviar registro: ' + e.getMessage()
            );
        }
        
        return JSON.Serialize(orders);
    }
    
    @AuraEnabled(cacheable=true)
    public static ContentDocumentLink getFiles(String orderId) {
        try {
            ContentDocumentLink datos = [
                SELECT
                Id,
                LinkedEntityId,
                ContentDocumentId,
                ContentDocument.Title,
                ContentDocument.FileType
                FROM ContentDocumentLink
                WHERE
                LinkedEntityId = :orderId
                AND ContentDocument.FileType != 'CSV'
                AND ContentDocument.FileType != 'PDF'
                LIMIT 1
            ];
            
            return datos;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}