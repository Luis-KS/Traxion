global class DPNLIConsumidoUpdateBatch implements Database.Batchable<sObject>{

    global Database.QueryLocator start( Database.BatchableContext BC ) {
        String query = 'SELECT Id, Activo__c FROM DPN_Line_Item__c';
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<DPN_Line_Item__c> scope){
         for (DPN_Line_Item__c dpnli : scope)
         {
             dpnli.Activo__c = true;   
         }
         update scope;
    }   
    
    global void finish( Database.BatchableContext BC ) {
        
    }
 
}