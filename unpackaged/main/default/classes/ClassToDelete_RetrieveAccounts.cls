public class ClassToDelete_RetrieveAccounts {
    
    @AuraEnabled
    public static List<Order__c> getFilteredOrders(List<String> clavesSeleccionadas, List<String> umusSeleccionadas, List<String> estadosSeleccionados, List<String> pedidosSeleccionados, List<String> transportesSeleccionados, Date fechaInicio, Date fechaFin){
        
        // Order list to return 
        List<Order__c> orderList = new List<Order__c>();

        // Get related account Ids from contact
        List<Id> accountIdList = UserContactClass.getAccountIdsFromUser();


        List<Id> filteredOrderIdList = new List<Id>();
        if(!clavesSeleccionadas.isEmpty() || !umusSeleccionadas.isEmpty() || !estadosSeleccionados.isEmpty() || !pedidosSeleccionados.isEmpty() || !transportesSeleccionados.isEmpty()){                                                    
            
            String orderLineItemQuery = 'SELECT Estatus__c, Tipo_de_Pedido__c, Order__c, Product__c, Product__r.Product_Code_ID__c, Account__c, Account__r.Clave_Presupuestal__c, Account__r.Estado__c';
            orderLineItemQuery += ' FROM Order_Line_Item__c';
            orderLineItemQuery += ' WHERE Product__c != Null';

            if(!clavesSeleccionadas.isEmpty()){
                orderLineItemQuery += ' AND Product__r.Product_Code_ID__c IN: clavesSeleccionadas';
            }
            if(!umusSeleccionadas.isEmpty()){
                orderLineItemQuery += ' AND Account__r.Clave_Presupuestal__c IN: umusSeleccionadas';
            }
            if(!estadosSeleccionados.isEmpty()){
                orderLineItemQuery += ' AND Account__r.Estado__c IN: estadosSeleccionados';
            }
            if(!pedidosSeleccionados.isEmpty()){
                orderLineItemQuery += ' AND Tipo_de_Pedido__c IN: pedidosSeleccionados';
            }

            // if(!transportesSeleccionados.isEmpty()){
            //     orderLineItemQuery += ' AND Product__r.Product_Code_ID__c IN: transportesSeleccionados';
            // } 

            List<Order_Line_Item__c> orderLineItemList = Database.query(orderLineItemQuery);
            for(Order_Line_Item__c oli : orderLineItemList){
                filteredOrderIdList.add(oli.Order__c);
            }   
        }

        Integer dInicio = fechaInicio.day();
        Integer moInicio = fechaInicio.month();
        Integer yrInicio = fechaInicio.year();
        DateTime DTInicio = DateTime.newInstance(yrInicio, moInicio, dInicio, 00, 00, 00);

        Integer dFin = fechaFin.day();
        Integer moFin = fechaFin.month();
        Integer yrFin = fechaFin.year();
        DateTime DTFin = DateTime.newInstance(yrFin, moFin, dFin, 11, 59, 59);

        String orderQuery = 'SELECT Id, Name, CreatedDate, Estatus__c, Tipo_de_Pedido__c, Fecha_Limite_de_Entrega__c, ' +
                       'Contacto__c, Cantidad_Aprobada_c__c, UMU__c, Total_de_Piezas__c, Costo_Total__c, ' +
                       '(SELECT Id, Estatus__c, Cantidad_Solicitada__c, Cantidad_Aprobada__c, Account__r.Name, Account__r.Clave_Presupuestal__c, Product__r.Name, Product__r.Product_Code_ID__c FROM Order_Line_Items__r)';
        orderQuery += ' FROM Order__c';
        orderQuery += ' WHERE UMU__c IN: accountIdList';

        orderQuery += ' AND CreatedDate >=: DTInicio';
        orderQuery += ' AND CreatedDate <=: DTFin';

        if(!filteredOrderIdList.isEmpty()){
            orderQuery += ' AND Id IN: filteredOrderIdList';
        }
         
        orderList = Database.query(orderQuery); 
        return orderList;
    }

    @AuraEnabled
    public static List<Order_Line_Item__c> getOrderLineItems(List<Id> orderIdList){ 

        // Order line item list to return 
        List<Order_Line_Item__c> orderLineItemList = new List<Order_Line_Item__c>();

        // Get related account Ids from contact
        List<Id> accountIdList = UserContactClass.getAccountIdsFromUser();

        List<Order__c> orderQuery = [SELECT Id
                             FROM Order__c
                             WHERE UMU__c IN: accountIdList];

        orderLineItemList = [SELECT Id, Name, Estatus__c, Tipo_de_Pedido__c, Order__c, Account__c, Account__r.Name, Account__r.Clave_Presupuestal__c, Account__r.Estado__c, Product__r.Name, Product__r.Product_Code_ID__c
                                                        FROM Order_Line_Item__c 
                                                        WHERE Order__c IN: orderQuery];
        return orderLineItemList;
    } 

    @AuraEnabled 
    public static List<DPN_Line_Item__c> getActiveDPNLineItem(){ 
        Id accountId = '0013K00000y6NnxQAE';
        // Get related account Ids from contact
        List<DPN_Line_Item__c> activeDPNLineItemList = UserContactClass.getActiveDPNListFromUser(accountId);
        return activeDPNLineItemList;
    }
}