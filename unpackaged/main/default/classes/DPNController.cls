public with sharing class DPNController {

  // Considerar cambiar el nombre del método, obtiene UMU NO DPN -Daniel 
  @AuraEnabled(cacheable=true)
  public static List<Account> getDPN(String searchKey) {
    return [
      SELECT id, Clave_Presupuestal__c, Name
      FROM Account
      WHERE Name LIKE :'%' + searchKey + '%'
      WITH SECURITY_ENFORCED
      ORDER BY Name DESC 
    ];
  }
  
  // Considerar eliminar el método, devuelve una lista vacía -Daniel 
  @AuraEnabled(cacheable=true)
  public static List<DPN_Line_Item__c> getDpnList(String Id){
      String Search = '%' + Id + '%';
      List<DPN_Line_Item__c> dpnList = [SELECT Id FROM DPN_Line_Item__c WHERE DPN__c =: Search];
      
      return dpnList;
  }
  
  // Create a lightning-datatable and display modal on rowaction
  @AuraEnabled(cacheable=true)
  public static List<Contact> getDataFromContact(){

       return [Select Id, FirstName, LastName, Email, Phone 
               From Contact 
               limit 10];
  }
  

}