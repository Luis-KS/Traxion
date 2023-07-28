public with sharing class OrderController {
  public class OrderWrapper {
    public String umu;
    public String tipoDePedido;
    public Integer totalDePiezas;
    public String contactId;
    public String status;
    public List<OrderItemWrapper> orderItems;
  }

  public class OrderItemWrapper {
    public String productId;
    public Integer cantidadSolicitada;
    public String umu;
  }

  @AuraEnabled
  public static String createOrder(String jsonData) {
    // Parse the JSON data into an Apex object
    OrderWrapper orderWrapper = (OrderWrapper) JSON.deserialize(
      jsonData,
      OrderWrapper.class
    );

    Order__c newOrder = new Order__c();
    newOrder.UMU__c = orderWrapper.umu;
    newOrder.Tipo_de_Pedido__c = orderWrapper.tipoDePedido;
    newOrder.Total_de_Piezas__c = orderWrapper.totalDePiezas;
    newOrder.Contacto__c = orderWrapper.contactId;
    newOrder.Estatus__c = orderWrapper.status;

    // Create a list to hold the Order_Line_Item__c records
    List<Order_Line_Item__c> orderItems = new List<Order_Line_Item__c>();

    for (OrderItemWrapper itemWrapper : orderWrapper.orderItems) {
      Order_Line_Item__c newItem = new Order_Line_Item__c();
      newItem.Product__c = itemWrapper.productId;
      newItem.Cantidad_Solicitada__c = itemWrapper.cantidadSolicitada;
      newItem.Order__c = newOrder.Id; // Set the Order__c field on the Order_Line_Item__c record

      orderItems.add(newItem);
    }

    try {
      insert newOrder;
      insert orderItems;
      return 'Order created successfully!';
    } catch (DmlException e) {
      // TODO: change this for an aura exception
      return 'Error creating order: ' + e.getMessage();
    }
  }

  @AuraEnabled
  public static String registrarOrden(String orderId, String status) {
    Set<String> setName = new Set<String>{ 'En Firma', 'Rechazado' };

    if (!setName.contains(status)) {
      return 'El estado proporcionado es incorrecto.';
    }

    List<Order__c> orders = [
      SELECT Id, Estatus__c, Fecha_De_Entrega__c, Hora_De_Entrega__c
      FROM Order__c
      WHERE Id = :orderId
    ];

    try {
      if (orders.size() > 0) {
        for (Order__c orden : orders) {
          orden.Estatus__c = status;
          orden.Fecha_De_Entrega__c = System.now().date(); 
          orden.Hora_De_Entrega__c = System.now().time();
        }

        update orders;
      }
    } catch (Exception e) {
      System.debug(e.getMessage());
      System.debug(e.getStackTraceString());
      // TODO: change this for an aura exception
      return 'Error al enviar registro: ' + e.getMessage();
    }
    return 'Enviado correctamente.';
  }

  @AuraEnabled
  public static String registrarOrdenParcial(
    String orderId,
    String status,
    String ordenParcialJson
  ) {
    Set<String> setName = new Set<String>{ 'Recibido Parcial' };

    if (!setName.contains(status)) {
      return 'El estado proporcionado es incorrecto.';
    }

    OrderUpdates orderUpdates = (OrderUpdates) JSON.deserialize(
      ordenParcialJson,
      OrderUpdates.class
    );

    List<Order__c> orders = [
      SELECT
        Id,
        Estatus__c,
        (
          SELECT Id, Estatus__c, Cantidad_Solicitada__c, Cantidad_Recibida__c, Piezas_Faltantes__c,  Cantidad_de_Piezas__c
          FROM Order_Line_Items__r
        )
      FROM Order__c
      WHERE Id = :orderId
      LIMIT 1
    ];

    List<Informacion_De_Lote__c> lotesUpdateList = new List<Informacion_De_Lote__c>();
    try {
      if (orders.size() > 0) {
        for (Order__c orden : orders) {
          orden.Estatus__c = status;
          orden.Descripcion__c = orderUpdates.descripcion;
          orden.Motivo__c = orderUpdates.desviacion;

          // TODO: Check this to confirm its ok.
          orden.Fecha_De_Entrega__c = orderUpdates.selectedDate;
          orden.Hora_De_Entrega__c = orderUpdates.selectedTime;

          Map<Id, Integer> getQuantityPerLote = new Map<Id, Integer>();

          for (OrderItemUpdate itemUpdate : orderUpdates.orderItemsUpdates) {
            for(Lote lote: itemUpdate.lotes){
                getQuantityPerLote.put(lote.Id, lote.cantidadDePiezasFaltantes);
            }
          }
         
          for(Informacion_De_Lote__c lote: [SELECT Id,Cantidad_de_Piezas_Recibidas__c
                                            FROM  Informacion_De_Lote__c
                                            WHERE Id 
                                            IN: getQuantityPerLote.keySet()]){

            lote.Cantidad_de_Piezas_Recibidas__c = getQuantityPerLote.get(lote.Id);                       
            lotesUpdateList.add(lote);
          }
        }

        update orders;
        try {
           ImageUploadController.saveImage('Imagen de Rechazo', orderUpdates.rejectionImage, orderId, false);
        } catch (Exception e) {
          System.debug(e.getMessage() + e.getStackTraceString());
        }
      
        update lotesUpdateList;
      }
    } catch (Exception e) {
      System.debug(e.getMessage());
      System.debug(e.getStackTraceString());
      // TODO: change this for an aura exception
      return 'Error al enviar registro: ' + e.getMessage();
    }

    
    return 'Enviado correctamente.';
  }

  public class OrderUpdates {
    public String desviacion;
    public String descripcion;
    public String rejectionImage;
    public List<OrderItemUpdate> orderItemsUpdates;
    public Date selectedDate;
    public Time selectedTime;
  }

  public class OrderItemUpdate {
    public String name;
    public String id;
    public List<Lote> lotes;
    public Integer cantidadDePiezasFaltantes;
  }

  public class Lote{
    public String id;
    public Integer cantidadDePiezasFaltantes;
  }
}