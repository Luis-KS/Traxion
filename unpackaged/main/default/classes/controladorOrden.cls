public without sharing class controladorOrden {
    private String ordenId {get;set;}
    private List<Id> listaProductos {get;set;}
    public Order__c orden {get;set;}
    public Account umu {get;set;}
    public Contact contact {get;set;}
    public List<Product2> productos {get;set;}
    public String idSubalmacen{get;set;}
    public Decimal totalCantidadSolicitada { get; set; }
    public Decimal totalCantidadAprobada { get; set; }
    public Decimal totalPiezasAprobadas { get; set; }
    public Decimal totalPiezasSolicitadas { get; set; }
    public Decimal totalCantidadConfirmada { get; set; }
    public Decimal totalPiezasConfirmadas { get; set; }
    public String folioDeEntrega {get;set;}
    public String folioDeRemision {get;set;}
    List<String> ordenIdList = new List<string>();

    public controladorOrden() {
        ordenId = ApexPages.currentPage().getParameters().get('id');
        orden = new Order__c();
        orden = [
            SELECT Id, Pedido__c, Folio_de_Entrega__c, Folio_de_Remision__c, Pedido__r.ID_de_Pedido__c, 
                Contacto__r.FirstName, UMU__c, Folio_del_Pedido__c, Tipo_de_Pedido__c, Entrega__c, Entrega__r.Name, CreatedDate,
                (SELECT Id, Order__c, Product__c, Numero_de_Subalmacen__c, UMU__c 
                 FROM Order_Line_Items__r) 
            FROM Order__c 
            WHERE Id =: ordenId 
            LIMIT 1
        ];
        
        // Get ids parameters
        List<Id> productIds = new List<Id>();
        List<String> oliIdList = new List<String>();
        for(Order_Line_Item__c oli: orden.Order_Line_Items__r){
            productIds.add(oli.Product__c);
            oliIdList.add(oli.Id);
        }
        String idsParameters = String.join(productIds, ','); 
        listaProductos = new List<String>(idsParameters.split(','));

        umu = [SELECT Id, Name, Ciudad__c, Calle__c, Colonia__c, Delegaci_n__c, Estado__c, Tipo_UMU__c, Clave_Presupuestal__c, UMU__c FROM Account WHERE Id = :orden.UMU__c LIMIT 1];
        contact = [SELECT Id, Name FROM Contact WHERE Id =: orden.Contacto__c];
        
        idSubalmacen = (ApexPages.currentPage().getParameters().get('idsubalmacen'));

        //productos = [SELECT Id, Product_Code_ID__c, Name FROM Product2 WHERE Id IN :(listaProductos)];
        ordenIdList.add(ordenId); // Assuming ordenId is a single ID value
        productos = [SELECT Id, Name, Product_Code_ID__c, 
                     (SELECT Id, Name, Product__c, Order__c, Cantidad_Solicitada__c, Cantidad_Aprobada__c, Cantidad_de_Piezas__c
                      FROM Order_Line_Items__r WHERE Order__c IN :ordenIdList LIMIT 1) 
					FROM Product2 
					WHERE Id IN :listaProductos];

        List<Order_Line_Item__c> oliList = [
            SELECT Id, Name, Product__c, Order__c, Cantidad_Solicitada__c, Cantidad_Aprobada__c, Cantidad_de_Piezas__c
            FROM Order_Line_Item__c
            WHERE Order__c IN :ordenIdList
        ];

        totalCantidadSolicitada = 0; 
        totalCantidadConfirmada = 0;

        totalPiezasSolicitadas = 0;  
        totalPiezasConfirmadas = 0; 

        for(Order_Line_Item__c oli : oliList){
            if(oli.Cantidad_Solicitada__c != null && oli.Cantidad_Solicitada__c != 0) {
                totalCantidadSolicitada += oli.Cantidad_Solicitada__c;
                totalPiezasSolicitadas++;
            }
            if(oli.Cantidad_de_Piezas__c != null && oli.Cantidad_de_Piezas__c != 0){
                totalCantidadConfirmada += oli.Cantidad_de_Piezas__c; 
                totalPiezasConfirmadas++; 
            }
        } 
    }
}