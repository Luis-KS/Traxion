public with sharing class MisPedidosClass {

    @AuraEnabled
    public static List<Pedido__c> getMisPedidos(Date fechaInicio, Date fechaFin){
        List<Pedido__c> filteredPedidoList = new List<Pedido__c>();
        for (Pedido__c pedido : pedidosQuery(fechaInicio, fechaFin, null, null, null, null, null)) {
            if (hasValidOrder(pedido)) {
                filteredPedidoList.add(pedido);
            }
        }
        return filteredPedidoList;
    }

    public static Boolean hasValidOrder(Pedido__c pedido) {
        for (Order__c ord : pedido.Ordenes__r) { 
            switch on ord.Tipo_de_Pedido__c {
                when 'Ordinario' {		
                    return true; 
                }	
                when 'Extraordinario', 'Soporte de Vida', 'Urgencia Médica', 'Emergencia Sanitaria' {	
                    if(ord.Pedido__r.Es_Programa__c){
                        return true;
                    } else{ 
                        if(pedido.Autorizado_Por__c != null){
                            return true; 
                        }
                    }
                } 
                when 'Programa' {		
                   return true; 
                } 
                when 'Replaneación' {		
                    return true; 
                }
            }
        }
        return false;
    }

    public static List<Pedido__c> pedidosQuery (Date fechaInicio, Date fechaFin, Boolean esPrograma, String tipoDePedidoExcento, 
        String tipoDePedidoNoValido, List<Id> pedidoIdList, List<String> validOptionsToAthorize){

        List<Id> accountIds = UserContactClass.getAccountIdsFromUser();

        String orderQuery = 'SELECT Id, Name, CreatedDate, Tipo_de_Pedido__c, ID_de_Pedido__c, Folio_de_Pedido__c, UMU__c, Pedido_Original__c, ' +
            'Fecha_Limite_de_Entrega__c, Estatus__c, Numero_de_Oficio__c, Mostrar_Envio_a_Autorizacion__c, Mostrar_Autorizacion__c, '+
            'Es_Programa__c, Total_de_Claves__c, Total_de_Piezas__c, Creado_Por__c, Creado_Por__r.Name, Creado_Por__r.Email, ' +
            'Aprobado_Por__c, Aprobado_Por__r.Name, App_Next_Par_Num__c, Auth_Next_Par_Num__c, ' +
            'Autorizado_Por__c, Autorizado_Por__r.Name, UMU__r.Name, UMU__r.Estado__c, UMU__r.Colonia__c, UMU__r.Delegacion__c, ' +
            'UMU__r.Clave_Presupuestal__c, UMU__r.Tipo_UMU__c, UMU__r.UMU__c, ' +

            // Related Order Line Items
            '(SELECT Id, Estatus__c, Cantidad_Solicitada__c, Cantidad_Aprobada__c, Cantidad_de_Piezas__c, Costo_Promedio__c, Costo__c, ' +
                'Estatus_Aprobaci_n__c, Estatus_Autorizaci_n__c, Cantidad_Autorizada__c, Autorizaci_n_Cantidad_Rechazada__c, ' +
                'Motivo_No_Aprobaci_n__c, Motivo_No_Autorizaci_n__c, Pedido__c, Cantidad_Surtida__c, Pedido__r.Es_Programa__c, ' + 
                'Order__r.Estatus__c, ' +
                'Account__r.Name, Account__r.Clave_Presupuestal__c, Account__r.Estado__c, Product__r.Name, Product__r.Product_Code_ID__c, ' +
                'Product__r.Subalmacen__c, Product__r.Subalmacen__r.Name, Product__r.Subalmacen__r.Numero_de_Subalmacen__c, ' +
                'Product__r.Programa__c, Product__r.Programa__r.Inventario__c, Product__r.Programa__r.Programa_ID__c, ' +
                'Product__r.Programa__r.Name, Product__r.Description__c ' +
            'FROM Order_Line_Items__r';
            if(validOptionsToAthorize != null && !validOptionsToAthorize.isEmpty()){
                orderQuery += ' WHERE Estatus_Aprobaci_n__c IN: validOptionsToAthorize), ';
            } else{
                orderQuery += '), ';
            }

            // Related Orders
            orderQuery += '(SELECT Id, Estatus__c, Tipo_de_Pedido__c, Autorizado_Por__c, Pedido__r.Es_Programa__c, ' +
                    'Motivo__c, Numero_de_Oficio__c, Seguimiento__c, Folio_de_Entrega__c, Folio_de_Remision__c ' +
                'FROM Ordenes__r) ' +

        'FROM Pedido__c ';

        if(pedidoIdList != null){
            orderQuery += 'WHERE Id IN: pedidoIdList';
        } else if(accountIds != null){
            orderQuery += 'WHERE UMU__c IN: accountIds';
        } 

        if(fechaInicio != null){
            Datetime dateTimeFechaInicio = DateTime.newInstance(fechaInicio, Time.newInstance(0, 0, 0, 0));
            orderQuery += ' AND CreatedDate >=: dateTimeFechaInicio';
        } 
        if(fechaFin != null){
            Datetime dateTimeFechaFin = DateTime.newInstance(fechaFin, Time.newInstance(23, 59, 59, 0));
            orderQuery += ' AND CreatedDate <=: dateTimeFechaFin';
        }
        if(esPrograma != null){
            orderQuery += ' AND Es_Programa__c = false';
        }
        if(tipoDePedidoExcento != null){
            orderQuery += ' AND Tipo_de_Pedido__c !=: tipoDePedidoExcento';
        }
        if(tipoDePedidoNoValido != null){
            orderQuery += ' AND Tipo_de_Pedido__c !=: tipoDePedidoNoValido';
        }
        
        orderQuery += ' ORDER BY CreatedDate DESC';

        return Database.query(orderQuery); 
    }

    @AuraEnabled
    public static Map<Id, ContentVersion> getOrderEvidence(List<String> orderIdList) {  
        List<ContentDocumentLink> contentDocumentLinkList = [
            SELECT ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN 
                (SELECT Id 
                 FROM Order__c 
                 WHERE Id IN: orderIdList )
                AND LinkedEntity.Type = 'Order__c'
        ];
        
        Set<Id> contentIds = new Set<Id>();
        for (ContentDocumentLink cont : contentDocumentLinkList) {
            contentIds.add(cont.ContentDocumentId);   
        }

        List<String> validImageExtensionList = new List<String>{
            'jpg', 'jpeg', 'png'
        };
        String likeValue = '%evidencia%';
        List<ContentVersion> conVersion = [
            SELECT Id, Title, ContentDocumentId
            FROM ContentVersion 
            WHERE ContentDocumentId IN: contentIds 
                AND FileExtension IN: validImageExtensionList
                AND Title LIKE: likeValue
        ];

        Map<Id, ContentVersion> orderContentMap = new Map<Id, ContentVersion>();
        for (ContentVersion cv : conVersion) {
            orderContentMap.put(cv.ContentDocumentId, cv);
        }
        
        Map<Id, ContentVersion> orderIdContentMap = new Map<Id, ContentVersion>();
        for (ContentDocumentLink cont : contentDocumentLinkList) {
            Id orderId = cont.LinkedEntityId;
            if (orderContentMap.containsKey(cont.ContentDocumentId)) {
                ContentVersion cv = orderContentMap.get(cont.ContentDocumentId);
                orderIdContentMap.put(orderId, cv);
            }
        }
        
        return orderIdContentMap;
    }
    
    @AuraEnabled
    public static List<Order__c> getFilteredOrdersAndOlis(List<String> orderIdList){ 
        List<Order__c> orderList = getOrders(orderIdList);
        Set<String> orderIdSet = new Set<String>();
        Set<String> oliIdSet = new Set<String>();
        for(Order__c ord : orderList){
            for(Order_Line_Item__c oli : ord.Order_Line_Items__r){ 
                if(!oli.Pedido__r.Es_Programa__c && ord.Tipo_de_Pedido__c != 'Ordinario'){
                    if(!(oli.Estatus_Autorizaci_n__c != 'Autorizado' && oli.Estatus_Autorizaci_n__c != 'Modificado')){
                        orderIdSet.add(ord.Id);
                        oliIdSet.add(oli.Id);
                    }
                } else{ 
                    orderIdSet.add(ord.Id);
                    oliIdSet.add(oli.Id);
                }
            }
        }

        String orderQuery = 'SELECT Id, Name, CreatedDate, Fecha_de_Creacion__c, Seguimiento__c, Order_Number__c, Es_Programa__c, ' +
            'Estatus__c, Tipo_de_Pedido__c, Fecha_Limite_de_Entrega__c, Entrega__c, Entrega__r.Name, Aprobado_Por__c, ' +
            'Aprobado_Por__r.Name, Certificado_Por__r.Name, Firmado_Por__r.Name, Contacto__c, Contacto__r.Name, UMU__c, ' +
            'UMU__r.Name, UMU__r.Estado__c, UMU__r.Colonia__c, UMU__r.Delegacion__c, UMU__r.Clave_Presupuestal__c, ' +
            '(SELECT Id, Estatus__c, Cantidad_Solicitada__c, Cantidad_Aprobada__c, Cantidad_Rechazada__c, Cantidad_de_Piezas__c, Estatus_Autorizaci_n__c, ' +
                'Costo__c, Pedido__c, Cantidad_Surtida__c, Costo_Promedio__c, Account__r.Name, Account__r.Clave_Presupuestal__c, Account__r.Estado__c, ' +
                'Product__r.Name, Product__r.Product_Code_ID__c, Product__r.Subalmacen__c, Product__r.Subalmacen__r.Name, ' +
                'Product__r.Subalmacen__r.Numero_de_Subalmacen__c, Product__r.Programa__c, Product__r.Programa__r.Inventario__c, ' +
                'Product__r.Programa__r.Programa_ID__c, Product__r.Programa__r.Name ' +
             'FROM Order_Line_Items__r WHERE Id IN: oliIdSet) ' +
        'FROM Order__c ' + 
        'WHERE Id IN: orderIdSet';
        return Database.query(orderQuery);  
    } 

    private static List<Order__c> getOrders(List<String> orderIdList) {  
        String orderQuery = 'SELECT Id, Name, CreatedDate, Fecha_de_Creacion__c, Seguimiento__c, Order_Number__c, Es_Programa__c, ' +
            'Estatus__c, Tipo_de_Pedido__c, Fecha_Limite_de_Entrega__c, Entrega__c, Entrega__r.Name, Aprobado_Por__c, ' +
            'Aprobado_Por__r.Name, Certificado_Por__r.Name, Firmado_Por__r.Name, Contacto__c, Contacto__r.Name, UMU__c, ' +
            'UMU__r.Name, UMU__r.Estado__c, UMU__r.Colonia__c, UMU__r.Delegacion__c, UMU__r.Clave_Presupuestal__c, ' +
            '(SELECT Id, Estatus__c, Cantidad_Solicitada__c, Cantidad_Aprobada__c, Cantidad_Rechazada__c, Cantidad_de_Piezas__c, Estatus_Autorizaci_n__c, ' +
                'Costo__c, Pedido__c, Cantidad_Surtida__c, Costo_Promedio__c, Account__r.Name, Account__r.Clave_Presupuestal__c, Account__r.Estado__c, ' +
                'Product__r.Name, Product__r.Product_Code_ID__c, Product__r.Subalmacen__c, Product__r.Subalmacen__r.Name, ' +
                'Product__r.Subalmacen__r.Numero_de_Subalmacen__c, Product__r.Programa__c, Product__r.Programa__r.Inventario__c, ' +
                'Product__r.Programa__r.Programa_ID__c, Product__r.Programa__r.Name, Pedido__r.Es_Programa__c ' +
             'FROM Order_Line_Items__r) ' +
        'FROM Order__c ' + 
        'WHERE Id IN: orderIdList';
        return Database.query(orderQuery); 
    }  

    @AuraEnabled
    public static Order__c certificateOrder(String selectedOrderId){  
        List<Order__c> orderToCertificateList = [
            SELECT Id, Order_Number__c, Firmado_Por__c, Estatus__c, Seguimiento__c, Folio_del_Pedido__c, 
                UMU__c, UMU__r.UMU__c, UMU__r.Estado__c, Pedido__c, Pedido__r.Creado_Por__c, 
                Pedido__r.Creado_Por__r.Email
            FROM Order__c
            WHERE Id =: selectedOrderId
            LIMIT 1
        ]; 
        if(orderToCertificateList.isEmpty()){ return null; }

        Id contactId = UserContactClass.getContactIdFromUser(); 

        Order__c orderToCertificate = orderToCertificateList[0];
        orderToCertificate.Firmado_Por__c = contactId;
        orderToCertificate.Estatus__c = 'Certificado';
        update orderToCertificate;

        List<Order__c> orderList = [
            SELECT Id, Order_Number__c
            FROM Order__c
            WHERE Id =: selectedOrderId
        ];

        List<Order_Line_Item__c> oliList = [
            SELECT Id, Product__c, Order__c, Pedido__c
            FROM Order_Line_Item__c
            WHERE Order__c =: selectedOrderId
        ];
        List<Id> productIds = new List<Id>();
        for(Order_Line_Item__c oli : oliList){
            productIds.add(oli.Product__c);
        }
        String idsParameters = String.join(productIds, ',');
        
        
        Pagereference pageRef = new Pagereference('/apex/CertificacionDeOrden?id=' + selectedOrderId + '&listaProductos=' + idsParameters
                                                 + '&firmadoPor=' + contactId);
        Blob contentBlob = Test.isRunningTest() ? Blob.valueOf('UNIT.TEST') : pageRef.getContentAsPDF();

        String certificationTitle = orderToCertificate.UMU__r.UMU__c + '-' + orderToCertificate.UMU__r.Estado__c + '-' +
            orderToCertificate.Folio_del_Pedido__c + '.pdf';

        List<ContentVersion> contentVersionList = new List<ContentVersion>(); 
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.VersionData = contentBlob;
        contentVersion.Title = certificationTitle;
        contentVersion.PathOnClient = certificationTitle;
        contentVersion.FirstPublishLocationId = selectedOrderId; 
        contentVersion.IsMajorVersion = false;
        contentVersionList.add(contentVersion);
        insert contentVersionList;

        List<Order__c> returnOrderToCertificateList = [
            SELECT Id, Contacto__c, Contacto__r.Email, Firmado_Por__c, Estatus__c, Seguimiento__c
            FROM Order__c
            WHERE Id =: orderToCertificate.Id
            LIMIT 1
        ];

        sendEmaiPreAutorizacion(orderList[0].Order_Number__c, contentVersionList[0].Id, contentBlob); 

        return returnOrderToCertificateList[0];
    } 

    @Future(callout=true)
    @AuraEnabled
    public static void sendEmaiPreAutorizacion(String orderNumber, String docId, Blob contentBlob){
        Map<String, String> certificadoMap = new Map<String, String>();
        certificadoMap.put('order_number', orderNumber); 
        certificadoMap.put('document_id', docId); 
        certificadoMap.put('base64', EncodingUtil.base64Encode(contentBlob)); 

        System.debug(EncodingUtil.base64Encode(contentBlob));
        if(!Test.isRunningTest()){
            ServicioCertificacionEntrega.RespuestaTraxionWrapper response = ServicioCertificacionEntrega.obtenerCertificacion(certificadoMap);
            System.debug(response);
        }
    }

    @AuraEnabled
    public static Order__c rejectOrder(String selectedOrderId){

        List<Order__c> orderToRejectList = [
            SELECT Id, Firmado_Por__c, Estatus__c, Seguimiento__c, Pedido__c, Pedido__r.Creado_Por__c, Pedido__r.Creado_Por__r.Email
            FROM Order__c
            WHERE Id =: selectedOrderId
            LIMIT 1
        ]; 
        if(orderToRejectList.isEmpty()){ return null; }

        Order__c orderToReject = orderToRejectList[0]; 

        Map<String, String> seguimientoMap = !String.isBlank(orderToReject.Seguimiento__c) 
            ? (Map<String, String>)JSON.deserialize(orderToReject.Seguimiento__c, Map<String, String>.class) 
            : new Map<String, String>(); 

        for(String key : seguimientoMap.keySet()){
            if(key == 'Procesando' || key == 'Verificando Disponibilidad' || key == 'Preparando Envío'){
                System.debug('Keep this status: ' + key);
            } else{
                seguimientoMap.remove(key);
            }
        }
        orderToReject.Seguimiento__c = JSON.serialize(seguimientoMap);
        orderToReject.Estatus__c = 'Enviado';
        update orderToReject; 

        List<Order__c> orderToReturn = [
            SELECT Id, Firmado_Por__c, Estatus__c, Seguimiento__c, Pedido__c, Pedido__r.Creado_Por__c, Pedido__r.Creado_Por__r.Email
            FROM Order__c
            WHERE Id =: orderToReject.Id
            LIMIT 1
        ];

        return orderToReturn[0];
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
    public static void reenviarOrden(String orderId){ 
        List<String> orderIdList = new List<String>{orderId};
        if(!Test.isRunningTest()){ 
            String response = UserContactClass.checkGeneracionDePedido(orderIdList); 
            if(String.isBlank(response)){
                return;
            }
        }

        List<Order__c> orderList = [
            SELECT Id, Estatus__c
            FROM Order__c
            WHERE Id =: orderId 
            LIMIT 1
        ];

        if(orderList.isEmpty()){
            return;
        }
        Order__c order = orderList[0];
        order.Estatus__c = 'Procesando';
        try{
            update order;
        } catch(Exception e){
            System.debug(e);
            return;
        }
    }
    
}