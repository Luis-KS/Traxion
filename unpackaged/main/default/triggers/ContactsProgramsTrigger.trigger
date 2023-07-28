trigger ContactsProgramsTrigger on Contactos_y_Programas__c (before insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT { 
            ContactsProgramsTriggerHandler.ContactsProgramsBeforeInsertHandler(Trigger.new);
        }
    }
}