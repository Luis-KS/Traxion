public with sharing class LoteDeInventarioTriggerHandler {
    public static void loteAfterUpdateHandler( List<Lote_de_Inventario__c> newLoteList ){
    	LoteInventarioFields.updateInsertCveInventario( newLoteList );
    }
    public static void loteBeforeUpdateHandler( List<Lote_de_Inventario__c> newLoteList ){
    	LoteInventarioFields.updateInsertFechaModif( newLoteList );
    }
    public static void loteAfterInsertHandler( List<Lote_de_Inventario__c> newLoteList ){
    	LoteInventarioFields.updateInsertCveInventario( newLoteList );
    }
    public static void loteBeforeInsertHandler( List<Lote_de_Inventario__c> newLoteList ){
    	LoteInventarioFields.updateInsertFechaModif( newLoteList );
    }
    public static void loteBeforeDeleteHandler( List<Lote_de_Inventario__c> oldLoteList ){
    	LoteInventarioFields.deleteCurrentLote( oldLoteList );
    }
}