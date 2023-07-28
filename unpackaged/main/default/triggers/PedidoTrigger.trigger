trigger PedidoTrigger on Pedido__c (before insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT { 
            PedidoTriggerHandler.pedidoBeforeInsertHandler(Trigger.new);
        } 
    } 
}