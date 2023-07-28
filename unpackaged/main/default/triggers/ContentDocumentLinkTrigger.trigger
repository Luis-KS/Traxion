trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {

        String lhwDocumentPrefix = Schema.getGlobalDescribe().get('Order__c').getDescribe().getKeyPrefix();
        String pedidoDocumentPrefix = Schema.getGlobalDescribe().get('Pedido__c').getDescribe().getKeyPrefix();

        for (ContentDocumentLink cdl : Trigger.New) {
            if (String.valueOf(cdl.LinkedEntityId).startsWithIgnoreCase(lhwDocumentPrefix)) {
                cdl.Visibility = 'AllUsers';
            }
            if (String.valueOf(cdl.LinkedEntityId).startsWithIgnoreCase(pedidoDocumentPrefix)) {
                cdl.Visibility = 'AllUsers';
            }
        }
    }
}