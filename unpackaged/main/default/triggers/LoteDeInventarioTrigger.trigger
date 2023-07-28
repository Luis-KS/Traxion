trigger LoteDeInventarioTrigger on Lote_de_Inventario__c (after update, before update, after insert, before insert, before delete) {

    switch on Trigger.operationType {
        when AFTER_UPDATE {
            LoteDeInventarioTriggerHandler.loteAfterUpdateHandler(Trigger.new);
        }
        when BEFORE_UPDATE { 
            LoteDeInventarioTriggerHandler.loteBeforeUpdateHandler(Trigger.new);
        }   
        when AFTER_INSERT {
            LoteDeInventarioTriggerHandler.loteAfterInsertHandler(Trigger.new);
        }
        when BEFORE_INSERT { 
            LoteDeInventarioTriggerHandler.loteBeforeInsertHandler(Trigger.new);
        }
        when BEFORE_DELETE { 
            LoteDeInventarioTriggerHandler.loteBeforeDeleteHandler(Trigger.old);
        } 
    }
}