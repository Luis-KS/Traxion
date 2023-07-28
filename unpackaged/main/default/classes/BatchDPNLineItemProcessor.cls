global class BatchDPNLineItemProcessor implements Database.Batchable<sObject> {
   global Database.QueryLocator start(Database.BatchableContext bc) {
      return Database.getQueryLocator('SELECT Id, Name, Consumido__c FROM DPN_Line_Item__c');
   }

   global void execute(Database.BatchableContext bc, List<DPN_Line_Item__c> scope) {
      // process each batch of records
      for (DPN_Line_Item__c dpnLineItem : scope) {
          if(dpnLineItem.Consumido__c == 16){
              dpnLineItem.Consumido__c = 0;
          }
         
      }
      update scope;
   }

   global void finish(Database.BatchableContext bc) {
      System.debug('Batch Job Completed Successfully.');
   }
}