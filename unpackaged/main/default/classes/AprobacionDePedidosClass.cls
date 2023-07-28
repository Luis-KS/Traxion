public with sharing class AprobacionDePedidosClass {

    private static ParametersDataTable dataTableParams;
    private static final String TIPO_DE_PEDIDO_EXCENTO = 'Ordinario';
    private static final String TIPO_DE_PEDIDO_NO_VALIDO = 'Programa';
    private static final String ESTATUS_ACTIVO = 'Activo'; 

    private static final String ESTATUS_APROBACION = 'Aprobado'; 
    private static final String ESTATUS_AUTORIZACION = 'Autorizado'; 
    private static final String ESTATUS_MODIFICADO = 'Modificado'; 
    private static final String ESTATUS_PENDIENTE = 'Pendiente';
    private static final String ESTATUS_RECHAZADO = 'Rechazado';

    public class DataPedido{
        @AuraEnabled public Date fechaInicio;
        @AuraEnabled public Date fechaFin;
        @AuraEnabled public Boolean esAprobacion;
        @AuraEnabled public String estatusNoOrdinario;
    }

    public class DataDeOLIWrapper{
        public String productid;
        public String dpn;
        public String validado;
        public String piezassolicitadas; 
        public String entransito;
        public String existenciaumu; 
        public String existenciacenadi;
    }

    public class DataDeSKUsWrapper{
        public String sku;
        public Integer availability; 
    }

    @AuraEnabled
    public static List<Pedido__c> getFilteredPedidos(String pedidoJSON){
        // Deserialize pedidoJSON and get the data
        DataPedido dataPedido = (DataPedido)JSON.deserialize(pedidoJSON, DataPedido.class);

        // Retrieve the list of Account Ids associated with the user
        List<Id> accountIdList = UserContactClass.getAccountIdsFromUser();

        // Query Order_Line_Item__c records based on the Account Ids
        String oliQuery = 'SELECT Id, Pedido__c ' +
            'FROM Order_Line_Item__c ' +
            'WHERE UMU__c IN: accountIdList'; 
        if(!dataPedido.esAprobacion){
            oliQuery += ' AND (Estatus_Aprobaci_n__c =: ESTATUS_APROBACION ' +
            'OR Estatus_Aprobaci_n__c =: ESTATUS_MODIFICADO)';
        }  
        List<Order_Line_Item__c> oliList = Database.query(oliQuery);  

        // Collect unique Pedido__c Ids from the retrieved Order_Line_Item__c records
        Set<Id> pedidoIdSet = new Set<Id>();
        for(Order_Line_Item__c oli : oliList){
            pedidoIdSet.add(oli.Pedido__c);
        } 
        List<Id> pedidoIdList = new List<Id>(pedidoIdSet);

        // Prepare the list of valid options for authorization
        List<String> validOptionsToAthorize = new List<String>();
        if(!dataPedido.esAprobacion){
            validOptionsToAthorize.add(ESTATUS_APROBACION);
            validOptionsToAthorize.add(ESTATUS_MODIFICADO);
        }

        // Query Pedido__c records based on the specified parameters
        List<Pedido__c> pedidosList = MisPedidosClass.pedidosQuery(dataPedido.fechaInicio, dataPedido.fechaFin, false, TIPO_DE_PEDIDO_EXCENTO, TIPO_DE_PEDIDO_NO_VALIDO, pedidoIdList, validOptionsToAthorize);

        // Filter the Pedido__c records and return the Pedido__c list
        List<Pedido__c> filteredPedidoList = new List<Pedido__c>();
        for (Pedido__c pedido : pedidosList) {
            if (hasMatchingOrderLineItem(pedido, dataPedido.esAprobacion, dataPedido.estatusNoOrdinario)) {
                filteredPedidoList.add(pedido); 
            }
        }
        return filteredPedidoList;
    }

    private static Boolean hasMatchingOrderLineItem(Pedido__c pedido, Boolean esAprobacion, String estatusNoOrdinario) {
        for (Order_Line_Item__c oli : pedido.Order_Line_Items__r) {
            if (esAprobacion && (oli.Estatus_Aprobaci_n__c == estatusNoOrdinario || (oli.Estatus_Aprobaci_n__c == ESTATUS_MODIFICADO && estatusNoOrdinario != ESTATUS_PENDIENTE && estatusNoOrdinario != ESTATUS_RECHAZADO))) {
                return true;
            } else if(!esAprobacion && (oli.Estatus_Autorizaci_n__c == estatusNoOrdinario || (oli.Estatus_Autorizaci_n__c == ESTATUS_MODIFICADO && estatusNoOrdinario != ESTATUS_PENDIENTE && estatusNoOrdinario != ESTATUS_RECHAZADO))){
                return true;
            }
        } 
        return false;
    } 

    @AuraEnabled
    public static List<Pedido__c> updateOrderLineItem(Id orderLineId, String actionType, Integer quantity, String message, Boolean esAprobacion){ 
        // Query the Order_Line_Item__c record
        List<Order_Line_Item__c> oliList = [
            SELECT Id, Name, Estatus__c, Motivo_No_Aprobaci_n__c, Cantidad_Solicitada__c, Tipo_de_Pedido__c,  
                Account__c, Account__r.Name, Account__r.Clave_Presupuestal__c, L_mite_Mensual_DPN__c, Consumido_DPN__c, Pedido__c,
                Existencia_en_UMU__c, Disponible_en_CENADI__c, Cantidad_de_Piezas__c, Costo__c, Cantidad_Rechazada__c, Order__c,
                Account__r.Estado__c, Product__c, Product__r.Name, Product__r.Product_Code_ID__c, Estatus_Aprobaci_n__c, 
                Dispobible_a_Solicitar__c, Estatus_Autorizaci_n__c, Cantidad_Autorizada__c, Autorizaci_n_Cantidad_Rechazada__c, 
                Motivo_No_Autorizaci_n__c
            FROM Order_Line_Item__c 
            WHERE Id =: orderLineId
            LIMIT 1
        ]; 

        System.debug(oliList.isEmpty());

        if(oliList.isEmpty()){
            return null;
        }  

        Order_Line_Item__c oliToUpdate = oliList[0]; 
        Integer cantidadRechazada = actionType != ESTATUS_PENDIENTE ? Integer.valueOf(oliToUpdate.Cantidad_Solicitada__c) - quantity : 0;

        if(esAprobacion){
            // Update fields related to approval
            oliToUpdate.Estatus_Aprobaci_n__c = actionType;
            oliToUpdate.Cantidad_Aprobada__c = quantity;
            oliToUpdate.Cantidad_Rechazada__c = cantidadRechazada;
            oliToUpdate.Motivo_No_Aprobaci_n__c = message; 
            
            if(actionType == ESTATUS_RECHAZADO){
                // Update fields for rejected items
                oliToUpdate.Estatus_Autorizaci_n__c = actionType;
                oliToUpdate.Cantidad_Autorizada__c = quantity;
                oliToUpdate.Autorizaci_n_Cantidad_Rechazada__c = cantidadRechazada;
                oliToUpdate.Motivo_No_Autorizaci_n__c = message; 
            }
        } else{
            // Update fields related to authorization
            oliToUpdate.Estatus_Autorizaci_n__c = actionType;
            oliToUpdate.Cantidad_Autorizada__c = quantity; 
            oliToUpdate.Autorizaci_n_Cantidad_Rechazada__c = cantidadRechazada;
            oliToUpdate.Motivo_No_Autorizaci_n__c = message; 
        }
        
        try{
            update oliToUpdate;
        } catch(DMLException e){
            System.debug(e.getMessage());
            return null;
        } 
        Id pedidoId = oliToUpdate.Pedido__c;

        String pedidoWithRelatedOLIQuery = 'SELECT Id, Name, CreatedDate, Tipo_de_Pedido__c, ID_de_Pedido__c, Folio_de_Pedido__c, ' +
            'UMU__c, Fecha_Limite_de_Entrega__c, Estatus__c, Numero_de_Oficio__c, Mostrar_Envio_a_Autorizacion__c, Mostrar_Autorizacion__c, ' +
            'Total_de_Claves__c, Total_de_Piezas__c, Creado_Por__c, Creado_Por__r.Name, UMU__r.Name, UMU__r.UMU__c, ' +
            'UMU__r.Estado__c, UMU__r.Colonia__c, UMU__r.Delegacion__c, UMU__r.Clave_Presupuestal__c, UMU__r.Tipo_UMU__c, ' +
            '(SELECT Id, Estatus__c, Cantidad_Solicitada__c, Cantidad_Aprobada__c, Cantidad_Autorizada__c, Motivo_No_Aprobaci_n__c, ' +
            'Motivo_No_Autorizaci_n__c, Autorizaci_n_Cantidad_Rechazada__c, Cantidad_Rechazada__c, ' +
            'Cantidad_de_Piezas__c, Costo__c, Estatus_Aprobaci_n__c, Estatus_Autorizaci_n__c, ' +
            'Account__r.Name, Account__r.Clave_Presupuestal__c, Account__r.Estado__c, Product__r.Name, Product__r.Product_Code_ID__c, ' +
            'Product__r.Subalmacen__c, Product__r.Subalmacen__r.Name, Product__r.Subalmacen__r.Numero_de_Subalmacen__c, ' +
            'Product__r.Programa__c, Product__r.Programa__r.Inventario__c, Product__r.Programa__r.Programa_ID__c, ' +
            'Product__r.Programa__r.Name, Product__r.Description__c ' +
            'FROM Order_Line_Items__r';

        if(esAprobacion){
            pedidoWithRelatedOLIQuery += ')';
        } else{
            List<String> validOptionsToAthorize = new List<String>{ESTATUS_APROBACION, ESTATUS_MODIFICADO}; 
            pedidoWithRelatedOLIQuery += ' WHERE Estatus_Aprobaci_n__c IN: validOptionsToAthorize)';
        } 
        pedidoWithRelatedOLIQuery += ' FROM Pedido__c ' +
            'WHERE Id =: pedidoId ' +
            'LIMIT 1';   
        List<Pedido__c> pedidoWithRelatedOLI = Database.query(pedidoWithRelatedOLIQuery);  

        if(esAprobacion && (actionType == ESTATUS_APROBACION || actionType == ESTATUS_MODIFICADO || actionType == ESTATUS_RECHAZADO)){
            pedidoWithRelatedOLI[0].Mostrar_Envio_a_Autorizacion__c = true;
        } else if(!esAprobacion && (actionType == ESTATUS_AUTORIZACION || actionType == ESTATUS_MODIFICADO || actionType == ESTATUS_RECHAZADO)){
            pedidoWithRelatedOLI[0].Mostrar_Autorizacion__c = true;
        }  

        try{
            update pedidoWithRelatedOLI;
        } catch(DMLException e){
            System.debug(e.getMessage());
            return null;
        }  
        return pedidoWithRelatedOLI;  
    }  

    @AuraEnabled
    public static List<Pedido__c> updateIdDePedido(Id pedidoId, Boolean esAprobacion){ 
        List<Id> pedidoIdList = new List<Id>{pedidoId}; 
        List<Pedido__c> pedidosList = MisPedidosClass.pedidosQuery(null, null, null, null, null, pedidoIdList, null); 
        if(pedidosList.isEmpty()){
            return null; 
        }   

        List<Order_Line_Item__c> oliList = [
            SELECT Order__c, Cantidad_Aprobada__c, Estatus_Aprobaci_n__c, Estatus_Autorizaci_n__c, Numero_de_Subalmacen__c, 
                Pedido__r.App_Next_Par_Num__c, Pedido__r.Auth_Next_Par_Num__c
            FROM Order_Line_Item__c
            WHERE Pedido__c =: pedidoId
        ]; 

        List<Order_Line_Item__c> sortedOliList = new List<Order_Line_Item__c>();
        List<Order_Line_Item__c> aprobadoOliList = new List<Order_Line_Item__c>();
        List<Order_Line_Item__c> rechazadoOliList = new List<Order_Line_Item__c>();
        for(Order_Line_Item__c oli : oliList){
            if (esAprobacion && (oli.Estatus_Aprobaci_n__c == ESTATUS_APROBACION || oli.Estatus_Aprobaci_n__c == ESTATUS_MODIFICADO)) {
                aprobadoOliList.add(oli);
            } else if (!esAprobacion && (oli.Estatus_Autorizaci_n__c == ESTATUS_AUTORIZACION || oli.Estatus_Autorizaci_n__c == ESTATUS_MODIFICADO)) {
                aprobadoOliList.add(oli);
            } else if (esAprobacion && (oli.Estatus_Aprobaci_n__c == ESTATUS_RECHAZADO || oli.Estatus_Aprobaci_n__c == ESTATUS_PENDIENTE)) {
                rechazadoOliList.add(oli);
            } else if (!esAprobacion && (oli.Estatus_Autorizaci_n__c == ESTATUS_RECHAZADO || oli.Estatus_Autorizaci_n__c == ESTATUS_PENDIENTE)) {
                rechazadoOliList.add(oli);
            } 
        } 
        sortedOliList.addAll(rechazadoOliList);
        sortedOliList.addAll(aprobadoOliList);
        

        System.debug('Printing sortedlist');
        System.debug(sortedOliList);

        Pedido__c pedidoToUpdate = pedidosList[0]; 
        String currentPedidoId = pedidoToUpdate.ID_de_Pedido__c;
        String updatedPedidoId = pedidoToUpdate.ID_de_Pedido__c;


        Map<String, List<Order_Line_Item__c>> pedidoOliMap = new Map<String, List<Order_Line_Item__c>>();
        Map<String, Set<Id>> pedidoOrderMap = new Map<String, Set<Id>>();
        Set<Id> allOrdersIdSet = new Set<Id>();
        Set<Id> aprobadoOrdersIdSet = new Set<Id>(); 
        List<Id> pedidoIdsToReturn = new List<Id>();
        
        Boolean autorizar = false;

        // TODO: Refactor this code
        for(Order_Line_Item__c oli : sortedOliList){ 
            allOrdersIdSet.add(oli.Order__c); 
            if(esAprobacion && (oli.Estatus_Aprobaci_n__c == 'Aprobado' || oli.Estatus_Aprobaci_n__c == 'Modificado' || oli.Estatus_Aprobaci_n__c == 'Rechazado')){
                if(updatedPedidoId != currentPedidoId + '-00'){
                    if(oli.Estatus_Aprobaci_n__c != 'Rechazado' && currentPedidoId == updatedPedidoId && oli.Pedido__r.App_Next_Par_Num__c == 1){
                        updatedPedidoId = currentPedidoId + '-00';
                    } else{
                        String sigNumParticion = String.valueOf(oli.Pedido__r.App_Next_Par_Num__c);
                        String formattedNumParticion = '-' + sigNumParticion.leftPad(2, '0');
                        updatedPedidoId = currentPedidoId + formattedNumParticion;
                    }
                } 
                aprobadoOrdersIdSet.add(oli.Order__c);
            } else if(esAprobacion && (oli.Estatus_Aprobaci_n__c == 'Pendiente')){  
                if(!pedidoOliMap.containsKey(currentPedidoId)){
                    pedidoOliMap.put(currentPedidoId, new List<Order_Line_Item__c>());
                    pedidoOrderMap.put(currentPedidoId, new Set<Id>());
                }
                pedidoOliMap.get(currentPedidoId).add(oli); 
                pedidoOrderMap.get(currentPedidoId).add(oli.Order__c); 

                String sigNumParticion = String.valueOf(oli.Pedido__r.App_Next_Par_Num__c);
                String formattedNumParticion = '-' + sigNumParticion.leftPad(2, '0');
                if(updatedPedidoId != currentPedidoId + formattedNumParticion){
                    updatedPedidoId = currentPedidoId + formattedNumParticion;
                }
            } 

            if(!esAprobacion && (oli.Estatus_Autorizaci_n__c == 'Autorizado' || oli.Estatus_Autorizaci_n__c == 'Modificado' || oli.Estatus_Autorizaci_n__c == 'Rechazado')){
                if(updatedPedidoId != currentPedidoId + '-00'){
                    if(oli.Estatus_Autorizaci_n__c != 'Rechazado' && currentPedidoId == updatedPedidoId && oli.Pedido__r.Auth_Next_Par_Num__c == 1){
                        autorizar = true;
                        updatedPedidoId = currentPedidoId + '-00';
                    } else{
                        if(oli.Estatus_Autorizaci_n__c != 'Rechazado') autorizar = true;
                        String sigNumParticion = String.valueOf(oli.Pedido__r.Auth_Next_Par_Num__c);
                        String formattedNumParticion = '-' + sigNumParticion.leftPad(2, '0');
                        updatedPedidoId = currentPedidoId + formattedNumParticion;
                    }
                } 
                aprobadoOrdersIdSet.add(oli.Order__c);
            } else if(!esAprobacion && (oli.Estatus_Autorizaci_n__c == 'Pendiente')){  
                if(!pedidoOliMap.containsKey(currentPedidoId)){
                    pedidoOliMap.put(currentPedidoId, new List<Order_Line_Item__c>());
                    pedidoOrderMap.put(currentPedidoId, new Set<Id>());
                }
                pedidoOliMap.get(currentPedidoId).add(oli); 
                pedidoOrderMap.get(currentPedidoId).add(oli.Order__c);  
                String sigNumParticion = String.valueOf(oli.Pedido__r.Auth_Next_Par_Num__c);
                String formattedNumParticion = '-' + sigNumParticion.leftPad(2, '0');
                if(updatedPedidoId != currentPedidoId + formattedNumParticion){
                    updatedPedidoId = currentPedidoId + formattedNumParticion;
                }
            } 
        } 

        Id contactId = UserContactClass.getContactIdFromUser(); 

        pedidoToUpdate.ID_de_Pedido__c = updatedPedidoId; 
        if(esAprobacion){
            pedidoToUpdate.Mostrar_Envio_a_Autorizacion__c = false;
            pedidoToUpdate.Aprobado_Por__c = contactId; 
            pedidoToUpdate.Fecha_Revision_Delegacion__c = Datetime.now();
        } else{
            pedidoToUpdate.Mostrar_Autorizacion__c = false;
            if(autorizar){
                pedidoToUpdate.Autorizado_Por__c = contactId; 
                pedidoToUpdate.Fecha_Revision_SICORA__c = Datetime.now();
            } 
        } 
        update pedidoToUpdate;

        Pedido__c lastPedido = pedidoToUpdate;

        pedidoIdsToReturn.add(pedidoToUpdate.Id);

        if(!pedidoOliMap.isEmpty()){
            Pedido__c pedido = pedidoToUpdate.clone(false, false, false, false);
            pedido.ID_de_Pedido__c = currentPedidoId; 
            pedido.Pedido_Original__c = pedidoToUpdate.Pedido_Original__c != null ? pedidoToUpdate.Pedido_Original__c : pedidoToUpdate.Id; 
            if(esAprobacion){
                pedido.App_Next_Par_Num__c = pedidoToUpdate.App_Next_Par_Num__c + 1;
                pedido.Mostrar_Envio_a_Autorizacion__c = false;
                pedidoToUpdate.Aprobado_Por__c = contactId; 
                pedidoToUpdate.Fecha_Revision_Delegacion__c = Datetime.now();
            } else{
                pedido.Auth_Next_Par_Num__c = pedidoToUpdate.Auth_Next_Par_Num__c + 1;
                pedidoToUpdate.Mostrar_Autorizacion__c = false;
                if(autorizar){
                    pedidoToUpdate.Autorizado_Por__c = contactId; 
                    pedidoToUpdate.Mostrar_Autorizacion__c = false;
                }
            }
            insert pedido;

            lastPedido = pedido;

            pedidoIdsToReturn.add(pedido.Id);
            
            Boolean removeAutorizadoPor = false;
            List<Id> orderIds = new List<Id>();
            List<Order_Line_Item__c> olisToUpdate = new List<Order_Line_Item__c>();
            List<Order_Line_Item__c> rejectedPendingOlis = new List<Order_Line_Item__c>();
            for(String pedidoIdentifier : pedidoOliMap.keySet()){
                for(Order_Line_Item__c oli : pedidoOliMap.get(pedidoIdentifier)){
                    oli.Pedido__c = pedido.Id;
                    olisToUpdate.add(oli);
                    if(oli.Estatus_Autorizaci_n__c == 'Rechazado' || oli.Estatus_Autorizaci_n__c == 'Pendiente'){
                        rejectedPendingOlis.add(oli);
                    }
                }
                
                for(Id orderId : pedidoOrderMap.get(pedidoIdentifier)){
                    orderIds.add(orderId);
                }
            }
            update olisToUpdate;

            if(olisToUpdate.size() == rejectedPendingOlis.size()){
                pedido.Autorizado_Por__c = null;
                update pedido;
            }
            
            List<Order__c> ordersToClone = [
                SELECT Id, UMU__c, Contacto__c, Estatus__c, Tipo_de_Pedido__c, Numero_de_Subalmacen__c, Seguimiento__c
                FROM Order__c
                WHERE Id IN: orderIds
            ];
            
            List<Order__c> ordersToInsert = new List<Order__c>();
            for(Order__c ord : ordersToClone){
                Order__c order = ord.clone(false, false, false, false);
                order.Pedido__c = pedido.Id; 
                order.Clon_Subalmacen__c = ord.Numero_de_Subalmacen__c; 
                order.Seguimiento__c = ord.Seguimiento__c;
                ordersToInsert.add(order);
            }
            insert ordersToInsert;
            
            List<Order__c> ordersWithData = [
                SELECT Id, UMU__c, Contacto__c, Estatus__c, Tipo_de_Pedido__c, Numero_de_Subalmacen__c, 
                    Folio_del_Pedido__c, Clon_Subalmacen__c
                FROM Order__c
                WHERE Id IN: ordersToInsert
            ];
            
            List<Order__c> lastOrderToUpdate = new List<Order__c>();
            List<Order_Line_Item__c> lastOliToUpdate = new List<Order_Line_Item__c>();
            for(Order__c ord : ordersWithData){
                for(Order_Line_Item__c oli : olisToUpdate){
                    if(String.valueOf(oli.Numero_de_Subalmacen__c) == ord.Clon_Subalmacen__c){
                        oli.Order__c = ord.Id;
                        lastOliToUpdate.add(oli);
                    }
                }
                ord.Order_Number__c = ord.Clon_Subalmacen__c + '-' + ord.Folio_del_Pedido__c;
                lastOrderToUpdate.add(ord);
            }
            update lastOrderToUpdate;
            update lastOliToUpdate;
            
            Set<Id> orderIdsToDelete = new Set<Id>();
            for(Id orderId : allOrdersIdSet){
                if(!aprobadoOrdersIdSet.contains(orderId)){
                    orderIdsToDelete.add(orderId);
                }
            }
            if(!orderIdsToDelete.isEmpty()){
                List<Order__c> ordersToDelete = [
                    SELECT Id
                    FROM Order__c
                    WHERE Id IN: orderIdsToDelete
                ];
                delete ordersToDelete;
            }   
        }  

        return MisPedidosClass.pedidosQuery(null, null, null, null, null, pedidoIdsToReturn, null);
    } 

    @AuraEnabled
    public static String generatePedidoInWMS(Id pedidoId){ 
        List<Order_Line_Item__c> oliList = [
            SELECT Id, Order__c
            FROM Order_Line_Item__c
            WHERE Pedido__c =: pedidoId
                AND Estatus_Autorizaci_n__c != 'Rechazado' 
                AND Estatus_Autorizaci_n__c != 'Pendiente'
        ];
        Set<String> orderIdSet = new Set<String>();
        for(Order_Line_Item__c oli : oliList){
            orderIdSet.add(oli.Order__c);
        }
        List<String> orderIdList = new List<String>(orderIdSet);

        System.debug(orderIdList);

        if(orderIdList.isEmpty()){
            return 'No go to WMS';
        }

        if(Test.isRunningTest()){
            return 'Success';
        } else{
            return UserContactClass.checkGeneracionDePedido(orderIdList);
        }
    } 

    @AuraEnabled
    public static void sendEmailAprobacionAutorizacion(Boolean isAutorizacion, Id pedidoId, Id contactId, List<String> contactEmail, 
        String emailTemplate){ 

        List<Pedido__c> pedidoList = [
            SELECT ID_de_Pedido__c
            FROM Pedido__c
            WHERE Id =: pedidoId
            LIMIT 1
        ];
        Pedido__c pedido = pedidoList[0];
        String idDePedido = pedido.ID_de_Pedido__c;

        List<Order_Line_Item__c> oliList = [
            SELECT Id, Product__c, Order__c, Pedido__c
            FROM Order_Line_Item__c
            WHERE Pedido__c =: pedidoId
        ];
        List<Id> productIds = new List<Id>();
        for(Order_Line_Item__c oli : oliList){
            productIds.add(oli.Product__c);
        }
        String idsParameters = String.join(productIds, ',');
      
        String vfPageToRender = '/apex/PreAutorizacionDePedido?id=';
        if(isAutorizacion){
            vfPageToRender = '/apex/AutorizacionDePedido?id=';
        } 

        Pagereference pageRef = new Pagereference(vfPageToRender + pedidoId + '&listaProductos=' + idsParameters);

        Blob contentBlob = Test.isRunningTest() ? Blob.valueOf('UNIT.TEST') : pageRef.getContentAsPDF();

        List<ContentVersion> contentVersionList = new List<ContentVersion>();   
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.VersionData = contentBlob;
        contentVersion.Title = idDePedido + '.pdf';
        contentVersion.PathOnClient = 'AprobacionDePedido.pdf';
        contentVersionList.add(contentVersion);
        insert contentVersionList;

        List<String> conVerList = new List<String>();
        for(ContentVersion conver : contentVersionList){
            conVerList.add(conVer.Id);
        }

        if(Test.isRunningTest()){return;}

        EmailTemplate et = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName =: emailTemplate];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(et.Id);
        mail.setToAddresses(contactEmail);
        mail.setTargetObjectId(contactId); 
        mail.setWhatId(pedidoId); 
        mail.setEntityAttachments(conVerList); 
        mail.setSaveAsActivity(false);
        mail.setUseSignature(false);

        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        mailList.add(mail);

        if(!mailList.isEmpty()){
            Messaging.sendEmail(mailList);
        }
    }

    public static List<String> getFieldIdsList(Id orderId){
        List<DocumentWrapper> documentWrapperList  = FilesController.getAllDocumentsAndRelatedFiles(orderId);
        List<String> fileIds = new List<String>();

        for (DocumentWrapper doc : documentWrapperList) {
            fileIds.addAll(getFileIdsFromDocument(doc));
        }
        return fileIds;
    }

    private static List<String> getFileIdsFromDocument(DocumentWrapper doc) {
        List<String> fileIds = new List<String>();
        if (!doc.files.isEmpty()) {
            for(Integer i = 0; i < doc.files.size(); i++){
                fileIds.add(doc.files[i].id);
            } 
        }
        return fileIds;
    } 

    @AuraEnabled
    public static String oliProductInformation(String umuId, List<String> productIds) {
        List<DPN_Line_Item__c> dpnList = [
            SELECT Id, Product__c, Product__r.Product_Code_ID__c, L_mite_Mensual__c, Consumido__c
            FROM DPN_Line_Item__c
            WHERE DPN__r.Estatus__c = 'Activo'
                AND DPN__r.Account__c =: umuId
                AND Product__c IN: productIds
        ]; 
        System.debug(dpnList);

        List<Order_Line_Item__c> oliList = [
            SELECT Id, Product__c, Cantidad_de_Piezas__c, Order__c, Order__r.Estatus__c, Order__r.Tipo_de_Pedido__c
            FROM Order_Line_Item__c
            WHERE Order__r.Estatus__c = 'Enviado'
                AND Product__c IN: productIds
                AND UMU__c =: umuId
                AND Cantidad_de_Piezas__c != null
        ];

        Map<Id, Integer> oliProductQtyMap = new Map<Id, Integer>();
        for(Order_Line_Item__c oli : oliList){
            if(!oliProductQtyMap.containsKey(oli.Product__c)){
                oliProductQtyMap.put(oli.Product__c, 0);
            }
            Integer currentQty = oliProductQtyMap.get(oli.Product__c);
            Integer updatedQty = currentQty + Integer.valueOf(oli.Cantidad_de_Piezas__c);
            oliProductQtyMap.put(oli.Product__c, updatedQty);
        } 

        List<String> dpnliProductList = new List<String>();
        for(DPN_Line_Item__c dpnli : dpnList){
            dpnliProductList.add(String.valueOf(dpnli.Product__r.Product_Code_ID__c));
        }

        String skuAvailability = Test.isRunningTest() ? '[{ "sku": "0606970382", "availability": 16793}]' : UserContactClass.getDisponibilidadSkus2(JSON.serialize(dpnliProductList));

        List<DataDeSKUsWrapper> skuInfoList = (List<DataDeSKUsWrapper>)JSON.deserialize(skuAvailability, List<DataDeSKUsWrapper>.class);
        
        List<DataDeOLIWrapper> dataDeOliList = new List<DataDeOLIWrapper>();
        for(DPN_Line_Item__c dpnli : dpnList){
            DataDeOLIWrapper dpnliData = new DataDeOLIWrapper();
            dpnliData.productid = String.valueOf(dpnli.Product__c);
            dpnliData.dpn = dpnli.L_mite_Mensual__c != null ? String.valueOf(dpnli.L_mite_Mensual__c) : 'N/A';
            dpnliData.validado = dpnli.L_mite_Mensual__c != null && dpnli.Consumido__c != null ? String.valueOf(dpnli.Consumido__c) : dpnli.L_mite_Mensual__c != null ? '0' : 'N/A';
            dpnliData.piezassolicitadas = dpnli.L_mite_Mensual__c != null  && dpnli.Consumido__c != null  ? String.valueOf(dpnli.L_mite_Mensual__c - dpnli.Consumido__c) : dpnli.L_mite_Mensual__c != null ? String.valueOf(dpnli.L_mite_Mensual__c) : 'N/A';
            dpnliData.entransito = oliProductQtyMap.containsKey(dpnli.Product__c) ? String.valueOf(oliProductQtyMap.get(dpnli.Product__c)) : 'N/A';
            dpnliData.existenciaumu = 'N/A';
            dpnliData.existenciacenadi = 'N/A';
            for(DataDeSKUsWrapper skuInfo : skuInfoList){
                if(skuInfo.sku == dpnli.Product__r.Product_Code_ID__c){
                    dpnliData.existenciacenadi = skuInfo.availability != null ? String.valueOf(skuInfo.availability) : 'N/A';
                }
            } 
            dataDeOliList.add(dpnliData);
        } 
        return JSON.serialize(dataDeOliList);
    } 

    @AuraEnabled
    public static Pedido__c updateTipoDePedido(Id pedidoId, String tipoDePedido){
        List<Id> pedidoIdList = new List<Id>{pedidoId}; 
        List<Pedido__c> pedidosList = MisPedidosClass.pedidosQuery(null, null, null, null, null, pedidoIdList, null); 
        if(pedidosList.isEmpty()){
            return null; 
        } 
        Pedido__c pedidoToUpdate = pedidosList[0]; 
        pedidoToUpdate.Tipo_de_Pedido__c = tipoDePedido;
        update pedidoToUpdate;

        return pedidoToUpdate;
    } 
}