public without sharing class controladorGeneracionPedidos {

    private static final String ESTATUS_ACTIVO = 'Activo'; 
    private static final String ESTATUS_VERIFICANDO = 'Verificando Disponibilidad'; 
    private static final String ESTATUS_PROCESANDO = 'Procesando'; 

    public class Ordenes_Line_Item{
        @AuraEnabled
        public Id insumoId;
        @AuraEnabled
        public Integer CantidadSolicitada;
    }

    public class Orden{
        @AuraEnabled
        public Id Idcontacto;
        @AuraEnabled
        public Id IdUmu;
        @AuraEnabled
        public String TipoDePedido;
        @AuraEnabled
        public Date fechaMaxima;
        @AuraEnabled
        public Boolean esPrograma;
        @AuraEnabled
        public String numeroOficio;
        @AuraEnabled
        public String justificacion;
        @AuraEnabled
        public List<Ordenes_Line_Item> ordenesDetails;
    }

    @AuraEnabled
    public static List<Order__c> deserializeOrders(String payload){
        List<Orden> orders = (List<Orden>)JSON.deserialize(payload, List<Orden>.class);
        system.debug('Orden: ' + orders);
        List<Order__c> orderCreated = createOrders(orders);
        return orderCreated;
    }
    
    public static List<Order__c> createOrders(List<Orden> orders){
        // Insert all order line items 
        String contactId = '';
        String tipoDePedido = '';
        Boolean esPrograma = false;
        Datetime fechaMaxima = null;
        String numeroDeOficio = '';
        String justificacion = '';

        List<Order_Line_Item__c> orderLineItemsList = new List<Order_Line_Item__c>();
        for(Orden order : orders) {
            if(String.isBlank(contactId)){ contactId = order.Idcontacto; }
            if(String.isBlank(tipoDePedido)){ tipoDePedido = order.TipoDePedido; }  
            if(order.numeroOficio != null && String.isBlank(numeroDeOficio)){ numeroDeOficio = order.numeroOficio; }  
            if(order.justificacion != null && String.isBlank(justificacion)){ justificacion = order.justificacion; }
            if(!esPrograma && fechaMaxima == null && order.esPrograma != null && order.esPrograma) {
                if(order.TipoDePedido == 'Emergencia Sanitaria' || order.TipoDePedido == 'Programa') {
                    fechaMaxima = order.fechaMaxima;
                }
                esPrograma = order.esPrograma;
            } 

            for(Ordenes_Line_Item ordenes: order.ordenesDetails){
                Order_Line_Item__c ordenItem = new Order_Line_Item__c(
                    Product__c = ordenes.insumoId,
                    Cantidad_Solicitada__c = ordenes.CantidadSolicitada, 
                    UMU__c = order.IdUmu
                );
                orderLineItemsList.add(ordenItem);
            }
        }

        try {
            insert orderLineItemsList;
        } catch (DmlException e) {
            System.debug('An error occurred during the insert operation: ' + e.getMessage());
            return null;
        }

        // Get the inserted olis with all the required information
        Set<Id> oliIdsSet = new Set<Id>();
        for(Order_Line_Item__c oli : orderLineItemsList) {
            oliIdsSet.add(oli.Id);
        }
        List<Order_Line_Item__c> queriedOLIList = [
            SELECT Id, Name, Order__c, UMU__c, Pedido__c, Numero_de_Subalmacen__c, Order_Line_Item_Classification__c 
            FROM Order_Line_Item__c 
            WHERE Id IN: oliIdsSet
        ];
        if(queriedOLIList.isEmpty()){ return null; }

        // Set umu-id - order line item & classification maps
        Map<Id, List<Order_Line_Item__c>> olisByUmuIdMap = new Map<Id, List<Order_Line_Item__c>>();
        Map<Id, Set<Integer>> umuIdsBySubalmacenMap = new Map<Id, Set<Integer>>();
        for(Order_Line_Item__c oli : queriedOLIList){
            if(!olisByUmuIdMap.containsKey(oli.UMU__c)){
                olisByUmuIdMap.put(oli.UMU__c, new List<Order_Line_Item__c>());
            }
            olisByUmuIdMap.get(oli.UMU__c).add(oli);

            if(!umuIdsBySubalmacenMap.containsKey(oli.UMU__c)){
                umuIdsBySubalmacenMap.put(oli.UMU__c, new Set<Integer>());
            }
            umuIdsBySubalmacenMap.get(oli.UMU__c).add(Integer.valueOf(oli.Numero_de_Subalmacen__c));
        }

        List<Pedido__c> pedidoListToInsert = new List<Pedido__c>();
        for(Id umuId : olisByUmuIdMap.keySet()){
            Pedido__c pedidoRec = new Pedido__c(
                UMU__c = umuId,
                Creado_Por__c = contactId,
                Es_Programa__c = esPrograma,
                Tipo_de_Pedido__c = tipoDePedido,
                Numero_de_Oficio__c = numeroDeOficio,
                Justificacion__c = justificacion
            );
            pedidoListToInsert.add(pedidoRec);
        }
        try {
            insert pedidoListToInsert;
        } catch (DmlException e) {
            System.debug('An error occurred during the insert operation: ' + e.getMessage());
            return null;
        }

        Set<Id> pedidoIdsSet = new Set<Id>();
        for(Pedido__c pedido : pedidoListToInsert) {
            pedidoIdsSet.add(pedido.Id);
        }

        List<Pedido__c> pedidosToUpdateList = getFechaMaximaDeEntrega(esPrograma, tipoDePedido, pedidoIdsSet);
        if(!pedidosToUpdateList.isEmpty()){
            try {
                update pedidosToUpdateList;
            } catch (DmlException e) {
                System.debug('An error occurred during the insert operation: ' + e.getMessage());
                return null;
            }
        }

        List<Order_Line_Item__c> oliPedidoListToUpdate = new List<Order_Line_Item__c>();
        for(Pedido__c pedido : pedidosToUpdateList){ 
            for(Order_Line_Item__c oli : olisByUmuIdMap.get(pedido.UMU__c)){
                oli.Pedido__c = pedido.Id;
                oliPedidoListToUpdate.add(oli);
            } 
        }
        try {
            update oliPedidoListToUpdate;
        } catch (DmlException e) {
            System.debug('An error occurred during the insert operation: ' + e.getMessage());
            return null;
        }

        // Insert sorted order list
        List<Order__c> orderListToInsert = new List<Order__c>();
        for(Id umuId : umuIdsBySubalmacenMap.keySet()){
            if(umuId == null){
                continue;
            }

            for(Integer sub : umuIdsBySubalmacenMap.get(umuId)){
                Order__c orderRec = new Order__c(
                    Contacto__c = contactId,
                    Order_Number__c = String.valueOf(sub),
                    UMU__c = umuId,
                    Tipo_de_Pedido__c = tipoDePedido,
                    Estatus__c = ESTATUS_PROCESANDO,
                    Seguimiento__c = JSON.serialize(new Map<String, String>{ ESTATUS_PROCESANDO => 'Fecha:' + String.valueOf(Datetime.now()) })
                );

                if(esPrograma) {
                    if(tipoDePedido == 'Emergencia Sanitaria' || tipoDePedido == 'Programa') {
                        orderRec.Fecha_Limite_de_Entrega__c = fechaMaxima;
                    } 
                    orderRec.Es_Programa__c = esPrograma;
                } else {
                    if(tipoDePedido != 'Ordinario'){
                        orderRec.Numero_de_Oficio__c = numeroDeOficio;
                        orderRec.Motivo__c = justificacion;
                    }
                } 

                orderListToInsert.add(orderRec);
            }
        }

        try {
            insert orderListToInsert;
        } catch (DmlException e) {
            System.debug('An error occurred during the insert operation: ' + e.getMessage());
            return null;
        }

        // Get the inserted orders with all the required information (folio)
        Set<Id> orderIdsSet = new Set<Id>();
        for(Order__c ord : orderListToInsert) {
            orderIdsSet.add(ord.Id);
        }
        List<Order__c> queriedOrderList = [
            SELECT Id, Name, UMU__c, Pedido__c, Order_Number__c, Folio_del_Pedido__c, Numero_de_Subalmacen__c
            FROM Order__c 
            WHERE Id IN: orderIdsSet
        ];

        // Match inserted order line items with their respective classified order 
        Map<Id, Order__c> updateOrderMap = new Map<Id, Order__c>();
        List<Order_Line_Item__c> oliListToUpdate = new List<Order_Line_Item__c>(); 
        for(Order_Line_Item__c oli : queriedOLIList){ 
            for(Order__c ord : queriedOrderList){
                if(ord.UMU__c == oli.UMU__c && Integer.valueOf(ord.Order_Number__c) == Integer.valueOf(oli.Numero_de_Subalmacen__c)){
                    oli.Order__c = ord.Id;
                    oliListToUpdate.add(oli);
                } 

                if(!updateOrderMap.containsKey(ord.Id) && ord.Pedido__c == null && oli.Pedido__c != null && ord.UMU__c == oli.UMU__c){
                    ord.Pedido__c = oli.Pedido__c; 
                    updateOrderMap.put(ord.Id, ord);
                }
            } 
        } 

        try {
            update updateOrderMap.values();
        } catch (DmlException e) {
            System.debug('An error occurred during the update operation: ' + e.getMessage());
            return null;
        } 

        try {
            update oliListToUpdate;
        } catch (DmlException e) {
            System.debug('An error occurred during the update operation: ' + e.getMessage());
            return null;
        } 

        List<Order__c> orderListToUpdate = new List<Order__c>();      
        for(Order__c ord : queriedOrderList){
            if(ord.Order_Number__c != null && ord.Folio_del_Pedido__c != null){ 
                ord.Order_Number__c = ord.Order_Number__c + '-' + ord.Folio_del_Pedido__c; 
                orderListToUpdate.add(ord);
            }
        }
        try {
            update orderListToUpdate;
        } catch (DmlException e) {
            System.debug('An error occurred during the update operation: ' + e.getMessage());
            return null;
        } 
        
        List<Order__c> orderList = [
            SELECT Id, Name, UMU__c, Pedido__c, Order_Number__c, Folio_del_Pedido__c, Tipo_de_Pedido__c, Contacto__r.Name,
                Pedido__r.Folio_de_Pedido__c, Pedido__r.Fecha_Limite_de_Entrega__c, Pedido__r.ID_de_Pedido__c
            FROM Order__c 
            WHERE Id IN: orderIdsSet
        ];

        return orderList;
    }

    public static List<Pedido__c> getFechaMaximaDeEntrega(Boolean esPrograma, String tipoDePedido, Set<Id> pedidoIdsSet){

        List<Pedido__c> pedidosToUpdate = new List<Pedido__c>();

        Datetime currentDatetime = Datetime.now();

        Boolean esProgramaEmergenciaSanitaria = false;
        if(esPrograma && (tipoDePedido == 'Programa' || tipoDePedido == 'Emergencia Sanitaria')){
            esProgramaEmergenciaSanitaria = true;
        }
        if(esProgramaEmergenciaSanitaria){return pedidosToUpdate;}

        List<Pedido__c> pedidoList = [
            SELECT Id, UMU__c, UMU__r.Estado__c
            FROM Pedido__c 
            WHERE Id IN: pedidoIdsSet
        ];

        Map<Id, Datetime> umuPedidoMap = new Map<Id, Datetime>();
        if(tipoDePedido == 'Ordinario'){

            Set<Id> umuIds = new Set<Id>();
            for(Pedido__c umusDePedido : pedidoList){
                umuIds.add(umusDePedido.UMU__c);
            }

            List<Pedido__c> pedidosOrdinariosList = [
                SELECT Id, UMU__c, Tipo_de_Pedido__c, Fecha_Limite_de_Entrega__c, CreatedDate
                FROM Pedido__c
                WHERE Tipo_de_Pedido__c = 'Ordinario' 
                    AND Fecha_Limite_de_Entrega__c >=: currentDatetime
                    AND UMU__c IN: umuIds
                ORDER BY Fecha_Limite_de_Entrega__c DESC
            ]; 

            for(Pedido__c pedido : pedidosOrdinariosList){
                umuPedidoMap.put(pedido.UMU__c, pedido.Fecha_Limite_de_Entrega__c);
            } 
        }


        for(Pedido__c pedido : pedidoList){

            Boolean isRestoDelPais = true;

            String estado = pedido.UMU__r.Estado__c;
            if(String.isBlank(estado)){ continue; } 

            estado = estado.toLowerCase().replaceAll('[àáâäãåā]', 'a').replaceAll('[èéêëēėę]', 'e').replaceAll('[ìíîïī]', 'i').replaceAll('[òóôöõøō]', 'o').replaceAll('[ùúûüū]', 'u').replaceAll('[çč]', 'c').replaceAll('[ñ]', 'n').toUpperCase();
            if (estado == 'CIUDAD DE MEXICO' || estado == 'ESTADO DE MEXICO') { isRestoDelPais = false; }

            switch on tipoDePedido {
                when 'Urgencia Médica' {
                    // Get fecha max | CDMX + EdoMex = 12hr | Resto = 24 hrs 
                    Datetime dateTimeLimiteDeEntrega = isRestoDelPais ? currentDateTime.addHours(24) : currentDateTime.addHours(12);
                    pedido.Fecha_Limite_de_Entrega__c = dateTimeLimiteDeEntrega;
                }
                when 'Soporte de Vida' {
                    // Get fecha max | CDMX + EdoMex = 4hr | Resto = 8hrs
                    Datetime dateTimeLimiteDeEntrega = isRestoDelPais ? currentDateTime.addHours(8) : currentDateTime.addHours(4);
                    pedido.Fecha_Limite_de_Entrega__c = dateTimeLimiteDeEntrega; 
                }
                when 'Extraordinario' {
                    pedido.Fecha_Limite_de_Entrega__c = umuPedidoMap.containsKey(pedido.UMU__c) ? umuPedidoMap.get(pedido.UMU__c) : currentDatetime.addDays(10);
                }
                when 'Ordinario' {
                    Datetime dateTimeLimiteDeEntrega = isRestoDelPais ? calcularFechaHabil(currentDateTime, 5) : calcularFechaHabil(currentDateTime, 3);
                    pedido.Fecha_Limite_de_Entrega__c = dateTimeLimiteDeEntrega; 
                }
                when else {
                    System.debug('ERROR: El pedido no es corresponde a ninguna opción válida');
                }
            }
            pedidosToUpdate.add(pedido);
        }
        return pedidosToUpdate;
    }

    public static Datetime calcularFechaHabil(Datetime fechaDeCreacion, Integer diasHabiles){        
        // Calculate the date 3 business days in the future
        Integer businessDaysToAdd = diasHabiles;
        Datetime futureDate = fechaDeCreacion;
        while (businessDaysToAdd > 0) {
            // Add one day to the date
            futureDate = futureDate.addDays(1);

            // Convert the date to a datetime with a default time of midnight
            Datetime futureDateTime = Datetime.newInstance(futureDate.year(), futureDate.month(), futureDate.day());

            // Check if the day is a weekend (Saturday or Sunday)
            if (futureDateTime.format('E') != 'Sat' && futureDateTime.format('E') != 'Sun') {
                // Decrease the number of business days to add
                businessDaysToAdd--;
            }
        }

        // Return the resulting date
        return futureDate;
    }

    public static Integer getInfoClavesDPNActiva(Id umuId, Id productId, Boolean isLimiteMensual){  
        Integer quantity = 0;
        String dpnRecordId = null;

        List<DPN__c> dpnList = [
            SELECT Id
            FROM DPN__c
            WHERE Account__c =: umuId
                AND Estatus__c =: ESTATUS_ACTIVO
            LIMIT 1
        ];

        if(!dpnList.isEmpty()){
            dpnRecordId = dpnList[0].Id;
        } else{
            return quantity;
        }

        String query = 'SELECT L_mite_Mensual__c, Consumido__c FROM DPN_Line_Item__c WHERE DPN__c =: dpnRecordId AND Product__c =: productId LIMIT 1';
        List<DPN_Line_Item__c> dpnLNIDataList = Database.query(query);

        if(dpnLNIDataList.size() == 1){
            DPN_Line_Item__c dpnLineItem = dpnLNIDataList[0];
            quantity = isLimiteMensual ? Integer.valueOf(dpnLineItem.L_mite_Mensual__c) : Integer.valueOf(dpnLineItem.Consumido__c);
        } 
        return quantity;
    }

    public static Date getUltimaFechaActivaDPN(Id umuId, Boolean isUltimaFecha){  
        Date ultimaFechaActiva = Date.today();

        List<DPN__c> dpnList = [
            SELECT Id, Name, Estatus__c, Account__c
            FROM DPN__c
            WHERE Account__c =: umuId
                AND Estatus__c =: ESTATUS_ACTIVO
        ];

        if(dpnList.size() != 1){
            return ultimaFechaActiva;
        }

        Id dpnRecordId = dpnList[0].Id;
        String query = 'SELECT Id, Name, Fecha__c FROM D_a_de_Pedido__c WHERE DPN__c =: dpnRecordId';
        if(isUltimaFecha){
            query += ' AND Fecha__c <= TODAY ORDER BY Fecha__c DESC LIMIT 1';
        } else{
            query += ' AND Fecha__c >= TODAY ORDER BY Fecha__c ASC LIMIT 1';
        }

        List<D_a_de_Pedido__c> fechaDeValidacion = Database.query(query);

        if(fechaDeValidacion.size() == 1){
            ultimaFechaActiva = fechaDeValidacion[0].Fecha__c;
        } 
        return ultimaFechaActiva;
    }

   /* @testVisible
    public static Map<Id, List<Order_Line_Item__c>> getOrderLineItems(Set<String> orderIds) {
        Map<Id, List<Order_Line_Item__c>> orderLineItemsMap = new Map<Id, List<Order_Line_Item__c>>();
        List<Order_Line_Item__c> orderLineItems = [SELECT Id, Order__c, Product__c, Numero_de_Subalmacen__c, UMU__c
                                                   FROM Order_Line_Item__c
                                                   WHERE Order__c IN :orderIds];

        for (Order_Line_Item__c item : orderLineItems) {
            if (!orderLineItemsMap.containsKey(item.UMU__c)) {
                orderLineItemsMap.put(item.UMU__c, new List<Order_Line_Item__c>());
            }

            orderLineItemsMap.get(item.UMU__c).add(item);
        }

        return orderLineItemsMap;
    }

    @Future(callout=true)
    @AuraEnabled
    public static void generatePdfFiles(List<String> orderIds){

        List<Order__c> orders = [
            SELECT Id, UMU__c, Order_Number__c, Es_Programa__c, Tipo_de_Pedido__c, ID_de_Pedido__c, 
                Estatus__c, Pedido__c, Pedido__r.Id, Contacto__r.Email
			FROM Order__c
            WHERE Id IN :orderIds
            ORDER BY Pedido__c
        ];

        Set<String> orderIdsSet = new Set<String>(orderIds);
        Map<Id, List<Order_Line_Item__c>> orderLineItemsMap = getOrderLineItems(orderIdsSet);

        Account umuItem = new Account();

        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<Id> contentVersionsToDelete = new List<Id>();
        Map<String, List<ContentVersion>> contentVersionMap = new Map<String, List<ContentVersion>>();

        Map<String, String> umuEmailMap = new Map<String, String>();
        Map<String, String> subalmacenEmailMap = new Map<String, String>();
        String idsParameters;
        List<String> productList = new List<String>();
        List<String> allProductList = new List<String>();

        system.debug('orderLineItemsMap: ' + orderLineItemsMap);

        // Map<Id, ContentVersion> productCSVMap = new Map<Id, ContentVersion>();

        Set<Id> pedidoWithCSV = new Set<Id>();

        for(Id key : orderLineItemsMap.keySet()) {
            List<Order_Line_Item__c> itemList = orderLineItemsMap.get(key);
            system.debug('itemList: ' + itemList);
            Boolean evaluate = true;
            allProductList.clear();
            productList.clear();

            for(Order__c order : orders) {
                List<Id> productIds = new List<Id>();
                String subalmacen = '';

                for(Order_Line_Item__c item : itemList) {
                    if(evaluate) { allProductList.add(item.Id); }

                    if(order.Id == item.Order__c) {
                        productIds.add(item.Product__c);
                        productList.add(item.Id);
                        if(subalmacen == '') { subalmacen = String.valueOf(item.Numero_de_Subalmacen__c); }
                    }
                }

                evaluate = false;

                if(subalmacen != '') {
                    umuItem = [
                        SELECT Id, Name, Clave_Presupuestal__c
                        FROM Account
                        WHERE Id = : order.UMU__c LIMIT 1
                    ];

                    system.debug('umuItem: ' + umuItem);
                    system.debug('subalmacen: ' + subalmacen);
                    system.debug('productIds: ' + productIds);

                    List<ContentVersion> subalmacenContentVersions = new List<ContentVersion>();
                    idsParameters = String.join(productIds, ',');

                    Subalmacen__c subalmacenEmail = [SELECT Email__c FROM Subalmacen__c WHERE Numero_de_Subalmacen__c = :subalmacen LIMIT 1];
                    subalmacenEmailMap.put(subalmacen, subalmacenEmail.Email__c);

                    Pagereference pageRef = new Pagereference('/apex/confirmacionDePedido?id=' + order.Id + '&idsubalmacen=' + subalmacen + '&listaProductos=' + idsParameters);
                    Blob contentBlob = pageRef.getContentAsPDF();


                    ContentVersion contentVersion = null;
                    String newContentTitle = subalmacen + ' - Confirmacion De Pedido PDF.pdf';
                    String newContentPath = 'ConfirmacionDePedido.pdf';

                    List<ContentVersion> existingContentVersions = [
                        SELECT Id, Title, PathOnClient, VersionData, IsMajorVersion, ContentDocumentId
                        FROM ContentVersion
                        WHERE FirstPublishLocationId = :order.Id AND Title =: newContentTitle
                    ];

                    Map<String, ContentVersion> existingContentMap = new Map<String, ContentVersion>();
                    for (ContentVersion cv : existingContentVersions) {
                        existingContentMap.put(cv.Title, cv);

                        ContentDocument contentDocument = [
                            SELECT Id FROM ContentDocument
                            WHERE Id =: cv.ContentDocumentId
                        ];
                        contentVersionsToDelete.add(contentDocument.Id);
                    }

                    if (existingContentMap.containsKey(newContentTitle)) {
                        // Si el archivo ya existe, actualizamos su versión
                        contentVersion = existingContentMap.get(newContentTitle);
                        // String contentVersionId = contentVersion.Id; // Obtener el ID de la ContentVersion existente
                        system.debug('existingContentMap: ' + existingContentMap);
                        //system.debug('contentVersionId: ' + contentVersionId);

                        if(contentVersion.IsMajorVersion) {
                            system.debug('IsMajorVersion');
                            contentVersion = new ContentVersion();
                            contentVersion.VersionData = contentBlob;
                            contentVersion.Title = newContentTitle;
                            contentVersion.PathOnClient = newContentPath;
                            contentVersion.FirstPublishLocationId = order.Id;
                        }

                    } else {
                        // Si el archivo no existe, creamos una nueva versión
                        system.debug('No new: ');
                        contentVersion = new ContentVersion();
                        contentVersion.VersionData = contentBlob;
                        contentVersion.Title = newContentTitle;
                        contentVersion.PathOnClient = newContentPath;
                        contentVersion.FirstPublishLocationId = order.Id;
                    }
                    
                    contentVersionList.add(contentVersion);
                    subalmacenContentVersions.add(contentVersion);

                    System.debug('Inside second for');

                    if(!pedidoWithCSV.contains(order.Pedido__r.Id) && order.Estatus__c == 'Verificando Disponibilidad') {
                        ContentVersion content = createCSVFiles(allProductList, true);
                        contentVersionList.add(content); 
                        pedidoWithCSV.add(order.Pedido__r.Id);
                    }

                    if(!contentVersionMap.containsKey(key)) {
                        contentVersionMap.put(key, new List<ContentVersion>());
                    }
                    contentVersionMap.get(key).addAll(subalmacenContentVersions);

                    String umuEmail = [SELECT Id, Email__c FROM Account WHERE Id = :order.UMU__c LIMIT 1].Email__c;
                    if(!umuEmailMap.containsKey(key)) {
                        umuEmailMap.put(key, umuEmail);
                    }

                    system.debug('');
                    system.debug('subalmacen: ' + subalmacen);
                    system.debug('idsParameters: ' + idsParameters);
                    system.debug('contentVersionList: ' + contentVersionList);
                    system.debug('contentVersionMap: ' + contentVersionMap);
                    system.debug('umuEmailMap: ' + umuEmailMap);
                }
            }

            system.debug('---> allProducts: ' + allProductList);

            if(contentVersionMap.containsKey(key)) {
                List<contentVersion> csvContentList = new  List<contentVersion>();
                csvContentList.add(createCSVFiles(allProductList, false));
                contentVersionMap.get(key).addAll(csvContentList);
            }
        }

        for(contentVersion key: contentVersionList) {
            System.debug('-----Key: ' + key);
        }

        try {
            insert contentVersionList;

            if(orders.get(0).Estatus__c == 'Enviado') {
                system.debug('Deleting...');
                Database.delete(contentVersionsToDelete);

                for(String key : umuEmailMap.keySet()) {
                    List<contentVersion> cvList = contentVersionMap.get(key);
                    Account umu = [
                        SELECT Id, Name, Clave_Presupuestal__c
                        FROM Account
                        WHERE Id = : key LIMIT 1
                    ];

                    if(cvList.size() > 0) {
                        String umuEmail = umuEmailMap.get(key);
                        if(orders.get(0).Es_Programa__c != true) {
                            SendEmail.sendEmailWithAttachments(cvList, umuEmail);
                        } else {
                            SendEmail.sendTemplateEmailWithAttachments(cvList, umuEmail, orders.get(0), umu);
                        }
                    }
                }
            }
            //return contentVersionList;
        } catch (DmlException error) {
            System.debug('An erros has ocurred: ' + error.getMessage());
            //return null;
        }
    } */

    @AuraEnabled
    public static ContentVersion createContentVersion(String title, String versionData, String pathOnClient, String contactId,
                                                      String orderId, String programName, String summaryJson) {
        Contact contact = [SELECT Id, Name, Email FROM Contact WHERE Id = :contactId];
        Order__c order = [SELECT Id, ID_de_Pedido__c, Tipo_de_Pedido__c, Fecha_de_Creacion__c, Pedido__r.ID_de_Pedido__c FROM Order__c WHERE Id = :orderId];

        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = title;
        contentVersion.VersionData = EncodingUtil.base64Decode(versionData);
        contentVersion.PathOnClient = pathOnClient;
        contentVersionList.add(contentVersion);

        try {
            System.debug(summaryJson);
            System.debug(programName);
            insert contentVersionList;
            if(!Test.isRunningTest()) {
                SendEmail.sendProgramEmailWithAttachments(contentVersionList, contact.Email, summaryJson, order, programName);
            }
            return contentVersion;
        } catch (Exception e) {
            System.debug('An error occurred while creating ContentVersion: ' + e.getMessage());
            return null;
        }
    }

    public static ContentVersion createCSVFiles(List<String> productList, Boolean csvAttach) {

        List<Order_Line_Item__c> lineItems = [
            SELECT Product__r.Name, Product__r.Product_Code_ID__c, Product__r.Description__c, Cantidad_Solicitada__c,
            Numero_de_Subalmacen__c, Order__c, Product__r.Programa__c
            FROM Order_Line_Item__c WHERE Id IN :productList
        ];

        Set<String> csvRows = new Set<String>();
        List<Order__c> orders = new List<Order__c>();

        if(lineItems.size() > 0) {
            system.debug('CSV');
            system.debug(lineItems);


            Set<Id> orderIds = new Set<Id>();
            for(Order_Line_Item__c item : lineItems) {
                orderIds.add(item.Order__c);
            }
            
            orders = [
                SELECT Id, Name, Pedido__c, Pedido__r.Id, Tipo_de_Pedido__c, Fecha_de_Creacion__c, UMU__c, Estatus__c,
                    Pedido__r.Fecha_Limite_de_Entrega__c, Pedido__r.ID_de_Pedido__c, Order_Number__c,
                    Pedido__r.Folio_de_Pedido__c
                FROM Order__c
                WHERE Id IN :orderIds
            ];

            Account umu = [
                SELECT Id, Name, Clave_Presupuestal__c, Delegaci_n__c, UMU__c
                FROM Account
                WHERE Id = :orders.get(0).UMU__c LIMIT 1
            ];
            system.debug(umu);

            Datetime dateField;
            String dateFormatted;
            String deliveryName, deliveryLargeName, deliveryShortName ;
            
            for(Order__c order : orders) {
                for (Order_Line_Item__c item : lineItems) {
                    if(order.Id == item.Order__c) {
                        if(order.Tipo_de_Pedido__c == 'Emergencia Sanitaria' || order.Tipo_de_Pedido__c == 'Programa') {
                            dateField = order.Pedido__r.Fecha_Limite_de_Entrega__c;
                        } else {
                            dateField = order.Pedido__r.Fecha_Limite_de_Entrega__c;
                        }
                        dateFormatted = dateField.format('yyyy-MM-dd');
                        deliveryName = order.Order_Number__c;
                        deliveryLargeName = deliveryName.substringAfter('-');
                        
                        if (deliveryLargeName.length() < 7) {
                            deliveryShortName = deliveryLargeName;
                        } else {
                            deliveryShortName = deliveryLargeName.substring(deliveryLargeName.length() - 7);
                        }
                        
                        csvRows.add(umu.Delegaci_n__c + ',' + '\'' + umu.UMU__c + ',' + '\'' + umu.Clave_Presupuestal__c
                        + ',' + umu.Name + ',' + order.Tipo_de_Pedido__c + ',' + '\'' + order.Pedido__r.ID_de_Pedido__c
                        + ',' + '\'' + order.Pedido__r.ID_de_Pedido__c + ',' + '\'' + deliveryShortName + ',' + '\'' + deliveryLargeName
                        + ',' + item.Numero_de_Subalmacen__c + ',' + '\'' + item.Product__r.Product_Code_ID__c
                        + ',' + item.Product__r.Description__c + ',' + item.Cantidad_Solicitada__c + ',' + item.Cantidad_Solicitada__c 
                        + ',' + dateFormatted );
                    }
                }
            }
        }

        List<String> csvList = new List<String>(csvRows);

        List<String> headers = new List<String>{'DELEGACION', 'UMU', 'CLAVE PRESUPUESTAL',
        'NOMBRE UMU', 'TIPO DE PEDIDO', 'FOLIO DE SOLICITUD', 'FOLIO DE PEDIDO', 'NUMERO DE REMISION', 'DELIVERY',
        'SUBALMACEN', 'CLAVE', 'DESCRIPCION CLAVE', 'CANTIDAD SOLICITADA', 'CANTIDAD CONFIRMADA', 'FECHA MAXIMA DE ENTREGA'};

        String csvString = String.join(headers, ',') + '\n' + String.join(csvList, '\n');
        Blob contentBlob = Blob.valueOf(csvString);

        String contentDocumentTitle = orders.get(0).Pedido__r.ID_de_Pedido__c + '.csv';
        List<ContentDocument> conDocList = [
            SELECT Id, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Title =: contentDocumentTitle
            LIMIT 1
        ];

        if(conDocList.isEmpty()){
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.VersionData = contentBlob;
            contentVersion.Title = contentDocumentTitle;
            contentVersion.PathOnClient = contentDocumentTitle;
            contentVersion.IsMajorVersion = false;
            if(csvAttach && lineItems.size() > 0) {
                contentVersion.FirstPublishLocationId = String.valueOf(orders.get(0).Pedido__r.Id);
            }
            system.debug('nuevo');
            return contentVersion;
        } else {
            String documentRecord = conDocList[0].LatestPublishedVersionId;
            List<ContentVersion> contentVersion = [
                SELECT Id, VersionData, Title, PathOnClient, FirstPublishLocationId
                FROM ContentVersion 
                WHERE Id =: documentRecord
                LIMIT 1
            ]; 
            contentVersion[0].VersionData = contentBlob;
            system.debug('existente');
            return contentVersion[0];
        }
    }

    @AuraEnabled
    public static void sendEmailSolicitudNoOrd(List<String> orderIds) {
        List<Order__c> orderList = [
            SELECT Pedido__c, Pedido__r.ID_de_Pedido__c
            FROM Order__c
            WHERE Id IN: orderIds
        ];

        Set<Id> pedidoIds = new Set<Id>();
        Set<String> pedidoIdDePedidos = new Set<String>();
        for(Order__c ord : orderList){
            pedidoIds.add(ord.Pedido__c);
            pedidoIdDePedidos.add(ord.Pedido__r.ID_de_Pedido__c);
        }

        if(pedidoIds.isEmpty() || pedidoIdDePedidos.isEmpty()){
            return;
        }

        Id pedidoId = new List<Id>(pedidoIds)[0];
        String idDePedido = new List<String>(pedidoIdDePedidos)[0];

        List<Order_Line_Item__c> oliList = [
            SELECT Id, Product__c, Order__c, Pedido__c
            FROM Order_Line_Item__c
            WHERE Pedido__c = :pedidoId
        ];
        
        List<Id> productIds = new List<Id>();
        for(Order_Line_Item__c oli : oliList){
            productIds.add(oli.Product__c);
        }
        String idsParameters = String.join(productIds, ',');

        Id contactId = UserContactClass.getContactIdFromUser(); 
        List<Contact> con = [
            SELECT Id, Email
            FROM Contact
            WHERE Id =: contactId
            LIMIT 1
        ];
        if(con.IsEmpty() || con.size() != 1 || String.isEmpty(con[0].Email)){
            return;
        }
        String contactEmail = con[0].Email;
        List<String> emailAddresses = new List<String>{contactEmail}; 
        
        Pagereference pageRef = new Pagereference('/apex/SolicitudDePedido?id=' + pedidoId + '&listaProductos=' + idsParameters);
        Blob contentBlob = pageRef.getContentAsPDF();

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.VersionData = contentBlob;
        contentVersion.Title = idDePedido + '.pdf';
        contentVersion.PathOnClient = idDePedido + '.pdf';
        insert contentVersion;

        List<String> conVerList = new List<String>{contentVersion.Id};
        
        EmailTemplate et = [
            SELECT Id, Subject, Body 
            FROM EmailTemplate 
            WHERE DeveloperName = 'Solicitud'
        ];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(et.Id);
        mail.setToAddresses(emailAddresses);
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

    @testVisible
    public static Set<Id> getOrderId(List<Order__c> orderList){
        Set<Id> orderIds = new Set<Id>();
        for(Order__c order: orderList){
            orderIds.add(order.Id);
        } 
        return orderIds;
    }
    
    @testVisible 
    public static Map<Decimal, List<Id>> GetSubalmacenFilter(String orderId, Map<Id, List<Order_Line_Item__c>> orderLineItem){
        
        Map<Decimal, List<Id>> subalmacenList = new Map<Decimal, List<Id>>();
        for(Order_Line_Item__c item: orderLineItem.get(orderId)){
            // verificar si no existe el subalmancen y crear una nueva lista con el id del almacen
            if(!subalmacenList.containsKey(item.Numero_de_Subalmacen__c)){
                subalmacenList.put(item.Numero_de_Subalmacen__c, new List<Id>());
            }
            // añadir item a su subalmacen
            subalmacenList.get(item.Numero_de_Subalmacen__c).add(item.Product__c);
        }
        return subalmacenList;
    }
}