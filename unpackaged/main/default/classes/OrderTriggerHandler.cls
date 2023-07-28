public class OrderTriggerHandler {
    public static void orderBeforeUpdateHandler(List<Order__c> newOrderList, Map<Id, Order__c> oldOrderMap){
    	OrderFields.updateSeguimiento(newOrderList, oldOrderMap);
    }

    public static void orderAfterUpdateHandler(List<Order__c> newOrderList, Map<Id, Order__c> oldOrderMap){
    	OrderFields.updateDates(newOrderList, oldOrderMap);
    }

    public static void orderAfterUpdateDeliveryHandler(List<Order__c> newOrderList, Map<Id, Order__c> oldOrderMap) {
        Set<String> orderIdSet = new Set<String>(); 
        for(Order__c ord : newOrderList){
            if(ord.Estatus__c == 'Preparando Envío' && 
               (oldOrderMap.get(ord.Id).Estatus__c == 'Verificando Disponibilidad' || oldOrderMap.get(ord.Id).Estatus__c == 'Preparando Envío')){
                orderIdSet.add(ord.Id);
            } 
        } 
        List<String> orderIdList = new List<String>(orderIdSet);
        if(!orderIdList.isEmpty()){
            OrderFields.confirmOrder(orderIdList);
        } 
    }
}