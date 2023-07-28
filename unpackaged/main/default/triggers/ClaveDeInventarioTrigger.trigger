trigger ClaveDeInventarioTrigger on Clave_de_Inventario__c (after update, before update) {
        
    if(!CheckRecursive.firstcall) {
        CheckRecursive.firstcall = true;
        switch on Trigger.operationType {
            when BEFORE_UPDATE { 
                ClaveDeInventarioTriggerHandler.claveBeforeUpdateHandler(Trigger.new, Trigger.oldMap);
            } 
        }
    }
    switch on Trigger.operationType {
        when AFTER_UPDATE { 
            ClaveDeInventarioTriggerHandler.claveAfterUpdateHandler(Trigger.new, Trigger.oldMap);
        }
    }
}