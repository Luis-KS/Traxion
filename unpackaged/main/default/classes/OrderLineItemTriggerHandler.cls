public class OrderLineItemTriggerHandler {
    public static void oliBeforeInsertHandler(List<Order_Line_Item__c> newOrderList){  
        OrderLineItemFields.checkHRCMNAndUpdateOli(newOrderList);
    } 

    public static void oliAfterInsertUpdateHandler(List<Order_Line_Item__c> newOrderList, List<Order_Line_Item__c> oldOrderList){  
        OrderLineItemFields.getOLIDataAndUpsertPedido(newOrderList, oldOrderList);
    } 
}