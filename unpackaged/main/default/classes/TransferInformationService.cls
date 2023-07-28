public without sharing class TransferInformationService {
  @AuraEnabled
  public static String createTransferInformation(
    String recordIds,
    String UmuId
  ) {
    // Split the incoming record IDs into a list
    List<String> incomingRecordIdsList = recordIds.split(',');

    // Convert the list to a set of Ids
    Set<String> incomingRecordIdsSet = new Set<String>();

    for (String recordId : incomingRecordIdsList) {
      incomingRecordIdsSet.add((String) recordId);
    }
    // TODO: Add try catch block and manage exception and throw aura exceptions

    // Query all TransferInformation records that have not been transferred yet
    List<Informacion_de_Transferencia__c> existingTransferInfos = [
      SELECT Id, Codigo_De_Transferencia__c, Identificadores_de_Ordenes__c
      FROM Informacion_de_Transferencia__c
      WHERE Transferido__c = FALSE
    ];

    // Iterate over the existing TransferInformation records
    for (
      Informacion_de_Transferencia__c existingTransferInfo : existingTransferInfos
    ) {
      // Split the stored record IDs into a list and convert to a set
      Set<String> storedRecordIdsSet = new Set<String>();
      List<String> storedRecordIdsList = existingTransferInfo.Identificadores_de_Ordenes__c.split(
        ','
      );
      for (String recordId : storedRecordIdsList) {
        storedRecordIdsSet.add((String) recordId);
      }

      // If the sets are equal, return the existing unique code
      if (storedRecordIdsSet.equals(incomingRecordIdsSet)) {
        return existingTransferInfo.Codigo_De_Transferencia__c;
      }
    }
    // If no matching TransferInformation record was found, create a new one
    Informacion_de_Transferencia__c transferInfo = new Informacion_de_Transferencia__c();
    transferInfo.Identificadores_de_Ordenes__c = recordIds;
    // transferInfo.UmuId = UmuId;

    insert transferInfo;

    // Generate a unique number
    String formattedNum = generateRandomNumber();
    System.debug(formattedNum);
    String uniqueCode = generateUniqueCode(formattedNum);

    // Update the transfer information record with the unique code
    transferInfo.Codigo_De_Transferencia__c = uniqueCode;
    update transferInfo;

    return uniqueCode;
  }

  private static String generateRandomNumber() {
    // Generate a unique code
    Integer randomNum = (Integer) Math.floor(
      Math.random() * (999999999 - 100000000 + 1) + 100000000
    );
    String numString = String.valueOf(randomNum);
    String formattedNum = numString.leftPad(9, '0');
    System.debug(formattedNum);

    return formattedNum;
  }

  public static String generateUniqueCode(String randomNumberString) {
    String uniqueCode = '';
    String possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    for (Integer i = 0; i < 4; i++) {
      Integer idx = Math.mod(
        Math.abs(Crypto.getRandomInteger()),
        possible.length()
      );
      uniqueCode += possible.substring(idx, idx + 1);
    }

    return randomNumberString + uniqueCode;
  }

  @AuraEnabled
  public static String getOrdersBeforeTransfer(String uniqueCode) {
    // Query for the TransferInformation record
    List<Informacion_de_Transferencia__c> transferInfo = [
      SELECT Id, Identificadores_de_Ordenes__c, Transferido__c
      FROM Informacion_de_Transferencia__c
      WHERE Codigo_De_Transferencia__c = :uniqueCode
      LIMIT 1
    ];

    // If the records have already been transferred, exit the method
    if (transferInfo.size() == 0) {
      return 'Las ordenes ya fueron transferidas anteriormente o el codigo no fue generado.';
    }

    List<String> recordIds = new List<String>();
    for (
      String recordId : transferInfo[0].Identificadores_de_Ordenes__c.split(',')
    ) {
      System.debug(recordId);
      recordIds.add(recordId.normalizeSpace());
    }

    // Query for the records to transfer
    List<Order__c> recordsToTransfer = [
      SELECT
        Id,
        Order_Number__c,
        OwnerId,
        Estatus__c,
        UMU__c,
        Usuario_ANS__c,
        Cantidad_de_Cajas_en_la_Orden__c,
        Cantidad_de_Cajas_Faltantes_en_la_Orden__c,
        Pedido__r.Fecha_Limite_de_Entrega__c,
        Entrega__r.Estado__c,
        Subalmacen__c,
        UMU__r.Name
      FROM Order__c
      WHERE Id IN :recordIds
    ];

    if (recordsToTransfer.size() > 0) {
      return JSON.serialize(recordsToTransfer);
    }

    throw new AuraHandledException('Error al traer los records');
  }

  @AuraEnabled
  public static String transferOwnership(
    String uniqueCode,
    String newOwnerId,
    String ordenCantidadDeCajasFaltantesJSON
  ) {
    // Query for the TransferInformation record
    List<Informacion_de_Transferencia__c> transferInfo = [
      SELECT Id, Identificadores_de_Ordenes__c, Transferido__c
      FROM Informacion_de_Transferencia__c
      WHERE Codigo_De_Transferencia__c = :uniqueCode
      LIMIT 1
    ];

    // If the records have already been transferred, exit the method
    if (transferInfo.isEmpty()) {
      return 'Las ordenes ya fueron transferidas anteriormente o el codigo no fue generado.';
    }

    List<String> recordIds = new List<String>();
    for (
      String recordId : transferInfo[0].Identificadores_de_Ordenes__c.split(',')
    ) {
      System.debug(recordId);
      recordIds.add(recordId.normalizeSpace());
    }

    // Query for the records to transfer
    List<Order__c> recordsToTransfer = [
      SELECT
        Id,
        OwnerId,
        Estatus__c,
        UMU__c,
        Usuario_ANS__c,
        Order_Number__c,
        Cantidad_de_Cajas_Faltantes_en_la_Orden__c
      FROM Order__c
      WHERE Id IN :recordIds
    ];

    // TODO: Add a database savepoint
    if (!recordsToTransfer.isEmpty()) {
      // Create a method to check if the current user contact is part of the UMU, if the user is not part of that UMU, throw an exception.
      String umu = recordsToTransfer[0].UMU__c;
      Boolean canTransfer = isContactPartOfUmu(newOwnerId, umu);
      if (!canTransfer) {
        throw new AuraHandledException(
          'Error: El usuario no es parte de la UMU.'
        );
      }

      OrderUpdates ordersCajas = (OrderUpdates) JSON.deserialize(
        ordenCantidadDeCajasFaltantesJSON,
        OrderUpdates.class
      );

      for (Order__c record : recordsToTransfer) {
        Integer cantidadDeCajasFaltantes = ordersCajas.orders.get(
          record.Order_Number__c
        );
        record.OwnerId = newOwnerId;
        record.Estatus__c = 'Transferido';
        record.Usuario_ANS__c = newOwnerId;
        // TODO: agregar la cantidad de cajas faltantes en la orden
        // ordenCantidadDeCajasFaltantes es un mapa con el id de la orden y la cantidad de cajas faltantes.
        // Integer cantidadDeCajasFaltantes = ordenCantidadDeCajasFaltantes.get('OrderID');
        // record.Cantidad_de_Cajas_Faltantes_en_la_Orden__c = cantidadDeCajasFaltantes;
        record.Cantidad_de_Cajas_Faltantes_en_la_Orden__c = cantidadDeCajasFaltantes !=
          null
          ? cantidadDeCajasFaltantes
          : 0;
        System.debug(record);
      }

      try {
        update recordsToTransfer;
        delete transferInfo;
        return 'Transferencia exitosa';
      } catch (Exception e) {
        // TODO: Add a database savepoint
        System.debug(e.getMessage());
        system.debug(e.getStackTraceString());
        throw new AuraHandledException('Error: ' + e.getMessage());
      }
    } else {
      throw new AuraHandledException(
        'Error: No se encontraron ordenes para transferir'
      );
    }
  }

  private static Boolean isContactPartOfUmu(String userId, String umuId) {
    // Fetch User with related Contact
    User userRecord = [
      SELECT Id, ContactId
      FROM User
      WHERE Id = :userId
      LIMIT 1
    ];

    // If there is no contact related to the user, return false
    if (userRecord.ContactId == null) {
      return false;
    }

    // Fetch AccountContactRelation records where AccountId is the provided accountId and ContactId is the user's ContactId
    List<AccountContactRelation> acrList = [
      SELECT Id, AccountId, ContactId
      FROM AccountContactRelation
      WHERE AccountId = :umuId AND ContactId = :userRecord.ContactId
    ];

    // If the list is not empty, the contact is associated with the account
    if (!acrList.isEmpty()) {
      return true;
    }

    // Otherwise, return false
    return false;
  }

  @AuraEnabled(cacheable=true)
  public static Boolean doesUserHavePermissionSetWithCustomPermission(
    String userId,
    String permissionSetName,
    String customPermissionName
  ) {
    // Query PermissionSetAssignment to see if the user has the specific permission set assigned
    PermissionSetAssignment psa = [
      SELECT Id, PermissionSetId
      FROM PermissionSetAssignment
      WHERE AssigneeId = :userId AND PermissionSet.Name = :permissionSetName
      LIMIT 1
    ];

    // If there is no PermissionSetAssignment record, return false
    if (psa == null) {
      return false;
    }

    // Query SetupEntityAccess to see if the permission set includes the custom permission
    SetupEntityAccess sea = [
      SELECT Id
      FROM SetupEntityAccess
      WHERE
        ParentId = :psa.PermissionSetId
        AND SetupEntityId IN (
          SELECT Id
          FROM CustomPermission
          WHERE DeveloperName = :customPermissionName
        )
      LIMIT 1
    ];

    // If the SetupEntityAccess record exists, return true; otherwise, return false
    return sea != null;
  }

  public class OrderUpdates {
    // Order number -> Cantidad de cajas
    public Map<String, Integer> orders;
  }
}