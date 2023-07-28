public with sharing class InventarioFields {

    public static void updateInventarioFirmado( List<Inventario__c> invList, Map<Id, Inventario__c> oldInvMap ){
        for( Inventario__c inv : invList ){
            System.debug('inv.Estatus__c inv- ' + inv.Estatus__c);
            System.debug('oldInvMap inv- ' + oldInvMap.get(inv.Id).Estatus__c);
            if( inv.Estatus__c == 'Firmado' && oldInvMap.get(inv.Id).Estatus__c == 'En Firma' ){
                inv.Firmado_por__c = UserInfo.getName();
                inv.Signed_Date__c = System.Now();
            }
            System.debug('updateInventarioFirmado inv- ' + inv);
        }
    }

    public static void updateEstatusInventario( List<Inventario__c> invList, Map<Id, Inventario__c> oldInvMap ){
        
        Set<Id> invIdSet = New Set<Id>();
        Map<Id, Date> invFechaMap = New Map<Id, Date>();
        Map<Id, Inventario__c> invToClaveInvMap = New Map<Id, Inventario__c>(); 
        Map<Id, Decimal> invNumCvesMap = New Map<Id, Decimal>();
        List<Clave_de_Inventario__c> cveInvList = New List<Clave_de_Inventario__c>();
        String currentUserEmail = [Select Email From User where Id = : UserInfo.getUserId() limit 1].Email;

        for( Inventario__c inv : invList ){
            if( inv.Estatus__c == 'En Firma' && inv.Estatus__c != oldInvMap.get(inv.Id).Estatus__c ){
                invIdSet.add( inv.Id );
                invFechaMap.put( inv.Id, inv.Fecha_Inicio__c );
            }
        }

        if ( invIdSet.size() > 0 ){
            invToClaveInvMap = new  Map<Id, Inventario__c>([ SELECT Fecha_Inicio__c, (SELECT Inventario__c, Fecha_Inicio_Conteo__c, Estatus_de_Conteo__c, Tipo_de_Insumo__c, Clasificacion__c FROM Claves_de_Inventario__r)
                                                             FROM Inventario__c
                                                             WHERE Id IN : invIdSet ]);

            for( Inventario__c inv : invToClaveInvMap.values() ){          
                for( Clave_de_Inventario__c cveInv : inv.Claves_de_Inventario__r ){
                    if( inv.id == cveInv.Inventario__c && invFechaMap.get(inv.Id) == cveInv.Fecha_Inicio_Conteo__c ){
                        cveInvList.add(cveInv);
                    }
                }
                invNumCvesMap.put(inv.id, cveInvList.size());
            }
            System.debug('invNumCvesMap- ' + invNumCvesMap);

            for( Inventario__c inv : invList ){
                for( Clave_de_Inventario__c claveInv : cveInvList ){
                    if( claveInv.Estatus_de_Conteo__c != 'Contado' || inv.Numero_de_Insumos__c != cveInvList.size()) { 
                        String errorMessage = 'Aun tiene Claves sin actualizar o en estatus diferente a Contado el día de hoy';
                        inv.addError(errorMessage);
                    }
                }
            }
        }

        if( cveInvList.size() > 0 ) {   
            for( Inventario__c inventario : invList ){
                System.debug('inventario.Numero_de_Insumos__c: ' + inventario.Numero_de_Insumos__c);
                System.debug('invNumCvesMap.get(inventario.Id) ' + invNumCvesMap.get(inventario.Id));
                if( inventario.Numero_de_Insumos__c == invNumCvesMap.get(inventario.Id) ){
                    System.debug('Result: ' + inventario.Numero_de_Insumos__c +' | '+ invNumCvesMap.get(inventario.Id));
                    System.debug('USer ' + UserInfo.getName());
                    //inventario.Estatus__c = 'En Firma';
                    inventario.Registrado_Por__c = UserInfo.getName();
                    inventario.Registrado_Por_Email__c = currentUserEmail;
                    inventario.Fecha_Registrado__c = System.Now();
                } 
            }
        }
    }

    public static void attachPDFToInventario( List<Inventario__c> invList, Map<Id, Inventario__c> oldInvMap ){
        System.debug('attachPDFToInventario');
        
        Set<id> invId = New Set<id>();
        for(Inventario__c inv : invList){
            System.debug('inv.Estatus__c: ' + inv.Estatus__c);
            if( ( inv.Estatus__c == 'En Firma' || inv.Estatus__c == 'Firmado' ) && inv.Estatus__c != oldInvMap.get(inv.Id).Estatus__c ){
                System.debug('Inventario' + inv);
                invId.add(inv.Id);
            }
        }
        if(invId.size() > 0){
            String netId = network.getNetworkId();
            addPDFToRecord(invId, netId);
        }
    }

    @Future(callout=true)
    public static void addPDFToRecord(Set<id> inventarioIdList, String networkId){

        String estatus;
        String templateId;
        String htmlBody;
        String body;
        String subject;
        String inventarioId;
        String firmadoPor;
        DateTime fechaFirmado;
        String registradoPor;
        DateTime fechaRegistrado;
        Double offset;

        Set<String> csvRows = new Set<String>();

        List<ContentVersion> contentVerToInsList = New List<ContentVersion>();
        List<Clave_de_Inventario__c> claves = new List<Clave_de_Inventario__c>();

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        Messaging.EmailFileAttachment attachmentCSV = new Messaging.EmailFileAttachment();

        TimeZone tz = UserInfo.getTimeZone();
        //User currentUser = [Select Email From User where Id = : UserInfo.getUserId() limit 1];
        //String registradoPorEmail;
        
        EmailTemplate template = [SELECT Id, HtmlValue, Body, Subject, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'Inventario_En_Firma']; 
        EmailTemplate templateFirmado = [SELECT Id, HtmlValue, Body, Subject, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'Inventario_Firmado'];

        List<Lote_de_Inventario__c> lotes = [ SELECT Lote__c, Fecha_de_Caducidad__c, Conteo_Actual__c, Clave_de_Inventario__c
                                              FROM Lote_de_Inventario__c 
                                              WHERE Clave_de_Inventario__r.Inventario__r.Id = : inventarioIdList ];
  
        if( lotes.size() > 0 ) {
            system.debug('CSV');
            system.debug(lotes);

            Set<Id> clavesIds = new Set<Id>();
            for( Lote_de_Inventario__c li : lotes ) {
                clavesIds.add(li.Clave_de_Inventario__c);
            }
            
            claves = [ SELECT Inventario__r.Codigo_UMU__c, Inventario__r.Clave_Presupuestal__c, Nombre_UMU__c, Inventario__r.Delegaci_n__c,
                                Inventario__r.Name, Tipo_de_Insumo__c, Clasificacion__c, Codigo_de_Producto__c, Producto__r.Description__c,
                                Inventario__r.Fecha_Registrado__c, Inventario__r.Registrado_Por__c, Inventario__r.Signed_Date__c,
                                Inventario__r.Firmado_Por__c, Inventario__r.Estatus__c
                       FROM Clave_de_Inventario__c
                       WHERE Id IN :clavesIds ];

            System.debug('claves: ' + claves);
             
            for(Clave_de_Inventario__c clave : claves) {

                inventarioId = clave.Inventario__c;
                for (Lote_de_Inventario__c lote : lotes) {
                    if(clave.Id == lote.Clave_de_Inventario__c) {
                        if( clave.Inventario__r.Estatus__c == 'En Firma' ){
                            //firmadoPor = '';
                            //fechaFirmado = null;
                            //registradoPorEmail = clave.Inventario__r.Registrado_Por_Email__c;
                            registradoPor = clave.Inventario__r.Registrado_Por__c;
                            fechaRegistrado = clave.Inventario__r.Fecha_Registrado__c + tz.getOffset( clave.Inventario__r.Fecha_Registrado__c ) / (1000 * 3600 * 24.0);
                        } else if ( clave.Inventario__r.Estatus__c == 'Firmado' ){
                            firmadoPor = clave.Inventario__r.Firmado_Por__c;
                            fechaFirmado = clave.Inventario__r.Signed_Date__c + tz.getOffset( clave.Inventario__r.Signed_Date__c ) / (1000 * 3600 * 24.0);
                            //registradoPorEmail = clave.Inventario__r.Registrado_Por_Email__c;
                            registradoPor = clave.Inventario__r.Registrado_Por__c;
                            fechaRegistrado = clave.Inventario__r.Fecha_Registrado__c + tz.getOffset( clave.Inventario__r.Fecha_Registrado__c ) / (1000 * 3600 * 24.0);
                        }
                        csvRows.add('\'' + clave.Inventario__r.Codigo_UMU__c + ',' + '\'' + clave.Inventario__r.Clave_Presupuestal__c + ',' + clave.Nombre_UMU__c
                        + ',' + clave.Inventario__r.Delegaci_n__c + ',' + clave.Inventario__r.Name + ',' + clave.Tipo_de_Insumo__c
                        + ',' + clave.Clasificacion__c + ',' + '\'' + clave.Codigo_de_Producto__c + ',' + clave.Producto__r.Description__c.remove(',')
                        + ',' + lote.Lote__c + ',' + lote.Fecha_de_Caducidad__c
                        + ',' + lote.Conteo_Actual__c + ',' + fechaRegistrado + ',' + registradoPor + ',' + fechaFirmado
                        + ',' + firmadoPor + ',' + clave.Inventario__r.Estatus__c );
                    }
                }
            }
        }

        List<String> csvList = new List<String>(csvRows);
        List<String> headers = new List<String>{'UMU','CLAVE PRESUPUESTAL UMU','NOMBRE UMU','DELEGACIÓN','FOLIO DEL INVENTARIO',
                                                'TIPO DE INSUMO','CLASIFICACIÓN DE INSUMO','CLAVE','DESCRIPCIÓN CLAVE','LOTE','FECHA DE CADUCIDAD',
                                                'PIEZAS CONTADAS','FECHA DE REGISTRO','REGISTRADO POR','FECHA DE REVISIÓN','FIRMADO POR','ESTATUS' };

        String csvString = String.join(headers, ',') + '\n' + String.join(csvList, '\n');
        Blob contentCSVBlob = Blob.valueOf(csvString);

        for (Inventario__c inventario : [SELECT ID, Name, Nombre_UMU__c, Clave_Presupuestal__c, Owner.Name, Owner.Email, Codigo_UMU__c, Estatus__c, Registrado_Por_Email__c
                                         FROM Inventario__c 
                                         WHERE id IN : inventarioIdList]){
            // 
            PageReference inventarioPDFRef = new PageReference('/apex/InventarioPDF?id=' + inventario.Id + '&estatus=' + inventario.Estatus__c);
            Blob contentBlob;
            if( !Test.isRunningTest() ) { 
                contentBlob = inventarioPDFRef.getContentAsPDF();
            } else {
                contentBlob = blob.valueOf('Unit.Test');
            }          
            
            if( inventario.Estatus__c == 'En Firma' ){
                estatus = 'REGISTRADO-';
                templateId = template.Id;
                htmlBody = template.HtmlValue;
                body = template.Body;
                subject = template.Subject;
            } else if ( inventario.Estatus__c == 'Firmado' ){
                estatus = 'FIRMADO-';
                templateId = templateFirmado.Id;
                htmlBody = templateFirmado.HtmlValue;
                body = templateFirmado.Body;
                subject = templateFirmado.Subject;
            }

            ContentVersion contVersion = new ContentVersion();
            contVersion.Title = estatus+inventario.Clave_Presupuestal__c+'-'+inventario.Nombre_UMU__c;
            contVersion.PathOnClient = estatus+inventario.Clave_Presupuestal__c+'-'+inventario.Nombre_UMU__c+'.pdf';
            contVersion.VersionData = contentBlob;
            contVersion.FirstPublishLocationId = inventario.Id;
            contVersion.NetworkId = networkId;
            contentVerToInsList.add(contVersion);

            ContentVersion contVersionCSV = new ContentVersion();
            contVersionCSV.Title = estatus+inventario.Clave_Presupuestal__c+'-'+inventario.Nombre_UMU__c;
            contVersionCSV.PathOnClient = estatus+inventario.Clave_Presupuestal__c+'-'+inventario.Nombre_UMU__c+'.csv';
            contVersionCSV.VersionData = contentCSVBlob;
            contVersionCSV.FirstPublishLocationId = inventario.Id;
            contVersionCSV.NetworkId = networkId;
            contentVerToInsList.add(contVersionCSV);
            
            htmlBody = htmlBody.replace('{INVENTARIO_OWNER}', inventario.Owner.Name);
            htmlBody = htmlBody.replace('{UMU}', inventario.Nombre_UMU__c);
            htmlBody = htmlBody.replace('{CLAVE_UMU}', inventario.Codigo_UMU__c);
            
            subject = subject.replace('{ESTATUS}', inventario.Estatus__c);
			
			attachment.setFileName(contVersion.pathOnClient); 
            attachment.setBody(contVersion.versionData);

            attachmentCSV.setFileName(contVersionCSV.pathOnClient); 
            attachmentCSV.setBody(contVersionCSV.versionData);
			
            email.setSubject(subject);
            email.setHtmlBody(htmlBody);
            email.setPlainTextBody(body);
            email.setToAddresses(new List<String>{inventario.Owner.Email, inventario.Registrado_Por_Email__c});
            email.setFileAttachments(new Messaging.EmailFileAttachment[] {attachment, attachmentCSV});
            System.debug('Inventario Email: ' + email);
            try {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                System.debug('Inventario Email Sent: ' + results);
            } catch (Exception e) {
                System.debug('Error sending email: ' + e.getMessage());
            }
        }
                  
        if(contentVerToInsList.size() > 0){
            insert contentVerToInsList; 
        }
    }

    public static void clearEstatusClave( List<Inventario__c> invList, Map<Id, Inventario__c> oldInvMap ){
        
        Set<Id> invIdSet = New Set<Id>();
        Set<Id> invToUpdateSet = New Set<Id>();

        List<Clave_de_Inventario__c> claveClearStList = New List<Clave_de_Inventario__c>();

        for( Inventario__c inv : invList ){
            System.debug('Inventario 01: ' + inv.Estatus__c);
            if( inv.Estatus__c == 'En Firma' && inv.Estatus__c != oldInvMap.get(inv.Id).Estatus__c ){
                invIdSet.add( inv.Id );
            }
        }

        if ( invIdSet.size() > 0 ){
            for(List<Clave_de_Inventario__c> claveList : [SELECT Inventario__c, Estatus_de_Conteo__c 
                                                          FROM Clave_de_Inventario__c
                                                          WHERE Inventario__c in : invIdSet]){  
                for( Clave_de_Inventario__c clave : claveList ){
                    clave.Estatus_de_Conteo__c = null;
                    claveClearStList.add(clave);
                }                
            }
        }
    
        if(claveClearStList.size() > 0){
            update claveClearStList;
        } 
        
    }
}