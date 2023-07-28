public with sharing class CalendarioDeValidacionesController {
  @AuraEnabled(cacheable=true)
  public static List<D_a_de_Pedido__c> getCalendarioValidaciones(String accId) {
    try {
      String status = 'Activo';
     

      List<D_a_de_Pedido__c> calendarioVal = [
        SELECT DPN__c, Name, Fecha__c, Hora_de_Inicio__c, Hora_de_Fin__c
        FROM D_a_de_Pedido__c
        WHERE DPN__r.Account__c = :accId AND DPN__r.Estatus__c = :status
        ORDER BY Fecha__c ASC
      ];

      return calendarioVal;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}