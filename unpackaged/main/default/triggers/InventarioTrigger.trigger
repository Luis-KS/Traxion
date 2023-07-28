trigger InventarioTrigger on Inventario__c (before update, after update) {
    
    switch on Trigger.operationType { 
            when BEFORE_UPDATE { 
                //if(!CheckRecursive.firstcall) {
                    CheckRecursive.firstcall = true;
                    InventarioTriggerHandler.inventarioBeforeUpdateHandler(Trigger.new, Trigger.oldMap);
                //}
            } 
            when AFTER_UPDATE {
                System.debug('InventarioTrigger After Update');
                InventarioTriggerHandler.inventarioAfterUpdateHandler(Trigger.new, Trigger.oldMap);
            }
        }
    }