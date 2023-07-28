public without sharing class UserContactClass {
    
    private static final String RESPONSABLE_DE_FARMACIA = 'Responsable_de_Farmacia_y_o_Almac_n';
    private static final String ESTATUS_ACTIVO = 'Activo';
    private static final String RDF_MEDICINA = 'MEDICINE';
    private static final String RDF_MATERIAL_DE_CURACION = 'HEALING MATERIAL';
    private static final String URGENCIA_MEDICA = 'Urgencia Médica';
    private static final String SOPORTE_VIDA = 'Soporte de Vida';
    private static final String TIPO_ORDINARIO = 'Ordinario';
    private static final Map<String, String> TIPO_ORDEN_MAP = new Map<String, String>{
        'Soporte de Vida' => 'S-SPUR',
        'Urgencia Médica' => 'S-URGE',
        'Ordinario' => 'S-ORDI',
        'Extraordinario' => 'S-EXTRA',
        'Replaneación' => 'S-REPLA',
        'Emergencia Sanitaria' => 'S-SANI',
        'Programa' => 'S-PROG'
    };

    public static Id getUserId(){  
        try {
            Id currentUserId = UserInfo.getUserId(); 
            return currentUserId;
        } catch(Exception e){
            System.debug(e.getMessage());
            return null;
        }
    } 

    public static Id getContactIdFromUser(){  
        Id currentUserId = getUserId();
        System.debug('currentUserId---> ' + currentUserId);
        try { 
            User currentUser = [
                SELECT ContactId 
                FROM User 
                WHERE Id =: currentUserId 
                LIMIT 1]; 
            System.debug('currentUser---> ' + currentUser);
            return currentUser.ContactId;
        } catch(Exception e){
            System.debug(e.getMessage());
            return null;
        }
    }

    public static Boolean checkIfUserIsResponsableDeFarmaciaAlmacen(){    
        Id userId = getUserId();  
        try {
            List<PermissionSetAssignment> psaList = [
                SELECT PermissionSet.Name
                FROM PermissionSetAssignment
                WHERE AssigneeId =: userId
                    AND PermissionSet.Name =: RESPONSABLE_DE_FARMACIA
            ];
            return !psaList.isEmpty();
        } catch (Exception e) {
            System.debug(e.getMessage());
            return false;
        } 
    }

    public static List<Id> getAccountIdsFromUser(){   
        Id contactId = getContactIdFromUser();    

        List<Id> accountIdList = new List<Id>();
        try {
            List<AccountContactRelation> accountContactList = [
                SELECT AccountId, Account.Name  
                FROM AccountContactRelation 
                WHERE ContactId =: contactId
            ];  
            for(AccountContactRelation accConRel : accountContactList){
                accountIdList.add(accConRel.AccountId);
            }
            return accountIdList;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return accountIdList;
        }
    }

    public static List<Id> getProgramIdsByContact() {
        Id contactId = getContactIdFromUser();
        List<Id> programsIdList = new List<Id>();
        try {
            List<Contactos_y_Programas__c> contactProgramsList = [
                SELECT Id, Contact__c, Programa__c 
                FROM Contactos_y_Programas__c
                WHERE Contact__c = :contactId
            ];
            for(Contactos_y_Programas__c cp : contactProgramsList) {
                programsIdList.add(cp.Programa__c);
            }
            return programsIdList;
        } catch (Exception e) {
            System.debug('Query error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<Account> getAccountListFromUser(){  
        List<Id> accountIdList = getAccountIdsFromUser(); 
        List<Account> accountList = new List<Account>();
        try {
            accountList = [
                SELECT Id, Name, Clave_Presupuestal__c, UMU__c, Tipo_UMU__c, UMU_Cerrada__c, Delegacion__c
                FROM Account 
                WHERE Id IN: accountIdList
            ];  
            return accountList;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return accountList;
        }
    }

    @AuraEnabled(cacheable=true)    
    public static List<DPN_Line_Item__c> getActiveDPNListFromUser(Id accountId){  
        List<DPN_Line_Item__c> dpnLineItem = new List<DPN_Line_Item__c>();

        Boolean userIsResponsableDeFarmacia = checkIfUserIsResponsableDeFarmaciaAlmacen();

        Id contactId = getContactIdFromUser();

        // Obtener DPN relacionada e items 
        List<DPN__c> dpnActivo = [
            SELECT Id, Name 
            FROM DPN__c 
            WHERE Account__c =: accountId
                AND Estatus__c =: ESTATUS_ACTIVO
                LIMIT 1
        ]; 

        if(dpnActivo.size() == 0){
            return dpnLineItem;
        }

        Id dpnActivoId = dpnActivo[0].Id;
        String dpnLineItemQuery = 'SELECT Id, Name, DPN__c, L_mite_Mensual__c, Consumido__c, Product__r.Product_Code_ID__c, Product__r.Description__c, Product__r.Name';
        dpnLineItemQuery += ' FROM DPN_Line_Item__c';
        dpnLineItemQuery += ' WHERE DPN__c =: dpnActivoId AND Activo__c = True'; 
         
        if(userIsResponsableDeFarmacia){ 
            Contact con = [
                SELECT Id, Name, Acceso_a_claves_por_clasificaci_n__c
                FROM Contact
                WHERE Id =: contactId
                    LIMIT 1
            ]; 
            String limiteDeResponsableDeFarmacia = '';
            String accesoaClavesPorClasificacion = con.Acceso_a_claves_por_clasificaci_n__c;
            switch on accesoaClavesPorClasificacion {
                when 'Medicina' {
                    limiteDeResponsableDeFarmacia = RDF_MEDICINA;
                }
                when 'Material de Curación' {
                    limiteDeResponsableDeFarmacia = RDF_MATERIAL_DE_CURACION;
                }
                when else {
                    limiteDeResponsableDeFarmacia = '';
                }
            }
            if(String.isNotBlank(limiteDeResponsableDeFarmacia)){
                dpnLineItemQuery += ' AND Product__r.Simple_Classification__c =: limiteDeResponsableDeFarmacia'; 
            } 
        }

        dpnLineItem = Database.query(dpnLineItemQuery); 
        return dpnLineItem;
    } 
    
    @AuraEnabled(cacheable=true)    
    public static List<DPN_Line_Item__c> getDpnNoOrdinary(){  
        List<DPN_Line_Item__c> dpnLineItem = new List<DPN_Line_Item__c>();

        Boolean userIsResponsableDeFarmacia = checkIfUserIsResponsableDeFarmaciaAlmacen();

        Id contactId = getContactIdFromUser();
        system.DEBUG('User' + contactId);

        // Obtener DPN relacionada e items 
        List<DPN__c> dpnNoOrdinaria = [
            SELECT Id, Name 
            FROM DPN__c 
            WHERE Estatus__c = 'No Ordinario'
            LIMIT 1
        ]; 

        if(dpnNoOrdinaria.size() == 0){
            return dpnLineItem;
        }

        Id dpnNoOrdinariaId = dpnNoOrdinaria[0].Id;
        String dpnLineItemQuery = 'SELECT Id, Name, DPN__c, L_mite_Mensual__c, Consumido__c, Product__r.Product_Code_ID__c, Product__r.Name, Product__r.Description__c';
        dpnLineItemQuery += ' FROM DPN_Line_Item__c';
        dpnLineItemQuery += ' WHERE DPN__c =: dpnNoOrdinariaId AND Activo__c = True'; 
         
        if(userIsResponsableDeFarmacia){ 
            Contact con = [
                SELECT Id, Name, Acceso_a_claves_por_clasificaci_n__c
                FROM Contact
                WHERE Id =: contactId
                    LIMIT 1
            ]; 
            String limiteDeResponsableDeFarmacia = '';
            String accesoaClavesPorClasificacion = con.Acceso_a_claves_por_clasificaci_n__c;
            switch on accesoaClavesPorClasificacion {
                when 'Medicina' {
                    limiteDeResponsableDeFarmacia = RDF_MEDICINA;
                }
                when 'Material de Curación' {
                    limiteDeResponsableDeFarmacia = RDF_MATERIAL_DE_CURACION;
                }
                when else {
                    limiteDeResponsableDeFarmacia = '';
                }
            }
            if(String.isNotBlank(limiteDeResponsableDeFarmacia)){
                dpnLineItemQuery += ' AND Product__r.Simple_Classification__c =: limiteDeResponsableDeFarmacia'; 
            } 
        }

        dpnLineItem = Database.query(dpnLineItemQuery); 
        return dpnLineItem;
    } 

    @AuraEnabled
    public static String getDisponibilidadSkus2(String jsonData){
        List<String> skus = (List<String>) JSON.deserialize(jsonData, List<String>.class);
        system.debug(JSON.serialize(ServicioPaqueteo.obtenerDisponibilidad(skus)));
        return JSON.serialize(ServicioPaqueteo.obtenerDisponibilidad(skus));
    }
    
    @AuraEnabled
    public static String getDisponibilidadSkus(String jsonData) {
        List<String> skus = (List<String>) JSON.deserialize(jsonData, List<String>.class);
        List<List<String>> skuBatches = splitListIntoBatches(skus, 500); // Dividir en lotes de 500 elementos
        
        List<ServicioPaqueteo.SkuDisponibilidad> result = new List<ServicioPaqueteo.SkuDisponibilidad>();
        
        for (List<String> batch : skuBatches) {
            System.debug(batch);
            List<ServicioPaqueteo.SkuDisponibilidad> batchResult = ServicioPaqueteo.obtenerDisponibilidad(batch);
            result.addAll(batchResult);
        }
        
        system.debug(JSON.serialize(result));
        return JSON.serialize(result);
    }
    
    private static List<List<String>> splitListIntoBatches(List<String> originalList, Integer batchSize) {
        List<List<String>> batches = new List<List<String>>();
        Integer totalElements = originalList.size();
        Integer batchCount = (totalElements + batchSize - 1) / batchSize;
        
        for (Integer i = 0; i < batchCount; i++) {
            Integer startIndex = i * batchSize;
            Integer endIndex = Math.min((i + 1) * batchSize, totalElements); 
            List<String> batch = new List<String>();
            
            for (Integer j = startIndex; j < endIndex; j++) {
                batch.add(originalList[j]);
            }
            
            batches.add(batch);
        }
        return batches;
    }


    @AuraEnabled
    public static String checkGeneracionDePedido(List<String> orderIdList){
        List<Order__c> orderList = [
            SELECT Id, Name, CreatedDate, UMU__c, UMU__r.UMU__c, Pedido__c, Pedido__r.Fecha_Limite_de_Entrega__c, Order_Number__c, 
                Folio_del_Pedido__c, Tipo_de_Pedido__c, Fecha_Limite_de_Entrega__c, Pedido__r.Es_Programa__c, 
                (SELECT CreatedDate, Name, Product__c, Product__r.Product_Code_ID__c, Cantidad_Solicitada__c, Cantidad_Autorizada__c,
                    Order__r.Tipo_de_Pedido__c, Pedido__r.Es_Programa__c, Estatus_Autorizaci_n__c
                 FROM Order_Line_Items__r)
            FROM Order__c 
            WHERE Id IN: orderIdList
        ];
        System.debug(orderList);
        System.debug(orderList.size());

        List<ServicioGeneracionPedido.Envio> enviosList = new List<ServicioGeneracionPedido.Envio>();
        for(Order__c ord : orderList){
            System.debug(validateOrderData(ord));
            if(!validateOrderData(ord)){
                continue;
            }
            
            String tipoPedido = ord.Tipo_de_Pedido__c;
            ServicioGeneracionPedido.Envio envio = new ServicioGeneracionPedido.Envio();
            envio.client_id = ord.Order_Number__c;
            envio.external_id = ord.Order_Number__c;
            envio.document_number = ord.Order_Number__c;
            envio.early_delivery_date = String.valueOf(ord.CreatedDate.addDays(1));
            envio.early_ship_date = String.valueOf(ord.CreatedDate.addDays(1));
            envio.late_delivery_date = String.valueOf(ord.Pedido__r.Fecha_Limite_de_Entrega__c);
            envio.late_ship_date = String.valueOf(ord.Pedido__r.Fecha_Limite_de_Entrega__c);
            envio.remision = ord.Order_Number__c;
            envio.shipment_number = ord.Order_Number__c;
            envio.entered_date = String.valueOf(ord.CreatedDate);
            envio.ship_address = '';
            envio.customer_date = String.valueOf(ord.CreatedDate); 
            envio.customer_number = ord.UMU__r.UMU__c;
            envio.bto_rush = tipoPedido == URGENCIA_MEDICA || tipoPedido == SOPORTE_VIDA ? '1' : '0';
            if (TIPO_ORDEN_MAP.containsKey(tipoPedido)) {
                envio.order_type = TIPO_ORDEN_MAP.get(tipoPedido);
            }

            Integer oliNum = 1;
            List<ServicioGeneracionPedido.Item> itemsList = new List<ServicioGeneracionPedido.Item>();
            for(Order_Line_Item__c oli : ord.Order_Line_Items__r){
                System.debug(validateOLIData(oli, ord));
                if(validateOLIData(oli, ord)){
                    ServicioGeneracionPedido.Item item = new ServicioGeneracionPedido.Item();
                    item.order_line = String.valueOf(oliNum);
                    item.entered_date = String.valueOf(ord.CreatedDate);
                    item.product_number = oli.Product__r.Product_Code_ID__c;
                    item.ordered_quantity = oli.Pedido__r.Es_Programa__c ? String.valueOf(oli.Cantidad_Solicitada__c) 
                        : tipoPedido == TIPO_ORDINARIO ? String.valueOf(oli.Cantidad_Solicitada__c) 
                        : String.valueOf(oli.Cantidad_Autorizada__c);
                    item.partial_flag = '1';
                    item.split_case = '1';
                    item.unit_price = '0';
                    itemsList.add(item);
                    oliNum ++;
                } 
            } 
            envio.items = itemsList;
            enviosList.add(envio);
        }
        return JSON.serialize(ServicioGeneracionPedido.crearPedido(enviosList)); 
    }

    private static Boolean validateOrderData(Order__c ord){
        if(String.isBlank(ord.Order_Number__c)) return false; 
        if(ord.Pedido__r == null || ord.Pedido__r.Fecha_Limite_de_Entrega__c == null) return false;
        if(String.isBlank(ord.Tipo_de_Pedido__c)) return false;
        if(ord.UMU__r == null || ord.UMU__r.UMU__c == null) return false; 
        if(ord.Order_Line_Items__r == null || ord.Order_Line_Items__r.isEmpty()) return false;
        return true;
    }

    private static Boolean validateOLIData(Order_Line_Item__c oli, Order__c ord){
        if(!ord.Pedido__r.Es_Programa__c && ord.Tipo_de_Pedido__c != 'Ordinario'){
            if(oli.Estatus_Autorizaci_n__c != 'Autorizado' && oli.Estatus_Autorizaci_n__c != 'Modificado'){
                return false;
            }
        }
        return true;
    }
}