public with sharing class InventarioPDFController {

    public Clave_de_Inventario__c inventario { get; set; }
    private String inventarioId {get;set;}
    public String estatusInventario {get;set;}
    public Decimal clavesContadas {get;set;}
    public Decimal lotesContados {get;set;}
    public Decimal piezasContadas {get;set;}
    public List<Clave_de_Inventario__c> claves {get;set;}
    public List<InventarioWrapper> inventarioDataList {get;set;}
    public String cadenaContenido {get;set;}
    public Double offsetR {get;set;}
    public Double offsetF {get;set;}

    public InventarioPDFController() {

        //String loteInfo;
        //Date caducidadInfo;
        //Decimal piezasInfo;
        String registradoPorEmail;
        String firmadoPorEmail;
        TimeZone tz = UserInfo.getTimeZone();

        User currentUser = [Select Email From User where Id = : UserInfo.getUserId() limit 1];
        registradoPorEmail = currentUser.Email;

        try{ 
            inventarioId = ApexPages.currentPage().getParameters().get('id'); 
            estatusInventario = ApexPages.currentPage().getParameters().get('estatus');
            System.debug('estatusInventario' + estatusInventario);
        } catch(Exception e){
            System.debug(e.getMessage());
        } 

        try{
            inventario = [  SELECT Inventario__r.Fecha_Registrado__c, Tipo_de_Insumo__c, Clasificacion__c, Nombre_UMU__c, Inventario__r.Codigo_UMU__c, 
                                    Inventario__r.Clave_Presupuestal__c, Inventario__r.Delegaci_n__c, Inventario__r.Signed_Date__c, Inventario__r.Tipo_UMU__c,
                                    Inventario__r.Name, Inventario__r.Firmado_Por__c, Inventario__r.Registrado_Por__c, Inventario__r.Conteo_Total_Actual__c,
                                    Inventario__r.Conteo_Total_Lotes__c, Inventario__r.Owner.Email
                            FROM Clave_de_Inventario__c
                            WHERE Inventario__c = :inventarioId
                            LIMIT 1 ];
            
            offsetR = tz.getOffset(inventario.Inventario__r.Fecha_Registrado__c) / (1000 * 3600 * 24.0);
            offsetF = tz.getOffset(inventario.Inventario__r.Signed_Date__c) / (1000 * 3600 * 24.0);

        } catch(Exception e) {
            System.debug(e.getMessage());
        }

        try{ 
            claves = [ SELECT Codigo_de_Producto__c, Clasificacion__c, Producto__r.Description__c, Tipo_de_Insumo__c, Conteo_Actual_Total__c, 
                                ( SELECT Lote__c, Fecha_de_Caducidad__c, Conteo_Actual__c FROM Lotes_de_Inventario__r )
                        FROM Clave_de_Inventario__c
                        WHERE Inventario__c = :inventarioId ];
            
            Integer contador = 1;

            inventarioDataList = new List<InventarioWrapper>(); 
            for(Integer i = 0; i < claves.size(); i++){

                InventarioWrapper invData = new InventarioWrapper();
                invData.clave = claves[i].Codigo_de_Producto__c;
                invData.descripcion = claves[i].Producto__r.Description__c;
                invData.conteoTotal = claves[i].Conteo_Actual_Total__c;

                List<String> loteList = new List<String>(); 
                List<String> caducidadList = new List<String>(); 
                List<String> piezasList = new List<String>(); 

                if(!claves[i].Lotes_de_Inventario__r.isEmpty()){
                    for(Integer j = 0; j < claves[i].Lotes_de_Inventario__r.size(); j++){

                        String loteInfo = claves[i].Lotes_de_Inventario__r[j].Lote__c;
                        Date caducidadInfo = claves[i].Lotes_de_Inventario__r[j].Fecha_de_Caducidad__c;
                        Decimal piezasInfo = claves[i].Lotes_de_Inventario__r[j].Conteo_Actual__c;

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

                        if(piezasInfo != null){
                            piezasList.add(String.valueOf(piezasInfo));
                        } else{
                            piezasList.add('N/A');
                        } 
                    } 
                } else {
                    loteList.add('N/A');
                    caducidadList.add('N/A');
                    piezasList.add('N/A');
                }
                invData.loteList = loteList; 
                invData.caducidadList = caducidadList;
                invData.piezasList = piezasList;
                inventarioDataList.add(invData);
            }
            
            clavesContadas = claves.size(); 
            piezasContadas = inventario.Inventario__r.Conteo_Total_Actual__c;
            lotesContados = inventario.Inventario__r.Conteo_Total_Lotes__c;
            firmadoPorEmail = inventario.Inventario__r.Owner.Email;
            cadenaContenido = inventario.Inventario__r.Name + ',' + inventario.Inventario__r.Clave_Presupuestal__c + ',' + clavesContadas  + ',' +
                              piezasContadas + ',' + inventario.Inventario__r.Registrado_Por__c + ',' + registradoPorEmail + ',' + inventario.Inventario__r.Firmado_Por__c + ',' + 
                              firmadoPorEmail + ',' + inventario.Inventario__r.Fecha_Registrado__c + ',' + inventario.Inventario__r.Signed_Date__c;
            
        } catch(Exception e){
            System.debug(e.getMessage());
        } 
    }

    public class InventarioWrapper{
        public String clave {get;set;}
        public String descripcion {get;set;}
        public Decimal conteoTotal {get;set;}
        public List<String> loteList {get;set;}
        public List<String> caducidadList {get;set;}
        public List<String> piezasList {get;set;}
    }
}