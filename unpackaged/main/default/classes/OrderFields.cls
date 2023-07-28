public class OrderFields { 
	public static void updateSeguimiento(List<Order__c> newOrderList, Map<Id, Order__c> oldOrderList){
        for(Order__c ord : newOrderList){
            if(Trigger.isUpdate && ord.Estatus__c != null && ord.Estatus__c != oldOrderList.get(ord.Id).Estatus__c){
                if((ord.Estatus__c == 'Error' || ord.Estatus__c == 'Procesando') && !String.isBlank(ord.Seguimiento__c)){
                    String payload = 'Fecha:' + String.valueOf(Datetime.now());
                    Map<String, String> seguimientoMap = new Map<String, String>();
                    seguimientoMap.put(ord.Estatus__c, payload);
                    ord.Seguimiento__c = JSON.serialize(seguimientoMap);
                } else {
                    Map<String, String> seguimientoMap = !String.isBlank(ord.Seguimiento__c) 
                        ? (Map<String, String>)JSON.deserialize(ord.Seguimiento__c, Map<String, String>.class) 
                        : new Map<String, String>();

                    String payload = 'Fecha:' + String.valueOf(Datetime.now());

                    if(ord.Estatus__c == 'En Firma' && oldOrderList.get(ord.Id).Estatus__c == 'Enviado'){
                        List<Contact> contact = [
                            SELECT Id, Name
                            FROM Contact
                            WHERE Id =: ord.Contacto__c
                            LIMIT 1
                        ];

                        if(!contact.isEmpty()){
                            payload += ';Firmado:' + String.valueOf(contact[0].Name);
                        }
                    } 
                    seguimientoMap.put(ord.Estatus__c, payload);
                    ord.Seguimiento__c = JSON.serialize(seguimientoMap);
                } 
            }
        }
    }

    public static void updateDates(List<Order__c> newOrderList, Map<Id, Order__c> oldOrderList) {
        for(Order__c ord : newOrderList) {
            if(Trigger.isUpdate && ord.Estatus__c != null && ord.Estatus__c != oldOrderList.get(ord.Id).Estatus__c) {

                String seguimientoJson = ord.Seguimiento__c;
                Map<String, Object> seguimientoMap = (Map<String, Object>) JSON.deserializeUntyped(seguimientoJson);
                String enFirma = (String) seguimientoMap.get('En Firma');

                if(enFirma != null && enFirma != '') {
                    String enFirmaValue = null;
                    String regexPattern = 'Fecha:(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})';
                    Pattern pattern = Pattern.compile(regexPattern);
                    Matcher matcher = pattern.matcher(enFirma);

                    if (matcher.find()) { enFirmaValue = matcher.group(1); }

                    DateTime enFirmaDatetime;
                    if (enFirmaValue != null) {
                        try {
                            enFirmaDatetime = DateTime.valueOf(enFirmaValue);
                            ord.Fecha_de_certificacion_de_la_remision__c = enFirmaDatetime;
                        } catch (Exception e) {
                            System.debug('Error dentro del try: ' + e.getMessage());
                        }
                    } else {
                        enFirmaDatetime = null;
                    }
                }
            }
        }
    }

    public static void updateContentVersion(List<Order__c> newOrderList, Map<Id, Order__c> oldOrderMap) {
        /*List<String> orderId = new List<String>();
        for(Order__c order : newOrderList) { 
            if(order.Estatus__c == 'Preparando Envío' && oldOrderMap.get(order.Id).Estatus__c == 'Verificando Disponibilidad'){
                orderId.add(order.Id);
                controladorGeneracionPedidos.generatePdfFiles(orderId);
                orderId.clear();
            } else if(order.Estatus__c == 'Enviado' && oldOrderMap.get(order.Id).Estatus__c == 'Preparando Envío' && order.Entrega__c != null) {
                orderId.add(order.Id);
                controladorGeneracionPedidos.generatePdfFiles(orderId);
                orderId.clear();
            }
        }*/
    }

    @future(callout = true)
    public static void confirmOrder(List<String> orderIdList){
        System.debug('Inside confirm order');

        List<Order__c> orderList = [
            SELECT Id, UMU__c, Contacto__c, Pedido__c, Es_Programa__c, Numero_de_Subalmacen__c, Folio_del_Pedido__c, 
                Pedido__r.ID_de_Pedido__c, Contacto__r.Email, Pedido__r.Folio_de_Pedido__c, Tipo_de_Pedido__c,
                (SELECT Id, Order__c, Product__c, Numero_de_Subalmacen__c, UMU__c 
                 FROM Order_Line_Items__r)
            FROM Order__c
            WHERE Id IN: orderIdList
        ];

        Set<Id> umuIds = new Set<Id>();
        Map<Id, Account> idsWithUmusMap = new Map<Id, Account>();
        
        for(Order__c ord: orderList) {
            umuIds.add(ord.UMU__c);
        }

        List<Account> umuList = [
            SELECT Id, Name, Email__c, Clave_Presupuestal__c
            FROM Account WHERE Id IN :umuIds
        ];
        
        for(Account umu : umuList) {
            if(!idsWithUmusMap.containsKey(umu.Id) && umu.Email__c != null) {
                idsWithUmusMap.put(umu.Id, umu);
            }
        }
        
        system.debug('umusMap: ' + idsWithUmusMap);

        Map<Id, List<ContentVersion>> umusWithContentVersionsMap =  new Map<Id, List<ContentVersion>>();
        Map<Id, String> umusWithEmailsMap =  new Map<Id, String>();
        List<ContentVersion> conVerList = new List<ContentVersion>();
        List<ContentVersion> csvConVer = new List<ContentVersion>();
        Map<String, List<String>> oliIdsMap = new Map<String, List<String>>();
        Account umu = new Account();

        for(Order__c ord : orderList){
            // Get ids parameters
            List<Id> productIds = new List<Id>();
            List<String> oliIdList = new List<String>();
            for(Order_Line_Item__c oli: ord.Order_Line_Items__r){
                productIds.add(oli.Product__c);
                oliIdList.add(oli.Id);
            }

            if(ord.Es_Programa__c == true) {
                if(idsWithUmusMap.containsKey(ord.UMU__c)) {
                    umu = idsWithUmusMap.get(ord.UMU__c);
                    system.debug('UMU: ' + umu);
                    if(!umusWithEmailsMap.containsKey(ord.UMU__c)){
                        umusWithEmailsMap.put(ord.UMU__c, umu.Email__c);
                        system.debug('Hi0');
                    }
                }
            }

            if(!oliIdsMap.containsKey(ord.UMU__c)) {
                oliIdsMap.put(ord.UMU__c, oliIdList);
            } else {
                oliIdsMap.get(ord.UMU__c).addAll(oliIdList);
            }

            String idsParameters = String.join(productIds, ',');

            System.debug(ord.Id);
            System.debug(idsParameters);

            // Render PDF with corresponding data 
            Pagereference pageRef = new Pagereference('/apex/ConfirmacionDePedido?id=' + ord.Id);
            Blob contentBlob;
            if (!Test.isRunningTest()) {  
            	contentBlob = pageRef.getContentAsPDF();
            } else {
                // Dummy blob for tessting
                contentBlob = Blob.valueOf('This is a dummy blob.');
            }
            // System.debug(contentBlob);

            String contentDocumentTitle = ord.Numero_de_Subalmacen__c + '_' + ord.Folio_del_Pedido__c + '.pdf';
            List<ContentDocument> conDocList = [
                SELECT Id, LatestPublishedVersionId
                FROM ContentDocument
                WHERE Title =: contentDocumentTitle
                LIMIT 1
            ];
            System.debug(conDocList);
           
            if(conDocList.isEmpty()){
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.VersionData = contentBlob;
                contentVersion.Title = ord.Numero_de_Subalmacen__c + '_' + ord.Folio_del_Pedido__c + '.pdf';
                contentVersion.PathOnClient = ord.Numero_de_Subalmacen__c + '_' + ord.Folio_del_Pedido__c + '.pdf';
                contentVersion.FirstPublishLocationId = ord.Id;
                contentVersion.IsMajorVersion = false;
                conVerList.add(contentVersion); 

                if(!umusWithContentVersionsMap.containsKey(ord.UMU__c)){
                    umusWithContentVersionsMap.put(ord.UMU__c, new List<ContentVersion>());
                }
                umusWithContentVersionsMap.get(ord.UMU__c).add(contentVersion);
            } else{
                String contentVersion = conDocList[0].LatestPublishedVersionId;
                List<ContentVersion> documentRecord = [
                    SELECT Id, VersionData, Title, PathOnClient, FirstPublishLocationId 
                    FROM ContentVersion 
                    WHERE Id =: contentVersion
                    LIMIT 1
                ]; 
                documentRecord[0].VersionData = contentBlob; 
                conVerList.add(documentRecord[0]);

                if(!umusWithContentVersionsMap.containsKey(ord.UMU__c)){
                    umusWithContentVersionsMap.put(ord.UMU__c, new List<ContentVersion>());
                }
                umusWithContentVersionsMap.get(ord.UMU__c).add(documentRecord[0]);
            }
        }
        System.debug(umusWithEmailsMap);

        for(Order__c ord : orderList) {
            for(String key : oliIdsMap.keySet()) {
                if(ord.UMU__c == key) {

                    List<String> oliIds = oliIdsMap.get(key);
                    ContentVersion contentVersionCsv = controladorGeneracionPedidos.createCSVFiles(oliIds, true);
                    conVerList.add(contentVersionCsv);
                    system.debug(contentVersionCsv);

                    if(!umusWithContentVersionsMap.containsKey(key)){
                        umusWithContentVersionsMap.put(key, new List<ContentVersion>());
                        system.debug('Hi3');
                    } else {
                        umusWithContentVersionsMap.get(key).add(contentVersionCsv);
                        system.debug('Hi4');
                    }

                    if(ord.Es_Programa__c == true) {
                    SendEmail.sendTemplateEmailWithAttachments(umusWithContentVersionsMap.get(key), 
                                                               umusWithEmailsMap.get(key), ord,
                                                              idsWithUmusMap.get(key));
                    }
                }
            }
        }

        upsert conVerList;

        if(orderList[0].Es_Programa__c == true) return;

        List<ContentVersion> conVersionList = [
            SELECT Id, Title 
            FROM ContentVersion
            WHERE Id IN: conVerList
        ];

        Map<Id, List<Id>> umusWithContentVersionIdsMap =  new Map<Id, List<Id>>();
        for(Id umuId : umusWithContentVersionsMap.keySet()){
            for(ContentVersion conver : umusWithContentVersionsMap.get(umuId)){
                for(ContentVersion conv : conVersionList){
                    if(conver.Title == conv.Title){
                        if(!umusWithContentVersionIdsMap.containsKey(umuId)){
                            umusWithContentVersionIdsMap.put(umuId, new List<Id>());
                        }
                        umusWithContentVersionIdsMap.get(umuId).add(conv.Id);
                    }
                } 
            } 
        }

        EmailTemplate et;

        if (!Test.isRunningTest()){
            et = [
            SELECT Id, Subject, Body 
            FROM EmailTemplate 
            WHERE DeveloperName = 'Confirmacion_de_Pedido_No_Ordinario'
        ];
        } else{
            et = TestDataFactory.buildTemplate('TestEmailTemplate', '');
        } 

        List<String> contactEmails = new List<String>{
            orderList[0].Contacto__r.Email
        };

        System.debug(orderList[0].Contacto__r.Email);
        System.debug(orderList[0].Contacto__c);
        System.debug(orderList[0].Pedido__c);

        for(Id umuId : umusWithContentVersionIdsMap.keySet()){ 
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(et.Id);
            mail.setToAddresses(contactEmails);
            mail.setTargetObjectId(orderList[0].Contacto__c); 
            mail.setWhatId(orderList[0].Pedido__c); 
            mail.setEntityAttachments(umusWithContentVersionIdsMap.get(umuId)); 
            mail.setSaveAsActivity(false);
            mail.setUseSignature(false);

            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
            mailList.add(mail);

            if(!mailList.isEmpty()){
                Messaging.sendEmail(mailList);
            } 
        }
    }  
}