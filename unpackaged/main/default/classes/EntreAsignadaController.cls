public with sharing class EntreAsignadaController {
  @AuraEnabled(cacheable=true)
  public static List<Object> getEntregasAsignadas(String userId) {
    try {
      List<Order__c> entrega = [
        SELECT
          id,
          ImageId__c,
          Entrega__r.Name,
          Estatus__c,
          Entrega__r.Fecha_Planeada_de_Finalizacion__c,
          UMU__r.Name,
          Entrega__r.Estado__c,
          Entrega__r.OwnerId,
          Usuario_ANS__c,
          UMU__r.Ciudad__c,
          UMU__r.Calle__c,
          UMU__r.Colonia__c,
          UMU__r.Estado__c
        FROM order__c
        WHERE Entrega__r.OwnerId = :userId AND Entrega__r.Estado__c = 'Asignado'
        WITH SECURITY_ENFORCED
      ];

      // Map<String, List<Order__c>> orden = new Map<String, List<Order__c>>();
      // Map<String, List<String>> ids = new Map<String, List<String>>();

      // for (Order__c ord : entrega) {
      //   List<Order__c> newOrderList = new List<Order__c>();
      //   newOrderList.add(ord);
      //   orden.put(ord.UMU__r.Name, newOrderList);

      //   if (ids.containsKey(ord.UMU__r.Name)) {
      //     List<String> idList = ids.get(ord.UMU__r.Name);
      //     idList.add(ord.Id);
      //     ids.put(ord.UMU__r.Name, idList);
      //   } else {
      //     List<String> idList = new List<String>();
      //     idList.add(ord.Id);
      //     ids.put(ord.UMU__r.Name, idList);
      //   }
      // }

      // List<Object> entregaList = new List<Object>();
      // for (String key : orden.keySet()) {
      //   Map<String, Object> obj = new Map<String, Object>();
      //   obj.put('UMUName', key);
      //   obj.put('records', orden.get(key));
      //   obj.put('ids', ids.get(key));
      //   entregaList.add(obj);
      // }

      // return entregaList;
      Map<String, List<Order__c>> orden = new Map<String, List<Order__c>>();
      Map<String, String> ids = new Map<String, String>();

      for (Order__c ord : entrega) {
        List<Order__c> newOrderList = new List<Order__c>();
        newOrderList.add(ord);
        orden.put(ord.UMU__r.Name, newOrderList);

        if (ids.containsKey(ord.UMU__r.Name)) {
          String idString = ids.get(ord.UMU__r.Name);
          idString += ', ' + ord.Id;
          ids.put(ord.UMU__r.Name, idString);
        } else {
          ids.put(ord.UMU__r.Name, ord.Id);
        }
      }

      List<Object> entregaList = new List<Object>();
      for (String key : orden.keySet()) {
        Map<String, Object> obj = new Map<String, Object>();
        obj.put('UMUName', key);
        obj.put('records', orden.get(key));
        obj.put('ids', ids.get(key));
        entregaList.add(obj);
      }

      return entregaList;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}