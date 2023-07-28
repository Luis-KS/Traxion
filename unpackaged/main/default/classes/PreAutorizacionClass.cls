public without sharing class PreAutorizacionClass {

    private String pedidoId {get;set;}
    public Pedido__c pedido {get;set;}
    private List<Id> listaProductos {get;set;}
    public Order__c orden {get;set;}
    public Account umu {get;set;}
    public Contact contact {get;set;}
    public List<Product2> productos {get;set;}
    public String idSubalmacen{get;set;}
    public String aprobadoPor { get; set; }
    public String fechaRevisionDelegacion { get; set; }
    public String autorizadoPor { get; set; }
    public String fechaAutorizacion { get; set; }
    public Decimal totalCantidadSolicitada { get; set; }
    public Decimal totalCantidadAprobada { get; set; }
    public Decimal totalCantidadAutorizada { get; set; }
    public Decimal totalPiezasSolicitadas { get; set; }
    public Decimal totalPiezasAprobadas { get; set; }
    public Decimal totalPiezasAutorizadas { get; set; }
    public List<Order_Line_Item__c> allOlisFromPedidosList {get;set;}

    public PreAutorizacionClass() {
        try{ 
            pedidoId = ApexPages.currentPage().getParameters().get('id'); 
        } catch(Exception e){
            System.debug(e.getMessage());
        }  
        
        try{
            pedido = [
                SELECT Id, ID_de_Pedido__c, Tipo_de_Pedido__c, CreatedDate, UMU__c, Creado_Por__c, Aprobado_Por__c, Aprobado_Por__r.Name, 
                    Autorizado_Por__c, Autorizado_Por__r.Name, Fecha_Revision_Delegacion__c, Fecha_Revision_SICORA__c
                FROM Pedido__c 
                WHERE Id =: pedidoId 
                LIMIT 1
            ];

            String basePedidoId = pedido.ID_de_Pedido__c.substring(0, 6);
            String likeValue = basePedidoId + '%';
            List<Pedido__c> pedidosList = [
                SELECT Id 
                FROM Pedido__c
                WHERE ID_de_Pedido__c LIKE: likeValue
            ]; 

            Set<Id> pedidosIdSet = new Set<Id>();
            for(Pedido__c pedido : pedidosList){
                pedidosIdSet.add(pedido.Id);
            }

            allOlisFromPedidosList = [
                SELECT Id, Name, Product__c, Order__c, Cantidad_Solicitada__c, Cantidad_Aprobada__c, Cantidad_Autorizada__c,
                    Estatus_Aprobaci_n__c, Estatus_Autorizaci_n__c, Motivo_No_Aprobaci_n__c, Motivo_No_Autorizaci_n__c, 
                    Product__r.Product_Code_ID__c, Product__r.Name
                FROM Order_Line_Item__c
                WHERE Pedido__c IN: pedidosIdSet 
            ]; 


            totalCantidadSolicitada = 0;
            totalCantidadAprobada = 0;
            totalCantidadAutorizada = 0;

            totalPiezasSolicitadas = 0; 
            totalPiezasAprobadas = 0; 
            totalPiezasAutorizadas = 0; 

            for (Order_Line_Item__c oli : allOlisFromPedidosList) {
                if(oli.Cantidad_Solicitada__c != null) {
                    totalCantidadSolicitada += oli.Cantidad_Solicitada__c;
                    totalPiezasSolicitadas++;
                }
                if(oli.Cantidad_Aprobada__c != null){
                    totalCantidadAprobada += oli.Cantidad_Aprobada__c;
                    if(oli.Estatus_Aprobaci_n__c == 'Aprobado'  || oli.Estatus_Aprobaci_n__c == 'Modificado'){
                        totalPiezasAprobadas++;
                    } 
                }
                if(oli.Cantidad_Autorizada__c != null){
                    totalCantidadAutorizada += oli.Cantidad_Autorizada__c; 
                    if(oli.Estatus_Autorizaci_n__c == 'Autorizado'  || oli.Estatus_Autorizaci_n__c == 'Modificado'){
                        totalPiezasAutorizadas++;
                    }   
                }
            }  

        } catch(Exception e){
            System.debug(e.getMessage());
        }
        
        try{
            Id contactId = UserContactClass.getContactIdFromUser();
            List<Contact> contactList = [
                SELECT Name 
                FROM Contact 
                WHERE Id =: contactId
            ];
            if(!contactList.isEmpty()){
                aprobadoPor = contactList[0].Name;
                fechaRevisionDelegacion = String.valueOf(Datetime.now()); 
                autorizadoPor = contactList[0].Name;
                fechaAutorizacion = String.valueOf(Datetime.now());
            } 
        } catch(Exception e){
            System.debug(e.getMessage());
        } 

        try{
            umu = [
                SELECT Id, Name, Ciudad__c, Calle__c, Colonia__c, Delegacion__c, Estado__c, Tipo_UMU__c, Clave_Presupuestal__c, UMU__c 
                FROM Account 
                WHERE Id =: pedido.UMU__c 
                LIMIT 1
            ];
        } catch(Exception e){
            System.debug(e.getMessage());
        } 

        try{
            contact = [
                SELECT Id, Name 
                FROM Contact 
                WHERE Id =: pedido.Creado_Por__c
            ];
        } catch(Exception e){
            System.debug(e.getMessage());
        } 

        try{ 
            String urlProductos = (ApexPages.currentPage().getParameters().get('listaProductos')); 
            listaProductos = new List<String>(urlProductos.split(','));  
            productos = [
                SELECT Id, Product_Code_ID__c, Name, 
                    (SELECT Id, Name, Product__c, Order__c, Cantidad_Solicitada__c, Cantidad_Aprobada__c, Cantidad_Autorizada__c,
                        Estatus_Aprobaci_n__c, Estatus_Autorizaci_n__c, Motivo_No_Aprobaci_n__c, Motivo_No_Autorizaci_n__c
                     FROM Order_Line_Items__r
                     WHERE Pedido__c =: pedidoId LIMIT 1) 
                FROM Product2 
                WHERE Id IN: listaProductos
            ]; 

            List<Order_Line_Item__c> oliList = [
                SELECT Id, Name, Product__c, Order__c, Cantidad_Solicitada__c, Cantidad_Aprobada__c, Cantidad_Autorizada__c,
                    Estatus_Aprobaci_n__c, Estatus_Autorizaci_n__c, Motivo_No_Aprobaci_n__c, Motivo_No_Autorizaci_n__c
                FROM Order_Line_Item__c 
                WHERE Pedido__c =: pedidoId
            ]; 
        } catch(Exception e){
            System.debug(e.getMessage());
        } 
    }
}