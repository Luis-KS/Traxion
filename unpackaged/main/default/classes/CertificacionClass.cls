public without sharing class CertificacionClass {

    private String ordenId {get;set;}
    private String pedidoId {get;set;}
    public Pedido__c pedido {get;set;}
    public Contact ansUser {get;set;}
    private List<Id> listaProductos {get;set;}
    public Order__c orden {get;set;}
    public Account umu {get;set;}
    public Contact contact {get;set;}
    public List<Product2> productos {get;set;}
    public String idSubalmacen {get;set;} 
    public List<Order_Line_Item__c> olis {get;set;} 
    public String fecharecepcion {get;set;}
    public String fechallegadatransporte {get;set;}
    public String fechahorallegadatransporte {get;set;}
    public String fechaderemision {get;set;}
    public String fechacertificacion {get;set;}
    public String fechaconfirmacion {get;set;}
    public Integer totaldepiezas {get;set;}
    public Decimal subtotal {get;set;}
    public String subtotaltexto {get;set;}
    public String cadenadecontenido {get;set;} 
    public Integer totalclaves {get;set;}

    public List<CertificationWrapper> certificationDataList {get;set;}
    public class CertificationWrapper{
        public Integer cons {get;set;}
        public String clave {get;set;}
        public Decimal cantidadsurtida {get;set;}
        public String unidad {get;set;}
        public String clavepresupuestal {get;set;}
        public String descripcion {get;set;}
        public Set<String> loteList {get;set;}
        public Set<String> caducidadList {get;set;}
        public Decimal costopromedio {get;set;}
        public Decimal importe {get;set;}
    }

    public CertificacionClass() {

        try{ 
            ordenId = ApexPages.currentPage().getParameters().get('id'); 
        } catch(Exception e){
            System.debug(e.getMessage());
        } 
        
        try{
            orden = [
                SELECT Id, CreatedDate, UMU__c, Order_Number__c, Folio_de_Remision__c, Fecha_de_certificacion_de_la_remision__c, 
                    Folio_del_Pedido__c, Seguimiento__c, Firmado_Por__r.Name, Firmado_Por__r.Email, Certificado_Por__r.Name, Certificado_Por__r.Email,                    
                    Pedido__r.ID_de_Pedido__c, Pedido__r.Creado_Por__c, Pedido__r.Tipo_de_Pedido__c, Fecha_De_Entrega__c,Entrega__r.ID_de_Viaje__c,
                    Pedido__r.CreatedDate, Usuario_ANS__r.Name, Usuario_ANS__r.Email
                FROM Order__c 
                WHERE Id =: ordenId 
                LIMIT 1
            ];
            
            Id ansId = ApexPages.currentPage().getParameters().get('firmadoPor');
            ansUser = [SELECT Name, Email 
                       FROM Contact
                       WHERE Id = :ansId];

            System.debug(orden);
            System.debug(orden.Seguimiento__c);

            if(!String.isBlank(orden.Seguimiento__c)){
                Map<String, String> seguimientoMap = (Map<String, String>)JSON.deserialize(orden.Seguimiento__c, Map<String, String>.class);
                if(seguimientoMap.containsKey('Recibido')){
                    fecharecepcion = Datetime.valueOf(seguimientoMap.get('Recibido').substringAfter(':')).format('dd-MM-yyyy');
                } else if(seguimientoMap.containsKey('Recibido Parcial')){
                    fecharecepcion = Datetime.valueOf(seguimientoMap.get('Recibido Parcial').substringAfter(':')).format('dd-MM-yyyy');
                } else if(seguimientoMap.containsKey('En Firma')){
                    fecharecepcion = Datetime.valueOf(seguimientoMap.get('En Firma').substringAfter(':')).format('dd-MM-yyyy');
                }
                if(seguimientoMap.containsKey('Certificado')){
                    fechacertificacion = Datetime.valueOf(seguimientoMap.get('Certificado').substringAfter(':')).format('dd-MM-yyyy h:mm a');
                }

                if(seguimientoMap.containsKey('Llegada de Transporte')){
                    fechallegadatransporte = Datetime.valueOf(seguimientoMap.get('Llegada de Transporte').substringAfter(':')).format('dd-MM-yyyy');
                    fechahorallegadatransporte = Datetime.valueOf(seguimientoMap.get('Llegada de Transporte').substringAfter(':')).format('dd-MM-yyyy h:mm a');
                }else if(seguimientoMap.containsKey('Transferido')){
                    fechallegadatransporte = Datetime.valueOf(seguimientoMap.get('Transferido').substringAfter(':')).format('dd-MM-yyyy');
                    fechahorallegadatransporte = Datetime.valueOf(seguimientoMap.get('Transferido').substringAfter(':')).format('dd-MM-yyyy h:mm a');
                }

                if(seguimientoMap.containsKey('Preparando Envío')){
                    fechaconfirmacion = Datetime.valueOf(seguimientoMap.get('Preparando Envío').substringAfter(':')).format('dd-MM-yyyy h:mm a');
                }
            }

            fechaderemision = Datetime.now().format('dd-MM-yyyy');

        } catch(Exception e){
            System.debug(e.getMessage());
        }
        System.debug(orden);

        try{
            umu = [
                SELECT Id, Name, Ciudad__c, Calle__c, Colonia__c, Delegacion__c, Estado__c, Tipo_UMU__c, Clave_Presupuestal__c, UMU__c,
                    Razon_Social__c, Direccion_de_Licencia_Sanitaria__c
                FROM Account 
                WHERE Id =: orden.UMU__c 
                LIMIT 1
            ];
        } catch(Exception e){
            System.debug(e.getMessage());
        }
        System.debug(umu);

        try{
            contact = [
                SELECT Id, Name 
                FROM Contact 
                WHERE Id =: orden.Pedido__r.Creado_Por__c
            ];
        } catch(Exception e){
            System.debug(e.getMessage());
        }
        System.debug(contact);

        try{ 
            String urlProductos = (ApexPages.currentPage().getParameters().get('listaProductos')); 
            listaProductos = new List<String>(urlProductos.split(','));  
            olis = [
                SELECT Id, Name, Product__c, Order__c, Cantidad_Solicitada__c, Cantidad_Aprobada__c, Cantidad_Entregada__c, Cantidad_Autorizada__c, Importe__c,
                    Cantidad_Surtida__c, Estatus_Aprobaci_n__c, Estatus_Autorizaci_n__c, Motivo_No_Aprobaci_n__c, Motivo_No_Autorizaci_n__c, 
                    Product__r.Name, Product__r.Product_Code_ID__c, Product__r.Partida_Presupuestal__c, Product__r.Description__c, Costo_Promedio__c,
                    (SELECT Numero_de_Lote__c, Fecha_de_Expiracion__c FROM Informacion_De_Lotes__r) 
                FROM Order_Line_Item__c 
                WHERE Order__c =: ordenId
                    AND Product__c IN: listaProductos
            ]; 

            Integer localTotalDePiezas = 0;
            Decimal localCostoTotal = 0;
            Integer contador = 1;
            totalclaves = 0;

            certificationDataList = new List<CertificationWrapper>(); 
            for(Integer i = 0; i < olis.size(); i++){
                CertificationWrapper certData = new CertificationWrapper();
                
                certData.clave = olis[i].Product__r.Product_Code_ID__c;
                certData.cantidadsurtida = olis[i].Cantidad_Entregada__c;
                certData.unidad = 'UN';
                certData.clavepresupuestal = olis[i].Product__r.Partida_Presupuestal__c;
                certData.descripcion = olis[i].Product__r.Description__c; 

                Set<String> loteList = new Set<String>(); 
                Set<String> caducidadList = new Set<String>(); 
                if(!olis[i].Informacion_De_Lotes__r.isEmpty()){
                    for(Integer j = 0; j < olis[i].Informacion_De_Lotes__r.size(); j++){
                        String loteInfo = olis[i].Informacion_De_Lotes__r[j].Numero_de_Lote__c;
                        Date caducidadInfo = olis[i].Informacion_De_Lotes__r[j].Fecha_de_Expiracion__c;

                        if(!String.isBlank(loteInfo)){ 
                            loteList.add(loteInfo);
                        } else{
                            loteList.add('N/A');
                        }

                        if(caducidadInfo != null){
                            caducidadList.add(String.valueOf(caducidadInfo));
                        } else{
                            caducidadList.add('N/A');
                        } 
                    } 
                } else{
                    loteList.add('N/A');
                    caducidadList.add('N/A');
                }
                certData.loteList = loteList; 
                certData.caducidadList = caducidadList; 
                certData.costopromedio = olis[i].Costo_Promedio__c != null ? olis[i].Costo_Promedio__c.setscale(2) : 0;
                
                Decimal subimporte = olis[i].Costo_Promedio__c != null && olis[i].Cantidad_Entregada__c != null ? olis[i].Costo_Promedio__c * olis[i].Cantidad_Entregada__c : 0;
                certData.importe = subimporte.setscale(2);

                if(olis[i].Cantidad_Entregada__c == null || olis[i].Cantidad_Entregada__c == 0){
                    continue;
                }  
                certData.cons = contador++;
                totalclaves++;
                certificationDataList.add(certData);
                localTotalDePiezas += Integer.valueOf(olis[i].Cantidad_Entregada__c);
                localCostoTotal += subimporte.setscale(2); 
            }
            totaldepiezas = localTotalDePiezas;
            subtotal = localCostoTotal;
            subtotaltexto = ConversorNumeroTexto.convertToWord(Integer.valueOf(subtotal)).toUpperCase() + ' M.N';
        } catch(Exception e){
            System.debug(e.getMessage());
        } 
        System.debug(productos);

        String remision = orden.Folio_de_Remision__c != null ? String.valueOf(orden.Folio_de_Remision__c) + ', ' : ''; //FOLIO REMISION
        String idpedido = orden.Pedido__r.ID_de_Pedido__c != null ? String.valueOf(orden.Pedido__r.ID_de_Pedido__c) + ', ' : ''; //PEDIDO
        //String createdate = orden.Pedido__r.CreatedDate != null ? String.valueOf(orden.Pedido__r.CreatedDate) + ', ' : ''; //FECHA Y HORA DE SOLICITUD
        String createdate = orden.Pedido__r.CreatedDate != null ? String.valueOf(Datetime.valueOf(orden.Pedido__r.CreatedDate).format('dd-MM-yyyy')) + ', ' : '';
        String clavepresupuestal = umu.Clave_Presupuestal__c != null ? String.valueOf(umu.Clave_Presupuestal__c) + ', ' : '';//CLAVE PRESUPUESTAL DE LA UMU
        String umu =  umu.UMU__c != null ? String.valueOf(umu.UMU__c) + ', ' : ''; //NUMERO DE LA UMU
        String numeroentrega = orden.Entrega__r.ID_de_Viaje__c != null ? String.valueOf(orden.Entrega__r.ID_de_Viaje__c) + ', ' : ''; //NUMERO DE ENTREGA
        String fechaconfi = fechaconfirmacion != null ? String.valueOf(fechaconfirmacion) + ', ' : ''; //FECHA Y HORA DE CONFIRMACION DE PEDIDO
        String totalpiezas = totaldepiezas != null ? String.valueOf(totaldepiezas) + ', ' : '';//TOTAL DE PIEZAS
        String totalclaves = totalclaves != null ? String.valueOf(totalclaves) + ', ' : '';//TOTAL DE CLAVES
        String subtotalimporte = subtotal != null ? String.valueOf(subtotal) + ', ' : '';//SUBTOAL DEL IMPORTE
        
        String firmadoporname = ansUser.Name != null ? String.valueOf(ansUser.Name) + ', ' : ''; //NOMBRE COMPLETO DE JEFE DE FARMACIA / ALMACEN
        String firmadoporemail = ansUser.Email != null ? String.valueOf(ansUser.Email) + ', ' : ''; //CORREO ELECTRÓNICO DE JEFE DE FARMACIA / ALMACEN
        
        String nombreans = orden.Usuario_ANS__r.Name != null ? String.valueOf(orden.Usuario_ANS__r.Name) + ', ' : ''; //NOMBRE COMPLETO DEL ANS
        String correoans =  orden.Usuario_ANS__r.Email != null ? String.valueOf(orden.Usuario_ANS__r.Email) + ', ' : ''; //CORREO ELECTRÓNICO DEL ANS

        String dateCert = Datetime.valueOf(System.now()).format('dd-MM-yyyy h:mm a');
        String fechallegadacamion = fechahorallegadatransporte != null ? String.valueOf(fechahorallegadatransporte) + ', ' : ''; //FECHA Y HORA DE LLEGADA DEL CAMIÓN
        //String fecharem = fechacertificacion != null ? String.valueOf(fechacertificacion) + ', ' : ''; //FECHA Y HORA DE FIRMA DE LA REMISIÓN
        //String fechacerti = fechacertificacion != null ? String.valueOf(fechacertificacion) + '.' : '.'; //FECHA Y HORA DE CERTIFICACIÓN
        
       
        
        cadenadecontenido = remision + idpedido + createdate + clavepresupuestal + umu + numeroentrega + fechaconfi + totalpiezas + totalclaves 
            + subtotalimporte + firmadoporname + firmadoporemail + nombreans + correoans + fechallegadacamion + dateCert + ', ' + dateCert + '.';
        
        
        system.debug('Cadena test data');
        System.debug(firmadoporname + firmadoporemail + nombreans + correoans + fechallegadacamion + dateCert);
        system.debug('Cadena test data 2');
        System.debug(remision);
        System.debug(idpedido);
        System.debug(createdate);
        System.debug(clavepresupuestal);
        System.debug(umu);
        System.debug(numeroentrega);
        System.debug(fechaconfi);
        System.debug(totalpiezas);
        System.debug(totalclaves);
        System.debug(subtotalimporte);
        System.debug(firmadoporname);
        System.debug(firmadoporemail);
		System.debug(nombreans);
		System.debug(correoans);
		System.debug(fechallegadacamion);
        System.debug(ansUser);
		//System.debug(fecharem);
		//System.debug(fechacerti);
        
        
        system.debug('Certification data');
        system.debug(certificationDataList);
        system.debug(cadenadecontenido);

    }
}