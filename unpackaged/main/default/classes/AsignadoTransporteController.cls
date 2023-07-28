public with sharing class AsignadoTransporteController {
  @AuraEnabled(cacheable=true)
  public static List<Object> getEntregas(String idViaje) {
    try {
      List<Order__c> entrega = [
        SELECT
          id,
          ImageId__c,
          Entrega__r.Name,
          Entrega__r.Fecha_Planeada_de_Finalizacion__c,
          UMU__r.Name,
          Estatus__c,
          Entrega__r.Estado__c,
          Entrega__r.OwnerId,
          Usuario_ANS__c,
          UMU__r.Ciudad__c,
          UMU__r.Calle__c,
          UMU__r.Colonia__c,
          UMU__r.Estado__c
        FROM order__c
        WHERE
          Entrega__r.Name = :idViaje
          AND Entrega__r.Estado__c = 'No Asignado'
       // WITH SECURITY_ENFORCED
      ];

      Map<String, List<Order__c>> orden = new Map<String, List<Order__c>>();

      for (Order__c ord : entrega) {
        List<Order__c> newOrderList = new List<Order__c>();
        newOrderList.add(ord);
        orden.put(ord.UMU__r.Name, newOrderList);
      }

      List<Object> entregaList = new List<Object>();
      for (String key : orden.keySet()) {
        Map<String, Object> obj = new Map<String, Object>();
        obj.put('UMUName', key);
        obj.put('records', orden.get(key));
        entregaList.add(obj);
      }

      return entregaList;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

    @AuraEnabled
    public static void updateEntregaAsignar(String idViaje, String userId) {
        try {
            List<Entrega__c> entregaDatos = [
                SELECT Name, Estado__c, OwnerId
                FROM Entrega__c
                WHERE Name = :idViaje
                WITH SECURITY_ENFORCED
            ];
            
            system.debug(entregaDatos);
            
            List<Order__c> ordenes = [
                SELECT id, Estatus__c
                FROM Order__c
                WHERE Entrega__c = :entregaDatos[0].Id
                WITH SECURITY_ENFORCED
            ];
            
            system.debug(ordenes);
            
            List<Order__c> ordenUpdate = new List<Order__c>();
            for (Order__c orden : ordenes) {
                orden.Estatus__c = 'Enviado';
                ordenUpdate.add(orden);
            }
            
            system.debug('--> ordenUpdate' + ordenUpdate);
            
            if (!entregaDatos.isEmpty()) {
                List<Entrega__c> updatedEntregas = new List<Entrega__c>();
                for (Entrega__c entre : entregaDatos) {
                    entre.Estado__c = 'Asignado';
                    entre.OwnerId = userId;
                    updatedEntregas.add(entre);
                }
                
                system.debug('--> updatedEntregas' + updatedEntregas);
                
                if (Schema.sObjectType.Entrega__c.isUpdateable()) {
                    // Perform the update operation
                    update updatedEntregas;
                    update ordenUpdate;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

  @AuraEnabled
  public static void desasignarEntrega(String entregaId) {
    try {
      List<Entrega__c> entrega = [
        SELECT id, Estado__c
        FROM Entrega__c
        WHERE Id = :entregaId
      ];
      List<Entrega__c> entregaUpdate = new List<Entrega__c>();
      if (entrega.size() > 0) {
        for (Entrega__c entre : entrega) {
          entre.Estado__c = 'No Asignado';
          entregaUpdate.add(entre);
        }

        update entregaUpdate;
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void finalizarEntrega(String entregaId) {
    try {
      List<Entrega__c> entrega = [
        SELECT id, Estado__c
        FROM Entrega__c
        WHERE Id = :entregaId
      ];
      List<Entrega__c> entregaUpdate = new List<Entrega__c>();
      if (entrega.size() > 0) {
        for (Entrega__c entre : entrega) {
          entre.Estado__c = 'Entregado';
          entregaUpdate.add(entre);
        }

        update entregaUpdate;
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}