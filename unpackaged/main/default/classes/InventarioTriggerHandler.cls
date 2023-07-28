public with sharing class InventarioTriggerHandler {
    
    public static void inventarioBeforeUpdateHandler( List<Inventario__c> newInvList, Map<Id, Inventario__c> oldInventarioMap ){
    	InventarioFields.updateEstatusInventario( newInvList, oldInventarioMap );
        InventarioFields.updateInventarioFirmado( newInvList, oldInventarioMap );
    }
    public static void inventarioAfterUpdateHandler( List<Inventario__c> newInvList, Map<Id, Inventario__c> oldInventarioMap ){
    	InventarioFields.attachPDFToInventario( newInvList, oldInventarioMap );
        InventarioFields.clearEstatusClave( newInvList, oldInventarioMap );
    }
}