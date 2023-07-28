public class OrderLineItemFields {
    public static void getOLIDataAndUpsertPedido(List<Order_Line_Item__c> newOLIList, List<Order_Line_Item__c> oldOLIList){
        Set<Id> pedidoIds = new Set<Id>();
        
        for (Order_Line_Item__c oli : newOLIList) {  
            pedidoIds.add(oli.Pedido__c);
        }
        
        if(Trigger.isUpdate){
            for (Order_Line_Item__c oli : oldOLIList) {
                pedidoIds.add(oli.Pedido__c);
            }
        }

        System.debug(pedidoIds);
        
        List<Pedido__c> pedidosToUpdate = [
            SELECT Id, Total_de_Piezas__c, Total_de_Claves__c, Estatus__c, Es_Programa__c, UMU__r.Tipo_UMU__c,
                (SELECT Id, Cantidad_Solicitada__c, Cantidad_de_Piezas__c, Estatus_de_Orden__c, Order__r.Es_Programa__c,
                    Order__r.Tipo_de_Pedido__c, Cantidad_Autorizada__c, Estatus_Autorizaci_n__c
                FROM Order_Line_Items__r)
            FROM Pedido__c
            WHERE Id IN: pedidoIds
        ];

        System.debug(pedidosToUpdate);

        List<Order_Line_Item__c> oliListToUpdate = new List<Order_Line_Item__c>();
        for(Pedido__c pedido : pedidosToUpdate) { 

            System.debug(pedido);
            System.debug(JSON.serialize(pedido));

            Decimal totalClaves = 0;
            Decimal totalPiezas = 0;
            
            Set<String> estatusOrdenSet = new Set<String>(); 
            for (Order_Line_Item__c oli : pedido.Order_Line_Items__r) {
                if(!pedido.Es_Programa__c && oli.Order__r.Tipo_de_Pedido__c != 'Ordinario'){
                    if(!(oli.Estatus_Autorizaci_n__c != 'Autorizado' && oli.Estatus_Autorizaci_n__c != 'Modificado')){
                        totalClaves ++;
                        totalPiezas += oli.Cantidad_Autorizada__c;
                    } 
                } else{
                    totalClaves ++;
                    totalPiezas += oli.Cantidad_Solicitada__c;
                }

                if(!String.isBlank(oli.Estatus_de_Orden__c)){
                    estatusOrdenSet.add(oli.Estatus_de_Orden__c);
                }
            }  

            String estatusPedido = 'Ver Detalles';
            if(estatusOrdenSet.size() == 1){
                List<String> estatusOrdenList = new List<String>(estatusOrdenSet);
                estatusPedido = estatusOrdenList[0];
            } 
            pedido.Estatus__c = estatusPedido;
            pedido.Total_de_Claves__c = totalClaves;
            pedido.Total_de_Piezas__c = totalPiezas;
        } 
        update pedidosToUpdate;  
    } 


    public static void checkHRCMNAndUpdateOli(List<Order_Line_Item__c> newOLIList){
        if(Trigger.isBefore && Trigger.isInsert){
            Set<Id> umuIds = new Set<Id>();  
            for (Order_Line_Item__c oli : newOLIList) {   
                umuIds.add(oli.UMU__c);
            } 
    
            Map<Id, Account> umusEspecialesMap = new Map<Id, Account>([
                SELECT Id, Tipo_UMU__c
                FROM Account
                WHERE Id IN: umuIds
                    AND (Tipo_UMU__c = 'HR' OR Tipo_UMU__c = 'CMN')
            ]);
    
            for (Order_Line_Item__c oli : newOLIList) {  
                if(umusEspecialesMap.keySet().contains(oli.UMU__c) ){
                    oli.Estatus_Aprobaci_n__c = 'Aprobado';
                    oli.Cantidad_Aprobada__c = oli.Cantidad_Solicitada__c;  
                } 
            } 
        } 
    } 
}