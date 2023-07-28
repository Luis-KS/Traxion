public with sharing class ClaveDeInventarioTriggerHandler {
    public static void claveBeforeUpdateHandler( List<Clave_de_Inventario__c> newClaveList, Map<Id, Clave_de_Inventario__c> oldClaveMap ){
    	ClaveInventarioFields.updateEstatusConteo( newClaveList, oldClaveMap );
    }

    public static void claveAfterUpdateHandler( List<Clave_de_Inventario__c> newClaveList, Map<Id, Clave_de_Inventario__c> oldClaveMap ){
    	ClaveInventarioFields.clearEstatusLote( newClaveList, oldClaveMap );
    }
}