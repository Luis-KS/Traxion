public with sharing class AnsTransporteController {
  @AuraEnabled(cacheable=true)
  public static List<AccountContactRelation> getUmu(String userId) {
    try {
      List<Id> accId = new List<Id>();
      List<User> activeUser = [
        SELECT ContactId
        FROM User
        WHERE Id = :userId
        WITH SECURITY_ENFORCED
      ];

      Id contactId = activeUser[0].ContactId;
      List<Contact> conList = [
        SELECT AccountId
        FROM Contact
        WHERE id = :contactId
        WITH SECURITY_ENFORCED
      ];

      for (Contact con : conList) {
        accId.add(con.AccountId);
      }

      return [
        SELECT AccountId, Account.Name
        FROM AccountContactRelation
        WHERE ContactId = :contactId
        WITH SECURITY_ENFORCED
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Order__c> getUmuOrders(String umuName, String userId) {
    //Need revision to pass the Entrega Name
    try {
      List<Order__c> ordList = [
        SELECT
          id,
          Fecha_Limite_de_Entrega__c,
          Tipo_de_Pedido__c,
          Total_de_Piezas__c,
          UMU__r.Name,
          Estatus__c,
          Entrega__r.Estado__c,
          Id_de_Viaje__c,
          isRecibida__c
        FROM Order__c
        WHERE
          UMU__r.Name = :umuName
          AND Entrega__r.Estado__c = 'Asignado'
          AND Entrega__r.ownerId = :userId
        WITH SECURITY_ENFORCED
      ];

      return ordList;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static List<Order_Line_Item__c> getOrderItems() {
    try {
      List<Order_Line_Item__c> items = new List<Order_Line_Item__c>();
      return items;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Order__c> getOrdersAns(String userId) {
    try {
      List<Order__c> ordList = [
        SELECT
          id,
          Order_Number__c,
          ID_de_Pedido__c,
          Fecha_Maxima_de_Entrega__c,
          Tipo_de_Pedido__c,
          Total_de_Piezas__c,
          UMU__r.Name,
          UMU__r.Estado__c,
          Estatus__c,
          Entrega__r.Estado__c,
          Id_de_Viaje__c,
          isRecibida__c
        FROM Order__c
        WHERE ownerId = :userId // 0053K000002z5leQAA WHERE UMU__r.Name = :umuName AND Entrega__r.Estado__c = 'Asignado'
        WITH SECURITY_ENFORCED
      ];

      return ordList;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static List<Order_Line_Item__c> getProductsOrder(String orderId) {
    try {
      List<Order_Line_Item__c> productList = [
        SELECT
          id,
          Product__c,
          Product__r.Name,
          Product__r.BP_Product_Code__c,
          Product__r.Product_Code_ID__c,
          Numero_de_Lote__c,
          Cantidad_de_Piezas__c,
          (SELECT Id, Name, Cantidad__c, Numero_de_Lote__c, Cantidad_de_Piezas_Recibidas__c FROM Informacion_De_Lotes__r)
        FROM Order_Line_Item__c
        WHERE Order__c = :orderId
        WITH SECURITY_ENFORCED
      ];

      return productList;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}