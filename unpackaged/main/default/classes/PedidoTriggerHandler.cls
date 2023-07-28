public class PedidoTriggerHandler {
	public static void pedidoBeforeInsertHandler(List<Pedido__c> pedidoList){
    	PedidoFields.insertIdDePedido(pedidoList); 
    }
}